terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.10.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
  features {} 
}

variable "prefix" {
  default = "anusha-prefix"
}
variable "location" {
  default = "Japan East"
}

resource "azurerm_resource_group" "anusha_rg" {
  name = "${var.prefix}-resources"
  location = "${var.location}"
}

resource "azurerm_virtual_network" "anusha_network"{
  name = "${var.prefix}-network"
  address_space = ["10.0.0.0/16"]
  location = azurerm_resource_group.anusha_rg.location
  resource_group_name = azurerm_resource_group.anusha_rg.name
}

resource "azurerm_subnet" "anusha_internal" {
  name = "internal"
  resource_group_name = azurerm_resource_group.anusha_rg.name
  virtual_network_name = azurerm_virtual_network.anusha_network.name
  address_prefixes = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "anusha_network_interface" {
  name = "${var.prefix}-nic"
  location = azurerm_resource_group.anusha_rg.location
  resource_group_name = azurerm_resource_group.anusha_rg.name

  ip_configuration {
    name = "testconfiguration1"
    subnet_id = azurerm_subnet.anusha_internal.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "anusha_vm" {
  name = "${var.prefix}-vm"
  location = azurerm_resource_group.anusha_rg.location
  resource_group_name = azurerm_resource_group.anusha_rg.name
  network_interface_ids = [azurerm_network_interface.anusha_network_interface.id]
  vm_size = "Standard_DS1_v2"

  delete_os_disk_on_termination = true

  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer = "UbuntuServer"
    sku = "16.04-LTS"
    version = "latest"
  }

  storage_os_disk {
    name = "myosdisk1"
    caching = "ReadWrite"
    create_option = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    environment = "staging"
  }
}