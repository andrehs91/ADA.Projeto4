variable "project_name" {
  type = string
}

variable "location" {
  type = string
  default = "brazilsouth"
}

variable "env_rabbitmq_hostname" {
  type = string
}

variable "env_rabbitmq_username" {
  type = string
}

variable "env_rabbitmq_password" {
  type = string
}

variable "env_redis_hostname" {
  type = string
}

variable "env_redis_password" {
  type = string
}
