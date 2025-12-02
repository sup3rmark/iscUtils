# iscUtils
 A collection of functions that call the SailPoint Identity Security Cloud API.

# Configuration
*Note: this module requires PowerShell 7.*

The `Microsoft.PowerShell.SecretManagement` and `Microsoft.PowerShell.SecretStore` modules were previously required, but are now optional.

## Connect with stored credentials
1. (If you already have a Secret Vault established, you can skip this step.) Create a Secret Vault and set it as the default Vault: `Register-SecretVault -Name Default -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault`
   - You can remove the need to provide a password on every access of the Vault by running the following: `Set-SecretStoreConfiguration -Authentication None -Interaction None` (*Note: this is a less secure configuration and should not be used without understanding the risks associated therein.*). You may be prompted to set and provide a password during this process. While counter-intuitive, just go with it and set a password which will subsequently be ignored.
2. Generate a Personal Access Token in SailPoint and add to your newly-created Secret Vault:
   1. Access your tenant as normal (https://[tenant].identitynow.com, probably)
   2. Click your name in the top right corner, and select **Preferences**
   3. Select **Personal Access Tokens** on the left-hand side
   4. Click **New Token**
   5. In the **What is this token for?** box, enter something meaningful like "PowerShell" or "VSCode" to help you identify the token in the list in the future.
   6. Search for `sp:scopes:all` in the search box, and click the slider for the resulting entry.
   7. Click **Create**.
   8. Copy your **Client ID** and **Client Secret** into this snippet and run New-ISCTenant, passing in the tenant name (the `{tenant}` part in `https://{tenant}.identitynow.com`) along with **either** a ClientID and a ClientSecret (the latter of which needs to be a SecureString) **or** a Credential Object (which you can either make by hand or with Get-Credential, using the ClientID as the username and the ClientSecret as the password in either case).
   9. If your tenant is in the FedRamp domain (`https://{tenant}.saas.sailpointfedramp.com`) or the Demo domain (`https://{tenant}.identitynow-demo.com`), you'll want to specify that when creating the tenant configuration using the `-Domain` parameter.

You can do something like this:
```powershell
New-ISCTenant -Tenant 'devrel-ga-xxxx' -Domain Demo -ClientID '1619...426d' -ClientSecret ('cd2c.......b178' | ConvertTo-SecureString -AsPlainText -Force)
```
Or this:
```powershell
$clientID = '1619...426d'
$clientSecret = 'cd2c.......b178' | ConvertTo-SecureString -AsPlainText -Force

$credential = [PSCredential]::New($clientID, $clientSecret)

New-ISCTenant -Tenant 'devrel-ga-xxxx' -Domain Demo -Credential $credential
```
Or this:
```powershell
$credential = Get-Credential

New-ISCTenant -Tenant 'devrel-ga-xxxx' -Domain Demo $credential
```
Alternatively, you can manually create the Secret yourself, but *note that the Secret names set here are specific and must be set as listed. This is the format that the iscUtils module will expect*. 
```powershell
$clientId = '(replace with Client ID)'
$clientSecret = '(replace with Client Secret)'
$org = '(replace with tenant name)'

[pscredential]$cred = New-Object System.Management.Automation.PSCredential ($clientId, (ConvertTo-SecureString $clientSecret -AsPlainText -Force))
Set-Secret -Name "ISC - $org API" -Secret $cred
```

Repeat for all tenants you'd like to configure (prod, dev, etc.).

If you'd like to modify an existing tenant configuration, you can still use `New-ISCTenant`, but you'll need to use the `-Force` flag to allow the function to overwrite the existing entry.

If you'd like to remove an existing tenant configuration:
```powershell
Remove-ISCTenant -Tenant 'devrel-ga-xxxx'
```

## Connect without storing credentials
If, for whatever reason, you can't (or just don't want to) store your credentials in the PowerShell Secret Vault, you now have the option to connect by passing in a PAT at runtime (see above for instructions on generating a PAT):
```powershell
Connect-ISC -Tenant 'devrel-ga-xxxx' -Domain Demo -ClientID '1619...426d' -ClientSecret ('cd2c.......b178' | ConvertTo-SecureString -AsPlainText -Force)
```
Note that the ClientSecret is still expecting a SecureString.


# Using the Module

## Connect-ISC -Tenant foo -Domain Default
This is the first command you'll need to run in order to establish a connection to the Identity Security Cloud API with the specified tenant. This will automatically retrieve the stored secret for the specified tenant and use that to connect.

If your tenant is on the identitynow.com domain, the `-Domain` param is optional, but you can specify `Demo` if your tenant is in the identitynow-demo.com domain or `FedRamp` if your tenant is in the FedRamp domain ([tenant].saas.sailpointfedramp.com).

This only needs to be done once per PowerShell session. Any subsequent calls can leverage the `-ReconnectAutomatically` parameter to automatically refresh the token if needed.

## -Source parameter
Functions that include a `-Source` parameter will automatically have the list of sources from your connected tenant populated for tab-completion using a dynamic parameter. The list of sources is populated by the `Connect-ISC` function, so if you've added a source that isn't showing, you'll likely need to run `Connect-ISC` again to update that list.

# Example Commands

This list is non-exhaustive and just gives some examples of things you can do with the functions contained herein.

## Get current connection
```powershell
# Get the connection
Get-ISCConnection

# Get the connection and include the sources as an attribute in the reponse object
Get-ISCConnection -IncludeSources

# Select the name, source ID, connector name, and description of all sources in the connected tenant
(Get-ISCConnection -IncludeSources).SourceList | Select-Object name, id, connectorName, description
```

## Refresh the token if we're approaching the expiration time
```powershell
Test-ISCConnection -ReconnectAutomatically
```

## Get Accounts
```powershell
# Get a list of all accounts
$accounts = Get-ISCAccount -List

# Get a list of all accounts in the Active Directory source
$accounts = Get-ISCAccount -List -Source 'Active Directory'

# Get all attributes for all accounts in the Active Directory source and send them to the Clipboard in a format that can be pasted into Excel
Get-ISCAccount -List -Source 'Active Directory' -SchemaAttributes | ConvertTo-Csv -Delimiter "`t" | Set-Clipboard

# Get a list of all uncorrelated accounts in the Active Directory source, and output the account attributes to Out-GridView (Windows only)
Get-ISCAccount -List -Source 'Active Directory' -Uncorrelated -SchemaAttributes | Out-GridView
```

## Get Identities
```powershell
# Get a list of all identities
$identity = Get-ISCIdentity -List

# Get all attributes for all identities
$identity = Get-ISCIdentity -List -IdentityAttributes

# Get all attributes for all identities and send them to the Clipboard in a format that can be pasted into Excel
Get-ISCIdentity -List -IdentityAttributes | ConvertTo-Csv -Delimiter "`t" | Set-Clipboard

# Get all accounts correlated to the identity with EmployeeNumber 2
(Get-ISCIdentity -EmployeeNumber 2 -IncludeNested).accounts

# Get all identities with a lastname value of Ackbar
Get-ISCIdentity -CustomQuery 'attributes.lastname:ackbar'
```

## Get Entitlement/Set Entitlement
```powershell
# Get all entitlements on the Active Directory source
Get-ISCEntitlement -List -Source 'Active Directory'

# Get an entitlement called "flatGroup" from the Active Directory source, update the owner to the identity with an Employee Number value of 2, and mark the entitlement as Privileged
Get-ISCEntitlement -Name flatGroup -Source 'Active Directory' | Set-ISCEntitlement -OwnerEmployeeNumber 2 -Privileged $true

# Get all entitlements from the Active Directory source and loop through each one, updating the owner to the identity with an Employee Number value of 2, and marking the entitlement as Privileged
$entitlements = Get-ISCEntitlement -List -Source 'Active Directory'
foreach ($entitlement in $entitlements) {
    Set-ISCEntitlement -ID $entitlement.id -OwnerEmployeeNumber 2 -Privileged $false
}
```

## Perform a Search query
```powershell
Invoke-ISCQuery -Query 'attributes.lastname:organa' -Index Identities
```


---

Thanks for checking out my module! It is not exhaustive, but wraps any of the Identity Security Cloud (aka IdentityNow) API endpoints that I've used in PowerShell. This makes it easier to manipulate and parse the data we get back from the API.

If there are [any other API endpoints](https://developer.sailpoint.com/docs/api/v3/) you'd like me to work on, or if you run into any trouble with any of the existing functions, please [open an Issue](https://github.com/sup3rmark/iscUtils/issues/new) and I'll see what I can do!
