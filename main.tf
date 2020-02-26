#create resource group
resource "azurerm_resource_group" "rg" {
  name= "${var.name}"
  location= "${var.location}"

  tags {
    owner = "${var.owner}"
  }
}

#créer un virtual network
resource  "azurerm_virtual_network" "myFirstVnet"{
  name = "${var.name_vnet}"
  address_space = "${var.address_space}"
  location = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"    
}

#créer un subnet
resource "azurerm_subnet" "myFirstSubnet"{
  name= "${var.name_subnet}" 
  resource_group_name="${azurerm_resource_group.rg.name}"
  virtual_network_name="${azurerm_virtual_network.myFirstVnet.name}"
  address_prefix="${var.address_prefix}"
}

resource "azurerm_network_security_group" "myFirstNsg" {
  name= "${var.nameNsg}"
  location= "${var.location}"
  resource_group_name= "${azurerm_resource_group.rg.name}"

  security_rule{
    name= "SSH"
    priority= "1001"
    direction= "Inbound"
    access= "Allow"
    protocol= "Tcp"
    source_port_range= "*"
    destination_port_range= "22"
    source_address_prefix= "*"
    destination_address_prefix= "*"
  }
  
  security_rule{
   name = "HTTP"
   priority = "1002"
   direction = "Inbound"
   access = "Allow"
   protocol = "Tcp"
   source_port_range = "*"
   destination_port_range = "80"
   source_address_prefix = "*"
   destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "myFirstPubIp" {
  name = "${var.nameIpPub}"
  location = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  allocation_method = "${var.allocation_method}"
}

resource "azurerm_network_interface" "myFirstNIC" {
  name = "${var.nameNIC}"
  location = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  network_security_group_id = "${azurerm_network_security_group.myFirstNsg.id}"
  ip_configuration{
    name = "${var.nameNICConfig}"
    subnet_id = "${azurerm_subnet.myFirstSubnet.id}"
    private_ip_address_allocation = "${var.allocation_method}"
    public_ip_address_id = "${azurerm_public_ip.myFirstPubIp.id}"
  }
}

#create virtual machine
resource "azurerm_virtual_machine" "myFirstVM"{
  name = "${var.nameVM}"
  location = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  network_interface_ids = ["${azurerm_network_interface.myFirstNIC.id}"]
  vm_size = "${var.vmSize}"

  storage_os_disk{
    name ="myDisk"
    caching = "ReadWrite"
    create_option = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  storage_image_reference{
    publisher = "OpenLogic"
    offer = "CentOS"
    sku = "7.6"
    version = "latest"
  }
  os_profile{
    computer_name = "vmTest"
    admin_username = "vagrant"
  }
  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys{
       path =  "/home/vagrant/.ssh/authorized_keys"
       key_data = "${var.key_data}"
    }
  }
}
