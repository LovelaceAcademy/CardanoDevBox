# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Create Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "${var.resource-prefix}-rg"
  location = var.location
  tags = {
    stage = var.tag-stage
  }
}

# Create Virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.resource-prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags = {
    stage = var.tag-stage
  }
}

# Create Subnets
resource "azurerm_subnet" "devsnet" {
  name                 = "${var.resource-prefix}-vnet-dev-snet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create Public IP
resource "azurerm_public_ip" "cdbpip" {
  name                = "${var.resource-prefix}-cdbpip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  allocation_method   = "Static"
  tags = {
    stage = var.tag-stage
  }
}

# Network Security Group
resource "azurerm_network_security_group" "devnsg" {
  name                = "${var.resource-prefix}-dev-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.ssh-allowlist
    destination_address_prefix = "*"
  }
  tags = {
    stage               = var.tag-stage
  }
}

# Create Network interface with Subnet and Public IP
resource "azurerm_network_interface" "cdbnic" {
  name                          = "${var.resource-prefix}-cdbnic"
  location                      = var.location
  resource_group_name           = azurerm_resource_group.rg.name
  enable_accelerated_networking = var.cdbvm-nic-accelerated-networking
  ip_configuration {
    name                          = "cdbnic-ipconfig"
    subnet_id                     = azurerm_subnet.devsnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.cdbpip.id
  }
  tags = {
    stage = var.tag-stage
  }
}

resource "azurerm_network_interface_security_group_association" "cdbnicnsg" {
  network_interface_id      = azurerm_network_interface.cdbnic.id
  network_security_group_id = azurerm_network_security_group.devnsg.id
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "cdbstorage" {
  name                     = "${var.storage-prefix}cdbstor"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    stage = var.tag-stage
  }
}

# Create a SSH key 
resource "tls_private_key" "sshkey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "cdbvm" {
  name                  = "${var.resource-prefix}-cdbvm"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.cdbnic.id]
  size                  = var.cdbvm-size
  computer_name         = "${var.cdbvm-comp-name}"
  admin_username        = var.cdbvm-username
  disable_password_authentication = true
  os_disk {
    name                 = "${var.resource-prefix}-cdbvm-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = "128"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
  admin_ssh_key {
    username   = var.cdbvm-username
    public_key = tls_private_key.sshkey.public_key_openssh
  }
  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.cdbstorage.primary_blob_endpoint
  }
  tags = {
    stage = var.tag-stage
  }
}

output "sshpvk" {
  value       = tls_private_key.sshkey.private_key_pem
  description = "SSH private key"
  sensitive   = true
}

output "cdbpip" {
  value       = azurerm_public_ip.cdbpip.ip_address
  description = "Public IP Address"
  sensitive   = false
}
