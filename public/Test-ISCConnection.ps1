Function Test-ISCConnection {
    <#
.SYNOPSIS
    Checks how old the existing Identity Security Cloud connection is.

.INPUTS
    None

.OUTPUTS
    System.Management.Automation.PSCustomObject

.DESCRIPTION
    Use this tool to check whether there's an existing connection to Identity Security Cloud, and if so, how old it is.
    Throws an error if the connection is expired or doesn't exist. Otherwise, returns information about the connection.
    Optional flag to automatically connect/reconnect to Identity Security Cloud if there is no valid connection.

.EXAMPLE
    PS> Test-ISCConnection

.LINK
    https://github.csnzoo.com/shared/pwsh-iscUtils
#>
    [CmdletBinding()]
    param(
        # Check whether there is an active oAuth token. If not, request a new token for the previous connection.
        [Parameter (Mandatory = $false)]
        [Switch] $ReconnectAutomatically
    )

    $spConnection = Get-ISCConnection
    
    # If the connection is older than the default expiration time, and $ReconnectAutomatically isn't flagged, abort
    if (-NOT $spConnection.Timestamp) {
        throw 'ERROR: Connection to Identity Security Cloud has not been established. You must first connect manually using Connect-ISCAPI.'
    }

    if ($spConnection.TokenExpiration -lt $(Get-Date) -AND -NOT $ReconnectAutomatically) {
        throw 'ERROR: Connection is likely expired. Either reconnect manually using Connect-ISCAPI or use -ReconnectAutomatically flag.'
    }
    elseif ($spConnection.TokenExpiration -lt $(Get-Date) -AND $ReconnectAutomatically) {
        Connect-ISCAPI -Tenant $spConnection.Tenant
        Write-Verbose 'INFO: Connection is likely expired. Reconnecting automatically.'
        Return $(Get-ISCConnection)
    }
    elseif ($spConnection.TokenExpiration -gt $(Get-Date)) {
        Return $spConnection
    }
}