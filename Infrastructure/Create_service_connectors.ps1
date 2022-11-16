Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

$WebAppName = Get-AzWebApp -ResourceGroupName tfrg_webapp-api
$StorageAccount = Get-AzStorageAccount -ResourceGroupName tfrg_webapp-api
$CosmosDbAccount = Get-AzCosmosDBAccount -ResourceGroupName tfrg_webapp-api
$CosmosDbSqlDatabase = Get-AzCosmosDBSqlDatabase -ResourceGroupName tfrg_webapp-api -AccountName $CosmosDbAccount.Name

az webapp connection create storage-blob --connection tfwebappserviceconnectorstorage -g tfrg_webapp-api -n $WebAppName.Name --tg tfrg_webapp-api --account $StorageAccount.StorageAccountName --system-identity --client-type dotnet
az webapp connection create cosmos-sql --connection tfwebappserviceconnectordatabase -g tfrg_webapp-api -n $WebAppName.Name --tg tfrg_webapp-api --account $CosmosDb.Name --database $CosmosDbSqlDatabase.Name --system-identity --client-type dotnet


