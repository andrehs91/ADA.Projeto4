# URL utilizada para acessar a interface do producer
# Incluir "/swagger/index.html" ao final do endereço
output "producer_url" {
  value = azurerm_container_app.container_app_producer.latest_revision_fqdn
}
