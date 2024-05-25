# Ambiente isolado para execução dos containers
resource "azurerm_container_app_environment" "ada" {
  resource_group_name        = azurerm_resource_group.ada.name
  location                   = azurerm_resource_group.ada.location
  name                       = "cae-${var.project_name}-${terraform.workspace}"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.ada.id

  depends_on = [
    azurerm_resource_group.ada,
    azurerm_subnet.ada,
    azurerm_log_analytics_workspace.ada
  ]
}

# Vinculação do compartilhamento de arquivos ao ambiente gerenciado
resource "azurerm_container_app_environment_storage" "rabbitmq-storage" {
  name                         = "rabbitmqstorage"
  container_app_environment_id = azurerm_container_app_environment.ada.id
  account_name                 = azurerm_storage_account.ada.name
  access_key                   = azurerm_storage_account.ada.primary_access_key
  share_name                   = azurerm_storage_share.rabbitmqstorage.name
  access_mode                  = "ReadWrite"

  depends_on = [
    azurerm_container_app_environment.ada,
    azurerm_storage_account.ada,
    azurerm_storage_share.rabbitmqstorage
  ]
}

# Vinculação do compartilhamento de arquivos ao ambiente gerenciado
resource "azurerm_container_app_environment_storage" "redis-storage" {
  name                         = "redisstorage"
  container_app_environment_id = azurerm_container_app_environment.ada.id
  account_name                 = azurerm_storage_account.ada.name
  access_key                   = azurerm_storage_account.ada.primary_access_key
  share_name                   = azurerm_storage_share.redisstorage.name
  access_mode                  = "ReadWrite"

  depends_on = [
    azurerm_container_app_environment.ada,
    azurerm_storage_account.ada,
    azurerm_storage_share.redisstorage
  ]
}
