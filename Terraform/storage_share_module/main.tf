resource "azurerm_storage_share" "ada" {
  name                 = var.storage_share_name
  storage_account_name = var.storage_account_name
  quota                = 5
}
