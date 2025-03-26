Function New-ISCTenant {
    <#
.SYNOPSIS
    Create a stored credential for a new ISC tenant.

.DESCRIPTION
    Use this function to easily create and store a credential object for a specific ISC tenant.

.INPUTS
    None

.OUTPUTS
    None

.EXAMPLE
    PS> New-ISCTenant -Tenant foo -ClientID $clientId -ClientSecret $clientSecret

.EXAMPLE
    PS> New-ISCTenant -Tenant foo -ClientID bar -ClientSecret ('bash' | ConvertTo-SecureString -AsPlainText -Force)

.EXAMPLE
    PS> New-ISCTenant -Tenant foo -Credential $credentialObject

.LINK
    https://github.com/sup3rmark/iscUtils

#>

    [CmdletBinding()]
    param(
        # Define the tenant to which you want to add a credential for.
        [Alias('Environment')]
        [Parameter (Mandatory = $true)]
        [ValidateNotNullOrWhiteSpace()]
        [String] $Tenant,

        # Specify the Client ID you'd like to store.
        [Parameter (
            Mandatory = $true,
            ParameterSetName = 'ClientCredentials'
        )]
        [ValidateNotNullOrWhiteSpace()]
        [String] $ClientID,

        # Specify the Client Secret you'd like to store.
        [Parameter (
            Mandatory = $true,
            ParameterSetName = 'ClientCredentials'
        )]
        [ValidateNotNullOrWhiteSpace()]
        [SecureString] $ClientSecret,

        # Specify the Credential Object you'd like to store.
        [Parameter (
            Mandatory = $true,
            ParameterSetName = 'CredentialObject'
        )]
        [ValidateNotNullOrWhiteSpace()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()] $Credential,

        # Optionally specify which domain the tenant is in.
        [Parameter (Mandatory = $false)]
        [ValidateSet('Default', 'Demo', 'FedRamp')]
        [String] $Domain,

        # Overwrite any existing credential for this tenant.
        [Parameter (Mandatory = $false)]
        [Switch] $Force
    )

    if ($PsCmdlet.ParameterSetName -eq 'ClientCredentials') {
        $Credential = [PSCredential]::New($ClientID, $ClientSecret)
    }

    if ($Credential) {
        $splat = @{
            Name   = "ISC - $Tenant API"
            Secret = $Credential 
        }
        if ($Domain) {
            $splat += @{ Metadata = @{ Domain = $Domain } }
            Write-Verbose "$Domain Domain added to Secret Metadata."
        }
        if ((Get-Secret -Name $splat.Name) -and -not $Force) {
            throw "Secret already exists for $Tenant tenant. Specify Force to update the existing configuration."
        }
        Set-Secret @splat
        Write-Host "Configuration saved for $Tenant tenant$(if ($Domain){" with a $Domain domain"})."
    }
    else {
        throw 'No credential provided.'
    }
}