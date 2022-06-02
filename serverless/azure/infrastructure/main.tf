resource "azurerm_resource_group" "rg1" {
  name     = "cordsResourceGroupAG"
  location = "centralus"
}

resource "azurerm_virtual_network" "vnet1" {
  name                = "cordsVNet"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  address_space       = ["10.4.0.0/16"]
}

resource "azurerm_subnet" "frontend" {
  name                 = "cordsAGSubnet"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.4.0.0/24"]
}

resource "azurerm_subnet" "backend" {
  name                 = "cordsBackendSubnet"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.4.1.0/24"]
}

resource "azurerm_public_ip" "pip1" {
  name                = "cordsAGPublicIPAddress"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}

resource "azurerm_dns_zone" "dns_zone" {
  name                = "test.dummycordsfun.com"
  resource_group_name = azurerm_resource_group.rg1.name
}

resource "azurerm_dns_a_record" "dns_a_record" {
  name                = "cordsDNSARecord"
  zone_name           = azurerm_dns_zone.dns_zone.name
  resource_group_name = azurerm_resource_group.rg1.name
  ttl                 = 300
  target_resource_id  = azurerm_public_ip.pip1.id
}

resource "azurerm_application_security_group" "example" {
  name                = "cordsAsg"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
}


#####################################################
############# APPLICATION GATEWAY ###################
#####################################################


locals {
  backend_address_pool_name      = "${azurerm_virtual_network.vnet1.name}-beap"
  frontend_port_name             = "${azurerm_virtual_network.vnet1.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.vnet1.name}-feip"
  http_setting_name              = "${azurerm_virtual_network.vnet1.name}-be-htst"
  listener_name                  = "${azurerm_virtual_network.vnet1.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.vnet1.name}-rqrt"
  redirect_configuration_name    = "${azurerm_virtual_network.vnet1.name}-rdrcfg"
}

resource "azurerm_application_gateway" "network" {
  name                = "cordsAppGateway"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  sku {
    name     = "Standard_Small"
    tier     = "Standard"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "cords-gateway-ip-configuration"
    subnet_id = azurerm_subnet.frontend.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.pip1.id
  }

  #authentication_certificate {
   # name = "auth_cert"
   # data = "${base64encode(file("files/keys/certificate.cer"))}"
  #}

  #ssl_certificate {
   # name     = "ssl_cert"
    #data     = "${base64encode(file("files/keys/certificate.pfx"))}"
    #password = ""
  #}

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    port                  = 8000
    protocol              = "Https"
    request_timeout       = 2
    #authentication_certificate {
    #  name = "auth_cert"
    #}
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
    #ssl_certificate_name           = "ssl_cert"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "nsg" {
  name                = "cordsNetworkSecurityGroup"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name

  security_rule {
    name                       = "SSH_IB"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "SSH_OB"
    priority                   = 1001
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  # New security rule for 8000 port
  security_rule {
    name                       = "Allow_Any_8000_IB_Any"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "8000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Allow_Any_8000_OB_Any"
    priority                   = 1010
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "8000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "nic" {
  name                = "cordsNIC"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name

  ip_configuration {
    name                          = "nic-ipconfig"
    subnet_id                     = azurerm_subnet.backend.id
    private_ip_address_allocation = "Dynamic"
  }
}


resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "nic-assoc01" {
  network_interface_id    = azurerm_network_interface.nic.id
  ip_configuration_name   = "nic-ipconfig"
  backend_address_pool_id = azurerm_application_gateway.network.backend_address_pool.*.id[0]
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "nic-nsg-assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_network_interface_application_security_group_association" "nic-asg-assoc" {
  network_interface_id          = azurerm_network_interface.nic.id
  application_security_group_id = azurerm_application_security_group.example.id
}


# Create (and display) an SSH key
resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}


#####################################################
#################### BASTION ########################
#####################################################

# resource "azurerm_subnet" "bastion_subnet" {
#   name                 = "AzureBastionSubnet"
#   resource_group_name  = azurerm_resource_group.rg1.name
#   virtual_network_name = azurerm_virtual_network.vnet1.name
#   address_prefixes     = ["10.4.2.0/24"]
# }

# resource "azurerm_public_ip" "pip2" {
#   name                = "cordsBastionPublicIPAddress"
#   resource_group_name = azurerm_resource_group.rg1.name
#   location            = azurerm_resource_group.rg1.location
#   allocation_method   = "Static"
#   sku                 = "Standard"
# }

# resource "azurerm_bastion_host" "bastion" {
#   name                = "cordsBastion"
#   location            = azurerm_resource_group.rg1.location
#   resource_group_name = azurerm_resource_group.rg1.name
#   sku                = "Basic"
#   ip_configuration {
#     name                 = "configuration"
#     subnet_id            = azurerm_subnet.bastion_subnet.id
#     public_ip_address_id = azurerm_public_ip.pip2.id
#   }
# }

# # We need to include existing security rules for AzureBastionSubnet to the NSG for it to associate with the subnet.
# resource "azurerm_network_security_group" "bastion_nsg" {
#   name = "cordsBastionNetworkSecurityGroup"
#   resource_group_name = azurerm_resource_group.rg1.name
#   location = azurerm_resource_group.rg1.location
  
#   # Existing security rules start here
  
#   security_rule {
#     name                       = "Allow_TCP_443_Internet"
#     priority                   = 100
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = 443
#     source_address_prefix      = "Internet"
#     destination_address_prefix = "*"
#   }
#   security_rule {
#     name                       = "Allow_TCP_443_GatewayManager"
#     priority                   = 110
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = 443
#     source_address_prefix      = "GatewayManager"
#     destination_address_prefix = "*"
#   }
#   security_rule {
#     name                       = "Allow_TCP_4443_GatewayManager"
#     priority                   = 120
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = 4443
#     source_address_prefix      = "GatewayManager"
#     destination_address_prefix = "*"
#   }
#   security_rule {
#     name                       = "Allow_TCP_443_AzureLoadBalancer"
#     priority                   = 130
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = 443
#     source_address_prefix      = "AzureLoadBalancer"
#     destination_address_prefix = "*"
#   }
#   security_rule {
#     name                       = "Allow_Any_8080_IB_VirtualNetwork"
#     priority                   = 140
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "*"
#     source_port_range          = "*"
#     destination_port_range     = 8080
#     source_address_prefix      = "VirtualNetwork"
#     destination_address_prefix = "*"
#   }
#   security_rule {
#     name                       = "Allow_Any_5701_IB_VirtualNetwork"
#     priority                   = 150
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "*"
#     source_port_range          = "*"
#     destination_port_range     = 5701
#     source_address_prefix      = "VirtualNetwork"
#     destination_address_prefix = "*"
#   }
#   security_rule {
#     name                       = "Allow_Any_22_IB_VirtualNetwork"
#     priority                   = 160
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "*"
#     source_port_range          = "*"
#     destination_port_range     = "22"
#     source_address_prefix      = "*"
#     destination_address_prefix = "VirtualNetwork"
#   }
#   security_rule {
#     name                       = "Deny_any_other_traffic"
#     priority                   = 900
#     direction                  = "Inbound"
#     access                     = "Deny"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "*"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }
#   security_rule {
#     name                       = "Allow_Any_3389_VirtualNetwork"
#     priority                   = 100
#     direction                  = "Outbound"
#     access                     = "Allow"
#     protocol                   = "*"
#     source_port_range          = "*"
#     destination_port_range     = "3389"
#     source_address_prefix      = "*"
#     destination_address_prefix = "VirtualNetwork"
#   }
#   security_rule {
#     name                       = "Allow_Any_22_OB_VirtualNetwork"
#     priority                   = 110
#     direction                  = "Outbound"
#     access                     = "Allow"
#     protocol                   = "*"
#     source_port_range          = "*"
#     destination_port_range     = "22"
#     source_address_prefix      = "*"
#     destination_address_prefix = "VirtualNetwork"
#   }
#   security_rule {
#     name                       = "Allow_TCP_443_AzureCloud"
#     priority                   = 120
#     direction                  = "Outbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "443"
#     source_address_prefix      = "*"
#     destination_address_prefix = "AzureCloud"
#   }
#   security_rule {
#     name                       = "Allow_Any_8080_OB_VirtualNetwork"
#     priority                   = 130
#     direction                  = "Outbound"
#     access                     = "Allow"
#     protocol                   = "*"
#     source_port_range          = "*"
#     destination_port_range     = "8080"
#     source_address_prefix      = "VirtualNetwork"
#     destination_address_prefix = "VirtualNetwork"
#   }
#   security_rule {
#     name                       = "Allow_Any_5701_OB_VirtualNetwork"
#     priority                   = 140
#     direction                  = "Outbound"
#     access                     = "Allow"
#     protocol                   = "*"
#     source_port_range          = "*"
#     destination_port_range     = "5701"
#     source_address_prefix      = "VirtualNetwork"
#     destination_address_prefix = "VirtualNetwork"
#   }
#   security_rule {
#     name                       = "Allow_Any_80_Internet"
#     priority                   = 150
#     direction                  = "Outbound"
#     access                     = "Allow"
#     protocol                   = "*"
#     source_port_range          = "*"
#     destination_port_range     = "80"
#     source_address_prefix      = "*"
#     destination_address_prefix = "Internet"
#   }

#   # Existing security rules end here

#   # New security rule for 8000 port
#   security_rule {
#     name                       = "Allow_Any_8000_IB_Any"
#     priority                   = 170
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "*"
#     source_port_range          = "*"
#     destination_port_range     = "8000"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }
#   security_rule {
#     name                       = "Allow_Any_8000_OB_Any"
#     priority                   = 160
#     direction                  = "Outbound"
#     access                     = "Allow"
#     protocol                   = "*"
#     source_port_range          = "*"
#     destination_port_range     = "8000"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }
# }

# resource "azurerm_subnet_network_security_group_association" "bastion-subnet-security-grp-assoc" {
#   subnet_id                 = azurerm_subnet.bastion_subnet.id
#   network_security_group_id = azurerm_network_security_group.bastion_nsg.id
# }

############### LOAD BALANCER ####################

resource "azurerm_public_ip" "pip3" {
  name                = "publicIPForLB"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  allocation_method   = "Static"
  sku                 = "Standard" 
}

resource "azurerm_lb" "lb" {
  name                = "cordsLoadBalancer"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  sku                 = "Standard"
  frontend_ip_configuration {
    name                 = "publicIPAddress"
    public_ip_address_id = azurerm_public_ip.pip3.id
  }
}

resource "azurerm_lb_backend_address_pool" "backend_address_pool" {
  name            = "cordsLbBackendAddressPool"
  loadbalancer_id = azurerm_lb.lb.id
}

resource "azurerm_lb_backend_address_pool_address" "backend_address_pool_address" {
  name                    = "cordsLbBackendAddressPoolAddress"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_address_pool.id
  virtual_network_id      = azurerm_virtual_network.vnet1.id
  ip_address = "10.4.1.4"
}

resource "azurerm_lb_rule" "example" {
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "cordsLbRule"
  protocol                       = "Tcp"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backend_address_pool.id]
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "publicIPAddress"
  enable_tcp_reset               = true
  disable_outbound_snat          = true 
}

resource "azurerm_lb_nat_rule" "example" {
  resource_group_name            = azurerm_resource_group.rg1.name
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "cordsNatRule"
  protocol                       = "Tcp"
  frontend_port                  = 221
  backend_port                   = 22
  frontend_ip_configuration_name = "publicIPAddress"
}

############### PRIVATE KEY #####################
resource "local_file" "private_key" {
  content         = tls_private_key.example_ssh.private_key_pem
  filename        = "azure.pem"
  file_permission = "0600"
}



#####################################################
################## VIRTUAL MACHINE ##################
#####################################################


# Create virtual machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                  = "cordsVM"
  location              = azurerm_resource_group.rg1.location
  resource_group_name   = azurerm_resource_group.rg1.name
  network_interface_ids = [azurerm_network_interface.nic.id,]
  size                  = "Standard_DS1"
  
  os_disk {
    name                 = "cordsOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-LTS"
    version   = "latest"
  }

  computer_name                   = "cordsvm"
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.example_ssh.public_key_openssh
  }

  #boot_diagnostics {
   # storage_account_uri = azurerm_storage_account.cordsstorageaccount.primary_blob_endpoint
  #}
}



########### DIAGNOSTIC LOGS ON AGW #################

resource "azurerm_storage_account" "example" {
  name                     = "cordsstorageaccount"
  resource_group_name      = azurerm_resource_group.rg1.name
  location                 = azurerm_resource_group.rg1.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "staging"
  }
}

resource "azurerm_monitor_diagnostic_setting" "example" {
  name               = "cordsAGWDiagnosticSetting"
  target_resource_id = azurerm_application_gateway.network.id
  storage_account_id = azurerm_storage_account.example.id

  log {
    category = "ApplicationGatewayAccessLog"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }

  log {
    category = "ApplicationGatewayPerformanceLog"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
  
  log {
    category = "ApplicationGatewayFirewallLog"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}

