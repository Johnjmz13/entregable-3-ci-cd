# infra/outputs.tf
output "app_url" {
  description = "URL pública de la aplicación (ingress de Container Apps)"
  value       = "https://${azurerm_container_app.app.ingress[0].fqdn}"
}

output "container_app_environment_name" {
  description = "Nombre del ambiente de Container Apps"
  value       = azurerm_container_app_environment.main.name
}

output "container_app_name" {
  description = "Nombre de la Container App"
  value       = azurerm_container_app.app.name
}
