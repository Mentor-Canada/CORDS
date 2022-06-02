output "resource_group_name" {
  value = azurerm_resource_group.rg1.name
}

output "agw_public_ip_address" {
  value = azurerm_public_ip.pip1.ip_address
}

# output "bastion_public_ip_address" {
#   value = azurerm_public_ip.pip2.ip_address
# }

output "tls_private_key" {
  value     = tls_private_key.example_ssh.private_key_pem
  sensitive = true
}