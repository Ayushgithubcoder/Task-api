# Outputs for Terraform configuration

# Generated deterministically using Module Registry

output "main_rg_id" {
  description = "The ID of the Resource Group"
  value       = module.main_rg.id
}

output "main_rg_name" {
  description = "The name of the Resource Group"
  value       = module.main_rg.name
}

output "main_rg_location" {
  description = "The location of the Resource Group"
  value       = module.main_rg.location
}

output "frontend_app_id" {
  description = "The ID of the Static Web App"
  value       = module.frontend_app.id
}

output "frontend_app_name" {
  description = "The name of the Static Web App"
  value       = module.frontend_app.name
}

output "frontend_app_default_host_name" {
  description = "The default hostname of the Static Web App"
  value       = module.frontend_app.default_host_name
}

output "frontend_app_api_key" {
  description = "The API key for the Static Web App (sensitive)"
  sensitive   = true
  value       = module.frontend_app.api_key
}

output "task_manager_api_app_id" {
  description = "The ID of the Container App"
  value       = module.task_manager_api_app.id
}

output "task_manager_api_app_name" {
  description = "The name of the Container App"
  value       = module.task_manager_api_app.name
}

output "task_manager_api_app_latest_revision_fqdn" {
  description = "The FQDN of the latest revision"
  value       = module.task_manager_api_app.latest_revision_fqdn
}
