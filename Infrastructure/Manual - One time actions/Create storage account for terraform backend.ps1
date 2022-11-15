$ResourceGroupName = "rg4terraform"
$Location = "West Europe"
$Tags = @{owner="manualy created"}
$StorageAccountName = "storaccount4terraform"
$StorageContainerName = "tfstate"

Connect-AzAccount

New-AzResourceGroup `
    -Name $ResourceGroupName `
    -Location $Location `
    -Tag $Tags

New-AzStorageAccount `
    -ResourceGroupName $ResourceGroupName `
    -Name $StorageAccountName `
    -Location $Location `
    -SkuName Standard_GRS `
    -Kind BlobStorage `
    -AccessTier Hot `
    -MinimumTlsVersion TLS1_2 `
    -Tag $Tags

$Context = New-AzStorageContext `
    -StorageAccountName $StorageAccountName `
    -UseConnectedAccount

New-AzStorageContainer `
    -Name $StorageContainerName `
    -Context $Context
