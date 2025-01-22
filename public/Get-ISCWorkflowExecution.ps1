Function Get-ISCWorkflowExecution {
    <#
.SYNOPSIS
    Retrieve a specific workflow from Identity Security Cloud.

.DESCRIPTION
    Use this tool to retrieve a specific workflow from Identity Security Cloud by providing the name of the workflow you want to see. Returns a string.

.INPUTS
    None

.OUTPUTS
    System.Management.Automation.PSCustomObject
    
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
            HelpMessage = 'Enter the ID of a specific workflow execution to retrieve.',
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [ValidateNotNullOrEmpty()]
        [String] $ID,

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

    $url = "$script:iscV3APIurl/v3/workflow-executions/$ID/history"
    
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

    Write-Verbose 'Finished retrieving workflow execution details.'
    return $workflowData
}