Function Get-ISCConnection {
    <#
.SYNOPSIS
    Retrieves information about the most recent connection to Identity Security Cloud.

.DESCRIPTION
    Use this tool to retrieve the values associated with script variables set by other functions in this module.

.INPUTS
    None

.OUTPUTS
    System.Management.Automation.PSCustomObject

.EXAMPLE
    PS> Get-ISCConnection

    Timestamp       : 01/01/2019 3:30:00 PM
    TokenExpiration : 01/01/2019 3:42:30 PM
    Environment     : foo
    Token           : [token]
    Domain          : Default
    v3URL           : https://instance.api.identitynow.com

.LINK
    https://github.com/sup3rmark/iscUtils

#>

    [CmdletBinding()]
    param(
        # Specify whether to include the list of sources from the current Identity Security Cloud connection.
        [Parameter (Mandatory = $false)]
        [Switch] $IncludeSources
    )

    $connectionObject = New-Object PSObject
    $connectionObject | Add-Member -Type NoteProperty -Name 'Timestamp' -Value $script:iscConnectionTimestamp
    $connectionObject | Add-Member -Type NoteProperty -Name 'TokenExpiration' -Value $script:iscConnectionExpiration
    $connectionObject | Add-Member -Type NoteProperty -Name 'Tenant' -Value $script:iscTenant
    $connectionObject | Add-Member -Type NoteProperty -Name 'Domain' -Value $script:iscDomain
    $connectionObject | Add-Member -Type NoteProperty -Name 'Token' -Value $script:iscOauthToken.access_token
    $connectionObject | Add-Member -Type NoteProperty -Name 'API URL' -Value $script:iscAPIurl
    if ($IncludeSources.IsPresent) {
        $connectionObject | Add-Member -Type NoteProperty -Name 'SourceList' -Value $script:iscSources
    }

    return $connectionObject
}