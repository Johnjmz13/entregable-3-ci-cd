# infra/backend.hcl
resource_group_name  = "rg-calculadora-cicd"
storage_account_name = "tfstatecalculadorajohn"
container_name       = "tfstate"
key                  = "calculadora/terraform.tfstate"
