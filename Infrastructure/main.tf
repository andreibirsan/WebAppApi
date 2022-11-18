# Generate a random integer to create a globally unique name
resource "random_integer" "random" {
  min = 1000000
  max = 9999999
  keepers = {
    tfrg_id = azurerm_resource_group.tfrg-webapp.id
  }
}

# Create the resource group for the webapp
resource "azurerm_resource_group" "tfrg-webapp" {
  name     = "tfrg_webapp-api"
  location = var.location
  tags     = var.tags
}

# Create the App Service Plan
resource "azurerm_service_plan" "tf-appserviceplan" {
  name                = "tf_app-service-plan_webapp-api"
  location            = azurerm_resource_group.tfrg-webapp.location
  resource_group_name = azurerm_resource_group.tfrg-webapp.name
  os_type             = "Linux"
  sku_name            = var.appservice_sku
  tags                = var.tags
}

# Create the web app
resource "azurerm_linux_web_app" "tf-webapp" {
  name                = "webapp-api${random_integer.random.id}"
  location            = azurerm_resource_group.tfrg-webapp.location
  resource_group_name = azurerm_resource_group.tfrg-webapp.name
  service_plan_id     = azurerm_service_plan.tf-appserviceplan.id
  https_only          = true
  tags                = var.tags

  app_settings = {
    "AZURE_COSMOS_LISTCONNECTIONSTRINGURL" = "https://management.azure.com${azurerm_cosmosdb_account.tfcosmosdb-account.id}/listConnectionStrings?api-version=2021-04-15"
    "AZURE_COSMOS_RESOURCEENDPOINT"        = "${azurerm_cosmosdb_account.tfcosmosdb-account.endpoint}"
    "AZURE_COSMOS_SCOPE"                   = "https://management.azure.com/.default"
    "AZURE_STORAGEBLOB_RESOURCEENDPOINT"   = "${azurerm_storage_account.tfstor-webapp.primary_blob_endpoint}"
  }
  identity {
    type = "SystemAssigned"
  }
  site_config {
    minimum_tls_version     = "1.2"
    ftps_state              = "Disabled"
    scm_minimum_tls_version = "1.2"

    application_stack {
      docker_image     = var.docker_image
      docker_image_tag = var.imagebuild
    }
  }
}

# Create the App Service Plan scale out settings
resource "azurerm_monitor_autoscale_setting" "autoscale-setting" {
  name                = "tf_app-service-plan_webapp-api-autoscale-settings"
  resource_group_name = azurerm_resource_group.tfrg-webapp.name
  location            = azurerm_resource_group.tfrg-webapp.location
  target_resource_id  = azurerm_service_plan.tf-appserviceplan.id

  profile {
    name = "Default scaling"
    capacity {
      default = 1
      minimum = 1
      maximum = 20
    }
    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.tf-appserviceplan.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 90
      }
      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.tf-appserviceplan.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 10
      }
      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
    rule {
      metric_trigger {
        metric_name        = "MemoryPercentage"
        metric_resource_id = azurerm_service_plan.tf-appserviceplan.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 85
      }
      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
    rule {
      metric_trigger {
        metric_name        = "MemoryPercentage"
        metric_resource_id = azurerm_service_plan.tf-appserviceplan.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 50
      }
      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }
  notification {
    email {
      send_to_subscription_administrator = true
    }
  }
}

# Create the storage account for the webapp
resource "azurerm_storage_account" "tfstor-webapp" {
  name                      = "tfstoragewebapp${random_integer.random.id}"
  resource_group_name       = azurerm_resource_group.tfrg-webapp.name
  location                  = azurerm_resource_group.tfrg-webapp.location
  account_tier              = "Standard"
  access_tier               = "Hot"
  account_kind              = "StorageV2"
  account_replication_type  = "GRS"
  min_tls_version           = "TLS1_2"
  enable_https_traffic_only = "true"
  tags                      = var.tags
  network_rules {
    bypass                     = ["AzureServices"]
    default_action             = "Allow"
    ip_rules                   = []
    virtual_network_subnet_ids = []
  }
}

# Create the storage container for the webapp
resource "azurerm_storage_container" "tfblob" {
  name                  = "tfblob-webapp"
  storage_account_name  = azurerm_storage_account.tfstor-webapp.name
  container_access_type = "private"
}

# Create the CosmosDB account for the webapp
resource "azurerm_cosmosdb_account" "tfcosmosdb-account" {
  name                      = "tfcosmosdb-account${random_integer.random.id}"
  location                  = azurerm_resource_group.tfrg-webapp.location
  resource_group_name       = azurerm_resource_group.tfrg-webapp.name
  offer_type                = "Standard"
  kind                      = "GlobalDocumentDB"
  enable_automatic_failover = false
  tags                      = var.tags

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

/*
Seems that after the initial terraform apply the managed identity and the connection strings are removed from the app service configuration.
To find a solution for this!
*/

# Create the service connector from the app service to the database. Resource name can only contain letters, numbers (0-9), periods ('.'), and underscores ('_')
resource "azurerm_app_service_connection" "tf-webapp-serviceconnector-database" {
  name               = "tfwebappserviceconnectordatabase"
  app_service_id     = azurerm_linux_web_app.tf-webapp.id
  target_resource_id = azurerm_cosmosdb_sql_database.tfcosmosdb-sql-database.id
  client_type        = "dotnet"
  authentication {
    type = "systemAssignedIdentity"
  }
}

# Create the service connector from the app service to the storage account. Resource name can only contain letters, numbers (0-9), periods ('.'), and underscores ('_')
resource "azurerm_app_service_connection" "tf-webapp-serviceconnector-storage" {
  name               = "tfwebappserviceconnectorstorage"
  app_service_id     = azurerm_linux_web_app.tf-webapp.id
  target_resource_id = azurerm_storage_account.tfstor-webapp.id
  client_type        = "dotnet"
  authentication {
    type = "systemAssignedIdentity"
  }
} 