terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  required_version = ">= 1.5.0"
}

provider "azurerm" {
  features {}
}


resource "azurerm_resource_group" "rg" {
  name     = "rg-nginx-aca-demo"
  location = "East US"
}


resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-nginx-aca-demo"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku               = "PerGB2018"
  retention_in_days = 30
}


resource "azurerm_container_app_environment" "env" {
  name                = "nginx-container-env"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
}


resource "azurerm_container_app" "nginx" {

  name                         = "nginx-container-app"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.rg.name

  revision_mode = "Single"



  ingress {
    external_enabled = true

    target_port = 80
    transport   = "http"

    allow_insecure_connections = false

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }


  template {

    container {
      name  = "nginx"
      image = "nginx:latest"

      cpu    = 0.5
      memory = "1Gi"
    }


    min_replicas = 1
    max_replicas = 5
  }
}




output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "container_environment_id" {
  value = azurerm_container_app_environment.env.id
}

output "container_app_name" {
  value = azurerm_container_app.nginx.name
}

output "https_url" {
  value = "https://${azurerm_container_app.nginx.latest_revision_fqdn}"
}