terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100.0"
    }
  }

  backend "azurerm" {
      resource_group_name  = "tfstate"
      storage_account_name = "<SUBSTITUIR>" # Execute o arquivo backend.sh e insira aqui o nome do container criado
      container_name       = "tfstate"
      key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {
  }
}

# Grupo de recursos
resource "azurerm_resource_group" "ada" {
  location = var.location
  name     = "rg-${var.project_name}-${terraform.workspace}"
}

# Espaço de trabalho para logs
resource "azurerm_log_analytics_workspace" "ada" {
  resource_group_name = azurerm_resource_group.ada.name
  location            = azurerm_resource_group.ada.location
  name                = "law-${var.project_name}-${terraform.workspace}"

  depends_on = [
    azurerm_resource_group.ada
  ]
}
