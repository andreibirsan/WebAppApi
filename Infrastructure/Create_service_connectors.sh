WEBAPP=$(az webapp list --resource-group tfrg_webapp-api --query "[].{Name:repositorySiteName}" --output tsv)
STORAGEACCOUNT=$(az storage account list --resource-group tfrg_webapp-api --query "[].{Name:name}" --output tsv)
COSMOSDBACCOUNT=$(az cosmosdb list --resource-group tfrg_webapp-api --query "[].{Name:name}" --output tsv)
COSMOSDBDATABASE=$(az cosmosdb sql database list --resource-group tfrg_webapp-api --account-name $COSMOSDBACCOUNT --query "[].{Name:name}" --output tsv)
az webapp connection create storage-blob --connection tfwebappserviceconnectorstorage -g tfrg_webapp-api -n $WEBAPP --tg tfrg_webapp-api --account $STORAGEACCOUNT --system-identity --client-type dotnet
az webapp connection create cosmos-sql --connection tfwebappserviceconnectordatabase -g tfrg_webapp-api -n $WEBAPP --tg tfrg_webapp-api --account $COSMOSDBACCOUNT --database COSMOSDBDATABASE --system-identity --client-type dotnet