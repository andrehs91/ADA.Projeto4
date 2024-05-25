resource "azurerm_container_app" "container_app_rabbitmq" {
  resource_group_name          = azurerm_resource_group.ada.name
  container_app_environment_id = azurerm_container_app_environment.ada.id
  name                         = var.env_rabbitmq_hostname
  revision_mode                = "Single"
  ingress {
    exposed_port = 5672
    target_port  = 5672
    transport    = "tcp"
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
  template {
    container {
      cpu    = 0.5
      image  = "docker.io/rabbitmq:latest"
      memory = "1Gi"
      name   = var.env_rabbitmq_hostname
      env {
        name  = "RABBITMQ_DEFAULT_USER"
        value = var.env_rabbitmq_username
      }
      env {
        name  = "RABBITMQ_DEFAULT_PASS"
        value = var.env_rabbitmq_password
      }
      volume_mounts {
        name = "rabbitmqvolume"
        path = "/var/lib/rabbitmq"
      }
    }
    volume {
      name = "rabbitmqvolume"
      storage_name = azurerm_container_app_environment_storage.rabbitmq-storage.name
      storage_type = "AzureFile"
    }
  }
  depends_on = [
    azurerm_container_app_environment.ada,
    azurerm_container_app_environment_storage.rabbitmq-storage
  ]
}

resource "azurerm_container_app" "container_app_redis" {
  resource_group_name          = azurerm_resource_group.ada.name
  container_app_environment_id = azurerm_container_app_environment.ada.id
  name                         = var.env_redis_hostname
  revision_mode                = "Single"
  ingress {
    exposed_port = 6379
    target_port  = 6379
    transport    = "tcp"
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
  template {
    container {
      cpu    = 0.5
      image  = "docker.io/redis:latest"
      memory = "1Gi"
      name   = var.env_redis_hostname
      env {
        name  = "REDIS_PASSWORD"
        value = var.env_redis_password
      }
      volume_mounts {
        name = "redisvolume"
        path = "/data"
      }
    }
    volume {
      name = "redisvolume"
      storage_name = azurerm_container_app_environment_storage.redis-storage.name
      storage_type = "AzureFile"
    }
  }
  depends_on = [
    azurerm_container_app_environment.ada,
    azurerm_container_app_environment_storage.redis-storage
  ]
}

resource "azurerm_container_app" "container_app_consumer" {
  resource_group_name          = azurerm_resource_group.ada.name
  container_app_environment_id = azurerm_container_app_environment.ada.id
  name                         = "consumer"
  revision_mode                = "Single"
  template {
    max_replicas = 1
    container {
      cpu    = 0.5
      image  = "docker.io/andrehs/ada.consumer"
      memory = "1Gi"
      name   = "consumer"
      env {
        name  = "RABBITMQ_HOSTNAME"
        value = var.env_rabbitmq_hostname
      }
      env {
        name  = "RABBITMQ_USERNAME"
        value = var.env_rabbitmq_username
      }
      env {
        name  = "RABBITMQ_PASSWORD"
        value = var.env_rabbitmq_password
      }
      env {
        name  = "REDIS_HOSTNAME"
        value = var.env_redis_hostname
      }
      env {
        name  = "REDIS_PASSWORD"
        value = var.env_redis_password
      }
    }
  }
  depends_on = [
    azurerm_container_app_environment.ada,
    azurerm_container_app.container_app_rabbitmq,
    azurerm_container_app.container_app_redis
  ]
}

resource "azurerm_container_app" "container_app_producer" {
  resource_group_name          = azurerm_resource_group.ada.name
  container_app_environment_id = azurerm_container_app_environment.ada.id
  name                         = "producer"
  revision_mode                = "Single"
  ingress {
    allow_insecure_connections = true
    external_enabled           = true
    target_port                = 8080
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
  template {
    container {
      cpu    = 0.25
      image  = "docker.io/andrehs/ada.producer"
      memory = "0.5Gi"
      name   = "producer"
      env {
        name  = "CONNECTIONSTRINGS_AZURESTORAGEACCOUNT"
        value = azurerm_storage_account.ada.primary_connection_string
      }
      env {
        name  = "RABBITMQ_HOSTNAME"
        value = var.env_rabbitmq_hostname
      }
      env {
        name  = "RABBITMQ_USERNAME"
        value = var.env_rabbitmq_username
      }
      env {
        name  = "RABBITMQ_PASSWORD"
        value = var.env_rabbitmq_password
      }
      env {
        name  = "REDIS_HOSTNAME"
        value = var.env_redis_hostname
      }
      env {
        name  = "REDIS_PASSWORD"
        value = var.env_redis_password
      }
    }
  }
  depends_on = [
    azurerm_container_app_environment.ada,
    azurerm_container_app.container_app_rabbitmq,
    azurerm_container_app.container_app_redis
  ]
}
