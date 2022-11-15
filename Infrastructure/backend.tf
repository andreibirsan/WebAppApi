# Save the tfstate file in a manually created Azure storage account
terraform {
  backend "azurerm" {
    resource_group_name  = "rg4terraform"
    storage_account_name = "storaccount4terraform"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
} 