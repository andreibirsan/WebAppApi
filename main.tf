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
terraform {
  backend "azurerm" {
    resource_group_name  = "tf_rg_blobstore"
    storage_account_name = "tfstorage131120222"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

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
  name     = "tf_rg_webapp-api"
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
      docker_image        = "andreibirsan/todowebapp"
      docker_image_tag    = "latest"
    }
  }
}

# Create the resourcegroup, storage account and container for the webapp
resource "azurerm_resource_group" "tfrg-webapp-storageaccount" {
  name     = "tf_webapp-storageaccount"
  location = "West Europe"
}

resource "azurerm_storage_account" "tfstor-webapp" {
  name                     = "tfstoragewebapp"
  resource_group_name      = azurerm_resource_group.tfrg-webapp-storageaccount.name
  location                 = azurerm_resource_group.tfrg-webapp-storageaccount.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "tfblob" {
  name                  = "tfblob-webapp"
  storage_account_name  = azurerm_storage_account.tfstor-webapp.name
  container_access_type = "private"
}
