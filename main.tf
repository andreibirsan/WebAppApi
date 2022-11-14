terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}
provider "azurerm" {
  features {}
}

# Save the tfstate file in an Azure storage account. When running the terraform plan for the first time leave the backend part commented, then uncomment it to move the tfstate file to the cloud. 
#terraform {
#  backend "azurerm" {
#    resource_group_name  = "tf_rg_blobstore"
#    storage_account_name = "tfstorage131120222"
#    container_name       = "tfstate"
#    key                  = "terraform.tfstate"
#  }
#} 

# Generate a random integer to create a globally unique name
resource "random_integer" "ri" {
  min = 10000
  max = 99999
}

# Create the resourcegroup, storage account and container for the terraform backen used above
resource "azurerm_resource_group" "tfrg" {
  name     = "tf_rg_blobstore"
  location = "West Europe"
}

resource "azurerm_storage_account" "tfstor" {
  name                     = "tfstorage131120222"
  resource_group_name      = azurerm_resource_group.tfrg.name
  location                 = azurerm_resource_group.tfrg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstor.name
  container_access_type = "private"
}

# Create the resource group for the webapp
resource "azurerm_resource_group" "tfrg-webapp" {
  name     = "tfrg_webapp-api"
  location = "West Europe"
}

# Create the App Service Plan
resource "azurerm_service_plan" "tf-appserviceplan" {
  name                = "tf_app-service-plan_webapp-api"
  location            = azurerm_resource_group.tfrg-webapp.location
  resource_group_name = azurerm_resource_group.tfrg-webapp.name
  os_type             = "Linux"
  sku_name            = "B1"
}

# Create the web app
resource "azurerm_linux_web_app" "tf-webapp" {
  name                = "tf-webapp-api"
  location            = azurerm_resource_group.tfrg-webapp.location
  resource_group_name = azurerm_resource_group.tfrg-webapp.name
  service_plan_id     = azurerm_service_plan.tf-appserviceplan.id
  https_only          = true

  site_config {
    minimum_tls_version = "1.2"

    application_stack {
      docker_image     = "andreibirsan/todowebapp"
      docker_image_tag = "latest"
    }
  }
}

# Create the storage account for the webapp

resource "azurerm_storage_account" "tfstor-webapp" {
  name                     = "tfstoragewebapp"
  resource_group_name      = azurerm_resource_group.tfrg-webapp.name
  location                 = azurerm_resource_group.tfrg-webapp.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
# Create the storage container for the webapp
resource "azurerm_storage_container" "tfblob" {
  name                  = "tfblob-webapp"
  storage_account_name  = azurerm_storage_account.tfstor-webapp.name
  container_access_type = "private"
}
# Create the CosmosDB account for the webapp
resource "azurerm_cosmosdb_account" "tfcosmosdb-account" {
  name                      = "tfcosmosdb-account"
  location                  = azurerm_resource_group.tfrg-webapp.location
  resource_group_name       = azurerm_resource_group.tfrg-webapp.name
  offer_type                = "Standard"
  kind                      = "GlobalDocumentDB"
  enable_automatic_failover = false

  geo_location {
    location          = azurerm_resource_group.tfrg-webapp.location
    failover_priority = 0
  }
  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }
  depends_on = [
    azurerm_resource_group.tfrg-webapp
  ]
}

# Create the CosmosDB SQL database for the webapp
resource "azurerm_cosmosdb_sql_database" "tfcosmosdb-sql-database" {
  name                = "tfcosmosdb-sql-database"
  resource_group_name = azurerm_resource_group.tfrg-webapp.name
  account_name        = azurerm_cosmosdb_account.tfcosmosdb-account.name
}
# Create the CosmosDB container for the webapp
resource "azurerm_cosmosdb_sql_container" "tfcosmosdb-sql-container" {
  name                = "tfcosmosdb-sql-container"
  resource_group_name = azurerm_resource_group.tfrg-webapp.name
  account_name        = azurerm_cosmosdb_account.tfcosmosdb-account.name
  database_name       = azurerm_cosmosdb_sql_database.tfcosmosdb-sql-database.name
  partition_key_path  = "/definition/id"
}
# Create the service connector from the app service to the database. Resource name can only contain letters, numbers (0-9), periods ('.'), and underscores ('_')
resource "azurerm_app_service_connection" "tf-webapp-serviceconnector-database" {
  name               = "tf_webapp_serviceconnector_database"
  app_service_id     = azurerm_linux_web_app.tf-webapp.id
  target_resource_id = azurerm_cosmosdb_sql_database.tfcosmosdb-sql-database.id
  authentication {
    type = "systemAssignedIdentity"
  }
}
resource "azurerm_app_service_connection" "tf-webapp-serviceconnector-storage" {
  name               = "tf_webapp_serviceconnector_storage"
  app_service_id     = azurerm_linux_web_app.tf-webapp.id
  target_resource_id = azurerm_storage_account.tfstor-webapp.id
  authentication {
    type = "systemAssignedIdentity"
  }
}