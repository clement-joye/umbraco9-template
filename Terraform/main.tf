
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.65, < 2.94.0"
    }
  }
  backend "azurerm" {
  }
  required_version = ">= 0.14.9"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.azure_resource_group}-${var.environment}"
  location = "northeurope"
}

resource "azurerm_storage_account" "sa" {
  name                     = "st${var.azure_acronym}${var.environment}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "container" {
  name                  = "umbraco"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

resource "azurerm_sql_server" "db_server" {
  name                         = "sql-${var.azure_acronym}-${var.environment}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = "North Europe"
  version                      = "12.0"
  administrator_login          = var.sql_username
  administrator_login_password = var.sql_password
}

resource "azurerm_mssql_firewall_rule" "firewall_rule" {
  name                = "Azure services"
  server_id           = azurerm_sql_server.db_server.id
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

resource "azurerm_sql_database" "db" {
  name                = "db-${var.azure_acronym}-${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = "North Europe"
  server_name         = azurerm_sql_server.db_server.name
}

resource "azurerm_app_service_plan" "plan" {
  name                = "asp-${var.azure_acronym}-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "Linux"
  reserved            = "false"

  sku {
    tier = "Basic"
    size = "B1"
  }
}

resource "azurerm_app_service" "app" {
  name                = "app-${var.azure_acronym}-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.plan.id

  site_config {
    dotnet_framework_version = "v6.0"
    scm_type                 = "LocalGit"
  }

  app_settings = {
    "Umbraco:Storage:AzureBlob:Media:ConnectionString" = "DefaultEndpointsProtocol=https;AccountName=${azurerm_storage_account.sa.name};AccountKey=${azurerm_storage_account.sa.secondary_access_key};EndpointSuffix=core.windows.net" 
    "Umbraco:Storage:AzureBlob:Media:ContainerName" = "umbraco"
  }

  connection_string {
    name  = "umbracoDbDSN"
    type  = "SQLServer"
    value = "server=${azurerm_sql_server.db_server.fully_qualified_domain_name};database=db-${var.azure_acronym}-${var.environment};user id=${var.sql_username};password='${var.sql_password}'"
  }
}

resource "azurerm_application_insights" "ai" {
  name                = "ai-${var.azure_acronym}-${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  application_type    = "web"
}

output "instrumentation_key" {
  value     = azurerm_application_insights.ai.instrumentation_key
  sensitive = true
}

output "app_id" {
  value = azurerm_application_insights.ai.app_id
}
