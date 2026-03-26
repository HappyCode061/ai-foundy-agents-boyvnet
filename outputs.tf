############################################################
# OUTPUTS
############################################################

output "ai_account_name" {
  value =  azurerm_cognitive_account.ai_account.name
}

output "vnet_id" {
  value = data.azurerm_virtual_network.vnet.id
}

output "agent_subnet_id" {
  value = data.azurerm_subnet.agent_subnet.id
}
