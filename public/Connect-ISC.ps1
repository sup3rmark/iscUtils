#Requires -Modules Microsoft.PowerShell.SecretManagement
Function Connect-ISC {
    <#
.SYNOPSIS
    Connect to the ISC API.

.DESCRIPTION
    Use this function to connect to the specified Identity Security Cloud environment via the API.

.INPUTS
    None

.OUTPUTS
    None

.EXAMPLE
    PS> Connect-ISC -Environment foo
    
.EXAMPLE
    PS> Connect-ISC -Tenant foo -Verbose
    VERBOSE: ==========================================================
    VERBOSE: Connecting to foo Identity Security Cloud Environment!
    VERBOSE: ==========================================================
    VERBOSE: Successfully connected to the foo API endpoints at 12/31/2023 17:08:54.
    VERBOSE: 
    id     name                               description
    --     ----                               -----------
    12345  IdentityNow Admins                 Local break glass accounts for IDN Admins
    23456  Non SSO Users                      Users who can bypass SSO

.LINK
    
#>

    [CmdletBinding()]
    param(
        # Define the tenant to which you want to connect.
        [Alias('Environment')]
        [ValidateNotNullOrWhiteSpace()]
        [String] $Tenant,

        # Specify which domain the tenant is in.
        [ValidateSet('Default', 'Demo', 'FedRamp')]
        [String] $Domain = 'Default'
    )

    $script:iscTenant = $Tenant
    Write-Verbose '================================================================='
    Write-Verbose "Connecting to $Tenant Identity Security Cloud $(if ($Domain -ne 'Default') {"$Domain "}) Environment!"
    Write-Verbose '================================================================='

    $script:iscV3APIurl = switch ($Domain) {
        'Default' { "https://$script:iscTenant.api.identitynow.com" }
        'Demo' { "https://$script:iscTenant.api.identitynow-demo.com" }
        'FedRamp' { "https://$script:iscTenant.api.saas.sailpointfedramp.com" }
    }

    try {
        $credentialObject = Get-Secret -Name "ISC - $script:iscTenant API" -ErrorAction Stop
        $script:iscClientID = $credentialObject.username
        $script:iscClientSecret = $credentialObject.GetNetworkCredential().Password
    }
    catch {
        throw "Failed to retrieve ISC credentials from the PowerShell Secret Store. Exception: $($_.Exception.Message)"
    }
    $script:iscBase64APIkey = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$($script:iscClientID):$($script:iscClientSecret)"))
    $script:basicAuthHeader = @{Authorization = "Basic $script:iscBase64APIkey" }
    $script:cType = 'application/json;charset=utf-8'
    $script:basicAuthArgs = @{
        Headers     = $script:basicAuthHeader
        ContentType = $script:cType
        ErrorAction = 'Stop'
    }

    try {
        $oauthURLParams = @(
            'grant_type=client_credentials'
            "client_id=$script:iscClientID"
            "client_secret=$script:iscClientSecret"
        )
        $oauthTokenArgs = @{
            Uri    = "$script:iscV3APIurl/oauth/token?$($oauthURLParams -join '&')"
            Method = 'Post'
        }
        Write-Verbose "URL: $($oauthTokenArgs.URI)"
        $script:iscOauthToken = Invoke-RestMethod @oauthTokenArgs @script:basicAuthArgs
        $script:iscConnectionTimestamp = Get-Date
        $script:iscConnectionExpiration = $script:iscConnectionTimestamp.AddSeconds($script:iscOauthToken.expires_in)
        Write-Verbose "Successfully connected to the $script:iscTenant API endpoints at $script:iscConnectionTimestamp."

        $script:bearerAuthHeader = @{Authorization = "Bearer $($script:iscOauthToken.access_token)" }
        $script:bearerAuthArgs = @{
            Headers     = $script:bearerAuthHeader
            ContentType = "$script:cType"
            ErrorAction = 'Stop'
        }
        
        [array]$script:iscSources = Invoke-RestMethod -Uri "$script:iscV3APIurl/v3/sources" @script:bearerAuthArgs
        Write-Verbose ($script:iscSources | Select-Object id, name, description | Format-Table | Out-String)
    }
    catch {
        Write-Error "Failed to connect to the $script:iscTenant API endpoints. Exception: $($_.Exception.Message)"
    }
}