############################################################
# OUTPUTS
############################################################

output "ai_account_name" {
  value =  azurerm_cognitive_account.ai_account.name
}

output "subnet_id_agent" {
  value = azurerm_subnet.agent_subnet.id
}

output "subnet_id_private_endpoint" {
  value = azurerm_subnet.private_endpoint_subnet.id
}