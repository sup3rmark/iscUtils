# iscUtils
 A collection of functions that call the SailPoint Identity Security Cloud API.

# Configuration
*Note: this module requires PowerShell 7, as well as the `Microsoft.PowerShell.SecretManagement` and `Microsoft.PowerShell.SecretStore` modules.*

1. (If you already have a Secret Vault established, you can skip this step.) Create a Secret Vault and set it as the default Vault: `Register-SecretVault -Name Default -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault`
   - You can remove the need to provide a password on every access of the Vault by running the following: `Set-SecretStoreConfiguration -Authentication None -Interaction None` (*Note: this is a less secure configuration and should not be used without understanding the risks associated therein.*). You may be prompted to set and provide a password during this process. While counter-intuitive, just go with it and set a password which will subsequently be ignored.
2. Generate a Personal Access Token in SailPoint and add to your newly-created Secret Vault:
   1. Access your tenant as normal (https://[tenant].identitynow.com)
   2. Click your name in the top right corner, and select **Preferences**
   3. Select **Personal Access Tokens** on the left-hand side
   4. Click **New Token**
   5. In the **What is this token for?** box, enter something meaningful like "PowerShell" or "VSCode" to help you identify the token in the list in the future.
   6. Search for `sp:scopes:all` in the search box, and click the slider for the resulting entry.
   7. Click **Create**.
   8. Copy your **Client ID** and **Client Secret** into this snippet and run the following to add an entry to your Secret Vault (*note: the Secret names set here are specific and must be set as listed here. This is the format that the iscUtils module will expect.*):
```powershell
$clientId = '(replace with Client ID)'
$clientSecret = '(replace with Client Secret)'
$org = '(replace with tenant name)'


[pscredential]$cred = New-Object System.Management.Automation.PSCredential ($clientId, (ConvertTo-SecureString $clientSecret -AsPlainText -Force))
Set-Secret -Name "ISC - $org API" -Secret $cred
```

Repeat Step 2 for all tenants you'd like to configure (prod, dev, etc.).

# Using the Module

## Connect-ISC -Tenant foo
This is the first command you'll need to run in order to establish a connection to the Identity Security Cloud API with the specified tenant. This will automatically retrieve the stored secret for the specified tenant and use that to connect.

This only needs to be done once per PowerShell session. Any subsequent calls can leverage the `-ReconnectAutomatically` parameter to automatically refresh the token if needed.

## -Source parameter
Functions that include a `-Source` parameter will automatically have the list of sources from your connected tenant populated for tab-completion using a dynamic parameter. The list of sources is populated by the `Connect-ISC` function, so if you've added a source that isn't showing, you'll likely need to run `Connect-ISC` again to update that list.

---

Thanks for checking out my module! It is not exhaustive, but wraps any of the Identity Security Cloud (aka IdentityNow) API endpoints that I've used in PowerShell. This makes it easier to manipulate and parse the data we get back from the API.

If there are [any other API endpoints](https://developer.sailpoint.com/docs/api/v3/) you'd like me to work on, or if you run into any trouble with any of the existing functions, please [open an Issue](https://github.com/sup3rmark/iscUtils/issues/new) and I'll see what I can do!
