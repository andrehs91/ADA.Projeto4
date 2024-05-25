resource "random_id" "value" {
  byte_length = 2
}

resource "azurerm_storage_account" "ada" {
  resource_group_name      = azurerm_resource_group.ada.name
  location                 = azurerm_resource_group.ada.location
  name                     = "sa${var.project_name}${terraform.workspace}${random_id.value.dec}"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  depends_on = [
    azurerm_resource_group.ada
  ]
}

resource "azurerm_storage_container" "ada" {
  name                  = "ada"
  storage_account_name  = azurerm_storage_account.ada.name
  container_access_type = "private"

  depends_on = [
    azurerm_storage_account.ada
  ]
}

resource "azurerm_storage_share" "rabbitmqstorage" {
  name                 = "rabbitmqstorage"
  storage_account_name = azurerm_storage_account.ada.name
  quota                = 5

  depends_on = [
    azurerm_storage_account.ada
  ]
}

resource "azurerm_storage_share" "redisstorage" {
  name                 = "redisstorage"
  storage_account_name = azurerm_storage_account.ada.name
  quota                = 5

  depends_on = [
    azurerm_storage_account.ada
  ]
}
