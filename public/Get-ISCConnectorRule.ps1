Function Get-ISCConnectorRule {
    <#
.SYNOPSIS
    Retrieves connector rules from Identity Security Cloud.

.DESCRIPTION
    Use this tool to retrieve all connector rules from Identity Security Cloud, or a specific connector rule by providing the ID of the connector rule you want to see.

.INPUTS
    None

.OUTPUTS
    System.Management.Automation.PSCustomObject for individual transforms.
    System.Object[] when run with -All flag.
    
.EXAMPLE
    PS> Get-ISCConnectorRule -Id 2cXXXXXXXXXXXXXXXXXXXXXXXXXXXX50
    
.EXAMPLE
    PS> Get-ISCConnectorRule -All

.LINK
    
#>
    [CmdletBinding()]
    param(
        # Check whether there is an active oAuth token. If not, request a new token for the previous connection.
        [Parameter (Mandatory = $false)]
        [Switch] $ReconnectAutomatically,

        [Parameter (
            Mandatory = $true,
            ParameterSetName = 'All',
            HelpMessage = 'Retrieves connector rules from Identity Security Cloud.'
        )]
        [Switch] $All,

        [Parameter (
            Mandatory = $true,
            ParameterSetName = 'Id',
            HelpMessage = 'Enter the ID of a specific connector rule to retrieve.'
        )]
        [ValidateNotNullOrEmpty()]
        [String] $Id,

        # Specifies whether to output the API response directly to the console for debugging.
        [Parameter (Mandatory = $false)]
        [Switch] $DebugResponse
    )

    try {
        $spConnection = Test-ISCConnection -ReconnectAutomatically:$ReconnectAutomatically -ErrorAction Stop
        Write-Verbose "Connected to $($spConnection.Tenant) Identity Security Cloud."
    }
    catch {
        throw $_.Exception
    }

    $url = "$script:iscV3APIurl/beta/connector-rules"
    if ($Id) {
        $url += "/$Id"
    }

    $rulesData = @()
    Write-Verbose "Calling $url"
    try {
        $rulesData = Invoke-RestMethod -Uri $url -Method Get -ResponseHeadersVariable responseHeaders @script:bearerAuthArgs
        
        if ($DebugResponse) {
            Write-Host $rulesData
        }

        if ($rulesData.count -eq 0 -and $null -ne $Id) {
            throw "Failed to find connector rule with ID '$Id'. Please verify ID by using -All instead of specifying an ID."
        }        
    }
    catch {
        throw $_.Exception
    }
    Write-Verbose "Retrieved $($rulesData.count) records."

    Write-Verbose 'Finished retrieving connector rules.'
    return $rulesData
}