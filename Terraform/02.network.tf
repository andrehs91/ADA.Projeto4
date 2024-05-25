resource "azurerm_virtual_network" "ada" {
  resource_group_name = azurerm_resource_group.ada.name
  location            = azurerm_resource_group.ada.location
  address_space       = ["10.0.0.0/16"]
  name                = "vnet-${var.project_name}-${terraform.workspace}"
  depends_on = [
    azurerm_resource_group.ada
  ]
}

resource "azurerm_subnet" "ada" {
  resource_group_name  = azurerm_resource_group.ada.name
  virtual_network_name = azurerm_virtual_network.ada.name
  address_prefixes     = ["10.0.0.0/20"]
  name                 = "subnet-${var.project_name}-${terraform.workspace}"
  depends_on = [
    azurerm_virtual_network.ada
  ]
}
