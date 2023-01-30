# Import the AzureAD module
Install-Module -Name AzureAD

# Connect to Azure AD
Connect-AzureAD

# Get the tenant ID
$tenantId = (Get-AzureADTenantDetail).ObjectId

# Get the client ID for the Microsoft Store for Business app
$clientId = (Get-AzureADApplication | Where-Object { $_.DisplayName -eq "Microsoft Store for Business" }).AppId

# Create an authentication context for the tenant
$authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList "https://login.microsoftonline.com/$tenantId"

# Get an access token using the client ID and a null user credential (prompts for login)
$authResult = $authContext.AcquireTokenAsync("https://manage.devcenter.microsoft.com/.default", $clientId, [Microsoft.IdentityModel.Clients.ActiveDirectory.UserCredential]::null).Result

# Get the access token from the result
$accessToken = $authResult.AccessToken

# Get a list of apps from the Store for Business API using the access token
$appList = Invoke-RestMethod -Method Get -Uri "https://manage.devcenter.microsoft.com/v1.0/my/applications" -Headers @{ "Authorization" = "Bearer $accessToken" }

# Create an array to hold the app details
$appDetails = @()

# Loop through each app and add its details to the array
foreach ($app in $appList) {
    $appDetails += [pscustomobject]@{
        "App Name" = $app.displayName
        "App Id" = $app.identifierName
        "App Version" = $app.version
        "App Publisher" = $app.publisherDisplayName
    }
}

# Prompt for a file save location
$saveFile = [Microsoft.Win32.SaveFileDialog]::new()
$saveFile.Filter = "CSV files|*.csv"
$saveFile.Title = "Save App Details"

if ($saveFile.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    # Save the app details to the selected file location as a CSV
    $appDetails | Export-Csv -Path $saveFile.FileName -NoTypeInformation
}
