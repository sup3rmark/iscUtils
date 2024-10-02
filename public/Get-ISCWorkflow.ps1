Function Get-ISCWorkflow {
    <#
.SYNOPSIS
    Retrieve a specific workflow from Identity Security Cloud.

.DESCRIPTION
    Use this tool to retrieve a specific workflow from Identity Security Cloud by providing the name of the workflow you want to see. Returns a string.

.INPUTS
    None

.OUTPUTS
    System.Management.Automation.PSCustomObject for individual workflows.
    System.Object[] when run with -All flag.
    
.EXAMPLE
    PS> Get-ISCWorkflow -ID 5xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxd
    
.EXAMPLE
    PS> Get-ISCWorkflow -All

.LINK
    https://github.com/sup3rmark/iscUtils

#>
    [CmdletBinding()]
    param(
        # Check whether there is an active oAuth token. If not, request a new token for the previous connection.
        [Parameter (Mandatory = $false)]
        [Switch] $ReconnectAutomatically,

        [Parameter (
            Mandatory = $true,
            ParameterSetName = 'Enabled',
            HelpMessage = 'Retrieves all workflows from Identity Security Cloud.'
        )]
        [Parameter (
            Mandatory = $false,
            ParameterSetName = 'Disabled',
            HelpMessage = 'Retrieves all workflows from Identity Security Cloud.'
        )]
        [Switch] $All,

        [Parameter (
            Mandatory = $false,
            ParameterSetName = 'Enabled',
            HelpMessage = 'Filters workflows to only return enabled workflows.'
        )]
        [Switch] $Enabled,

        [Parameter (
            Mandatory = $true,
            ParameterSetName = 'Disabled',
            HelpMessage = 'Filters workflows to only return disabled workflows.'
        )]
        [Switch] $Disabled,

        [Parameter (
            Mandatory = $true,
            ParameterSetName = 'Name',
            HelpMessage = 'Enter the ID of a specific workflow to retrieve.'
        )]
        [ValidateNotNullOrEmpty()]
        [String] $ID,

        # Specifies how many items to request per call (max 250).
        [Parameter (Mandatory = $false)]
        [ValidateRange(1, 250)]
        [Int] $Limit = 250,

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

    $url = "$script:iscV3APIurl/v3/workflows"
    if ($ID) {
        $url += "/$ID"
    }

    
    Write-Verbose "Calling $url"
    try {
        $workflowData = Invoke-RestMethod -Uri $url -Method Get -ResponseHeadersVariable responseHeaders @script:bearerAuthArgs
        
        if ($DebugResponse) {
            Write-Host $workflowData
        }

        if ($workflowData.count -eq 0 -and $null -ne $ID) {
            throw "Failed to retrieve any workflows for '$ID'. Please verify ID by using -All instead of specifying a ID."
        }

        
    }
    catch {
        throw $_.Exception
    }
    Write-Verbose "Retrieved $($workflowData.count) records."

    if ($Enabled) {
        $workflowData = $workflowData | Where-Object { $_.enabled }
        Write-Verbose "Filtered to $($workflowData.count) enabled workflows."
    }
    elseif ($Disabled) {
        $workflowData = $workflowData | Where-Object { -not $_.enabled }
        Write-Verbose "Filtered to $($workflowData.count) disabled workflows."
    }

    Write-Verbose 'Finished retrieving workflows.'
    return $workflowData
}