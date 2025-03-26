Function Remove-ISCTenant {
    <#
.SYNOPSIS
    Remove a stored credential for an ISC tenant.

.DESCRIPTION
    Use this function to easily remove a credential object for a specific ISC tenant.

.INPUTS
    None

.OUTPUTS
    None

.EXAMPLE
    PS> Remove-ISCTenant -Tenant foo

.LINK
    https://github.com/sup3rmark/iscUtils

#>

    [CmdletBinding()]
    param(
        # Define the tenant to which you want to add a credential for.
        [Alias('Environment')]
        [Parameter (Mandatory = $true)]
        [ValidateNotNullOrWhiteSpace()]
        [String] $Tenant
    )

    try {
        $secretName = "ISC - $Tenant API"
        $secretInfo = Get-SecretInfo -Name $secretName -ErrorAction Stop
        Remove-Secret -Name $secretName -Vault $secretInfo.VaultName -ErrorAction Stop
        Write-Host "Configuration removed for $Tenant tenant."
    }
    catch {
        throw "Failed to remove configuration for $Tenant tenant. Exception: $($_.Exception.Message)"
    }
}