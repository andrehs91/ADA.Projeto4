terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100.0"
    }
  }

  backend "azurerm" {
      resource_group_name  = "tfstate"
      storage_account_name = "tfstate26509"
      container_name       = "tfstate"
      key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {
  }
}

resource "azurerm_resource_group" "ada" {
  location = var.location
  name     = "rg-${var.project_name}-${terraform.workspace}"
}

resource "azurerm_log_analytics_workspace" "ada" {
  resource_group_name = azurerm_resource_group.ada.name
  location            = azurerm_resource_group.ada.location
  name                = "law-${var.project_name}-${terraform.workspace}"

  depends_on = [
    azurerm_resource_group.ada
  ]
}
