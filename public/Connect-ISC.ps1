#Requires -Modules Microsoft.PowerShell.SecretManagement
function Connect-ISC {
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
    PS> Connect-ISC -Environment bar -Domain Demo

.EXAMPLE
    PS> Connect-ISC -Environment baz -Domain FedRamp
    
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
    https://github.com/sup3rmark/iscUtils

#>

    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param(
        # Define the tenant to which you want to connect.
        [Alias('Environment')]
        [Parameter (
            Mandatory = $true,
            ParameterSetName = 'Default'
        )]
        [Parameter (
            Mandatory = $true,
            ParameterSetName = 'PAT'
        )]
        [ValidateNotNullOrWhiteSpace()]
        [String] $Tenant,

        # Specify which domain the tenant is in.
        [Parameter ()]
        [ValidateSet('Default', 'Demo', 'FedRamp')]
        [String] $Domain = 'Default',

        # Specify a Client ID to connect with a PAT.
        [Parameter (
            Mandatory = $true,
            ParameterSetName = 'PAT'
        )]
        [ValidateNotNullOrEmpty()]
        [String] $ClientID,

        # Specify a Client Secret to connect with a PAT.
        [Parameter (
            Mandatory = $true,
            ParameterSetName = 'PAT'
        )]
        [ValidateNotNullOrEmpty()]
        [SecureString] $ClientSecret
    )

    $script:iscTenant = $Tenant
    Write-Verbose '================================================================='
    Write-Verbose "Connecting to $Tenant Identity Security Cloud Tenant!"
    Write-Verbose '================================================================='

    if ($ClientID) {
        $script:iscClientID = $ClientID
        $script:iscClientSecret = $ClientSecret | ConvertFrom-SecureString -AsPlainText
    }
    else {
        try {
            $credentialObject = Get-Secret -Name "ISC - $script:iscTenant API" -ErrorAction Stop
            $script:iscClientID = $credentialObject.username
            $script:iscClientSecret = $credentialObject.GetNetworkCredential().Password
        }
        catch {
            throw "Failed to retrieve ISC credentials from the PowerShell Secret Store. Exception: $($_.Exception.Message)"
        }
    }

    $metadataDomain = Get-SecretInfo -Name "ISC - $script:iscTenant API"

    if ($metadataDomain.Metadata.Domain -and ($Domain -ne $metadataDomain.Metadata.Domain)) {
        Write-Verbose "Provided Domain value $Domain does not match value stored in Secret. Overriding to $($metadataDomain.Metadata.Domain)."
        $Domain = $metadataDomain.Metadata.Domain
    }

    if ($null -eq $Domain) {
        throw 'No Domain stored in Secret for specified Tenant. Please provide a Domain value.'
    }

    $script:iscDomain = $Domain
    Write-Verbose "Domain set to $script:iscDomain."

    $script:iscAPIurl = switch ($script:iscDomain) {
        'Default' { "https://$script:iscTenant.api.identitynow.com" }
        'Demo' { "https://$script:iscTenant.api.identitynow-demo.com" }
        'FedRamp' { "https://$script:iscTenant.api.saas.sailpointfedramp.com" }
    }

    try {
        $oauthBody = @{
            grant_type    = 'client_credentials'
            client_id     = "$script:iscClientID"
            client_secret = "$script:iscClientSecret"
        }
        $oauthTokenArgs = @{
            Uri         = "$script:iscAPIurl/oauth/token"
            Form        = $oauthBody
            Method      = 'Post'
            ContentType = 'application/x-www-form-urlencoded'
        }
        Write-Verbose "URL: $($oauthTokenArgs.URI)"
        $script:iscOauthToken = Invoke-RestMethod @oauthTokenArgs
        $script:iscConnectionTimestamp = Get-Date
        $script:iscConnectionExpiration = $script:iscConnectionTimestamp.AddSeconds($script:iscOauthToken.expires_in)
        Write-Verbose "Successfully connected to the $script:iscTenant API endpoints at $script:iscConnectionTimestamp."

        $script:bearerAuthHeader = @{Authorization = "Bearer $($script:iscOauthToken.access_token)" }
        $script:bearerAuthArgs = @{
            Headers     = $script:bearerAuthHeader
            ContentType = 'application/json;charset=utf-8'
            ErrorAction = 'Stop'
        }
        
        [array]$script:iscSources = Invoke-RestMethod -Uri "$script:iscAPIurl/v3/sources" @script:bearerAuthArgs
        Write-Verbose ($script:iscSources | Select-Object id, name, description | Format-Table | Out-String)
    }
    catch {
        Write-Error "Failed to connect to the $script:iscTenant API endpoints. Exception: $($_.Exception.Message)"
    }
}