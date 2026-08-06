# Terraform configuration generated from Resource Plan
# Environment: dev
# Generated from deterministic resource plan (Phase 2)

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.116.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "Test-005-dev-rg"
    storage_account_name = "test005devtfstate"
    container_name       = "tfstate-system"
    key                  = "apps/Test-01-dev/dev.tfstate"
    subscription_id      = "d6c69b8a-1b49-482e-80c0-95ccb98fd3c6"
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Merge var.environment into tags so every resource carries the environment label.
# This ensures var.environment is consumed and not dead code.
locals {
  common_tags = merge(var.tags, { environment = var.environment })
}

# ========================================
# Phase: 1 Foundation
# ========================================

# Module: main_rg (azurerm_resource_group)
module "main_rg" {
  source = "./modules/azure-resource-group"

  location = var.location
  name     = "Test-01-dev-rg"
  tags     = local.common_tags
}

# Shared Data Lookup: log_analytics (azurerm_log_analytics_workspace)
data "azurerm_log_analytics_workspace" "shared" {
  name                = "test-01-dev-infrastructure"
  resource_group_name = "platform-shared-rg"
}

# ========================================
# Phase: 2 Shared Infrastructure
# ========================================

# Resource: app_task_manager_api (azurerm_container_app_environment)
resource "azurerm_container_app_environment" "app_frontend_web_app" {
  name                       = "myorg-test-01-dev-shared-dev-centralus-env"
  location                   = var.location
  resource_group_name        = module.main_rg.name
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.shared.id
  tags                       = local.common_tags
}

# Shared Data Lookup: tfstate_storage (azurerm_storage_account)
data "azurerm_storage_account" "shared" {
  name                = "test005devtfstate"
  resource_group_name = "Test-005-dev-rg"
}

# ========================================
# Phase: 3 Data
# ========================================

# Resource: pg_password (random_password)
resource "random_password" "pg_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}|:?"
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 2
}

# Resource: pg_server (azurerm_postgresql_flexible_server)
resource "azurerm_postgresql_flexible_server" "pg_postgresql_database" {
  name                   = "test-01-dev-pg"
  resource_group_name    = module.main_rg.name
  location               = var.location
  version                = "16"
  administrator_login    = "pgadmin"
  administrator_password = random_password.pg_password.result
  sku_name               = "B_Standard_B1ms"
  storage_mb             = 32768
  zone                   = "1"
  tags                   = local.common_tags
  lifecycle {
    ignore_changes = [administrator_password]

  }
}

# Resource: pg_database (azurerm_postgresql_flexible_server_database)
resource "azurerm_postgresql_flexible_server_database" "pg_database" {
  name      = "Test-01-dev-db"
  server_id = azurerm_postgresql_flexible_server.pg_postgresql_database.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# Resource: postgresql_database_fw (azurerm_postgresql_flexible_server_firewall_rule)
resource "azurerm_postgresql_flexible_server_firewall_rule" "postgresql_database_fw" {
  name             = "allow-azure-internal"
  server_id        = azurerm_postgresql_flexible_server.pg_postgresql_database.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# ========================================
# Phase: 4 Compute
# ========================================

# Module: frontend_app (azurerm_static_site)
module "frontend_app" {
  source = "./modules/azure-static-site"

  app_settings = {
    BACKEND_API_URL = "https://${module.task_manager_api_app.latest_revision_fqdn}"
  }
  location            = var.location
  name                = "test-01-dev-frontend-web-app"
  resource_group_name = module.main_rg.name
  sku_size            = "Free"
  sku_tier            = "Free"
  tags                = local.common_tags
}

# Module: task_manager_api_app (azurerm_container_app)
module "task_manager_api_app" {
  source = "./modules/azure-container-app"

  container_app_environment_id = azurerm_container_app_environment.app_frontend_web_app.id
  containers                   = [{ "name" : "task-manager-api", "image" : "${var.task_manager_api_image}", "cpu" : 0.25, "memory" : "0.5Gi", "env" : [] }]
  environment_variables = {
    DATABASE_URL = "postgresql://pgadmin:${urlencode(random_password.pg_password.result)}@${azurerm_postgresql_flexible_server.pg_postgresql_database.fqdn}:5432/${azurerm_postgresql_flexible_server_database.pg_database.name}?sslmode=require"
  }
  ingress = {
    external_enabled = true
    target_port      = 8080
    transport        = "http"
  }
  location            = var.location
  name                = "test-01-dev-task-manager-api"
  resource_group_name = module.main_rg.name
  revision_mode       = "Single"
  tags                = local.common_tags
}
