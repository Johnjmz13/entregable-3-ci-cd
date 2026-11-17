# infra/main.tf
terraform {
  required_version = ">= 1.10.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.81"
    }
  }

  # La configuración de la cuenta de almacenamiento se pasa en "terraform init -backend-config=backend.hcl"
  backend "azurerm" {}
}

provider "azurerm" {
  features {}

  # La suscripción se toma de la variable de entorno ARM_SUBSCRIPTION_ID.
  # Los proveedores de recursos (Microsoft.App, Microsoft.OperationalInsights) se registran
  # una sola vez en la preparación: la identidad del pipeline solo tiene permisos sobre el grupo de recursos.
  resource_provider_registrations = "none"
}

locals {
  name_prefix    = "calculadora-${var.environment_name}"
  container_name = "calculadora"
  container_port = 8000

  tags = {
    Project     = "calculadora-cicd"
    Environment = var.environment_name
    ManagedBy   = "Terraform"
  }
}

# --- Recurso existente que Terraform solo consulta (no lo crea) ---

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# --- Logs ---

# Pago por uso: los primeros 5 GB al mes (por cuenta de facturación) y 31 días de retención no se cobran.
# Esta app genera pocos KB al día; el tope diario solo protege contra un pico inesperado de logs.
resource "azurerm_log_analytics_workspace" "logs" {
  name                = "log-${local.name_prefix}"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  daily_quota_gb      = 0.05
  tags                = local.tags
}

# --- Ambiente de Container Apps (equivale al cluster ECS) ---

resource "azurerm_container_app_environment" "main" {
  name                       = "cae-${local.name_prefix}"
  location                   = data.azurerm_resource_group.main.location
  resource_group_name        = data.azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id
  tags                       = local.tags
}

# --- Container App (equivale a Task Definition + Servicio ECS + ALB) ---

resource "azurerm_container_app" "app" {
  name                         = "ca-${local.name_prefix}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = data.azurerm_resource_group.main.name
  revision_mode                = "Single"
  tags                         = local.tags

  template {
    # Con 0 réplicas mínimas la app se apaga tras unos minutos sin tráfico y no cobra cómputo;
    # la primera petición la vuelve a encender (tarda unos segundos en responder).
    min_replicas = var.min_replicas
    max_replicas = 1

    http_scale_rule {
      name                = "http"
      concurrent_requests = "10"
    }

    container {
      name   = local.container_name
      image  = var.docker_image_uri
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "APP_VERSION"
        value = var.app_version
      }

      # Da hasta 60 segundos para arrancar antes de evaluar las demás sondas
      startup_probe {
        transport               = "HTTP"
        port                    = local.container_port
        path                    = "/health"
        interval_seconds        = 5
        timeout                 = 5
        failure_count_threshold = 12
      }

      # Solo recibe tráfico la réplica que responde en /health
      readiness_probe {
        transport               = "HTTP"
        port                    = local.container_port
        path                    = "/health"
        interval_seconds        = 10
        timeout                 = 5
        failure_count_threshold = 3
        success_count_threshold = 1
      }

      # Si deja de responder 3 veces seguidas, se reinicia el contenedor
      liveness_probe {
        transport               = "HTTP"
        port                    = local.container_port
        path                    = "/health"
        interval_seconds        = 30
        timeout                 = 5
        failure_count_threshold = 3
      }
    }
  }

  ingress {
    external_enabled           = true
    target_port                = local.container_port
    transport                  = "http"
    allow_insecure_connections = false

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}
