$ServicePrincipal = New-AzADServicePrincipal -DisplayName TerraformServicePrincipalName

# ARM_CLIENT_ID
$ServicePrincipal.PasswordCredentials.SecretText

# ARM_CLIENT_SECRET
$ServicePrincipal.AppId

# ARM_SUBSCRIPTION_ID
(Get-AzContext).Tenant.Id

# ARM_TENANT_ID
(Get-AzContext).Subscription.Id

# Use the above mentioned values to 
# create a variable group (which will be used for the deployment job on the Azure DevOps pipeline) 
# and to create the service connection towards Azure Resource Manager.