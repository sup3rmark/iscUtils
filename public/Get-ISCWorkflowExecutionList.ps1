Function Get-ISCWorkflowExecutionList {
    <#
.SYNOPSIS
    Retrieve a list of executions from Identity Security Cloud for a specified workflow.

.DESCRIPTION
    Use this tool to retrieve a list of workflow executions from Identity Security Cloud by providing the ID of the workflow you want to see. Returns a string.

.INPUTS
    None

.OUTPUTS
    System.Object[]
    
.EXAMPLE
    PS> Get-ISCWorkflowExecutionList -ID 5xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxd

.LINK
#>
    [CmdletBinding()]
    param(
        # Check whether there is an active oAuth token. If not, request a new token for the previous connection.
        [Parameter (Mandatory = $false)]
        [Switch] $ReconnectAutomatically,

        [Parameter (
            Mandatory = $true,
            HelpMessage = 'Enter the ID of a specific workflow to retrieve.',
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [ValidateNotNullOrEmpty()]
        [String] $ID,

        [Parameter (
            Mandatory = $false,
            HelpMessage = 'Filter to executions that started after this datetime. Must be earlier than StartedBefore, if provided.'
        )]
        [ValidateNotNullOrEmpty()]
        [DateTime] $StartedAfter,

        [Parameter (
            Mandatory = $false,
            HelpMessage = 'Filter to executions that started prior to this datetime. Must be later than StartedAfter, if provided.'
        )]
        [ValidateNotNullOrEmpty()]
        [DateTime] $StartedBefore,

        [Parameter (
            Mandatory = $false,
            HelpMessage = 'Filter to executions in the provided state.'
        )]
        [ValidateSet('Completed', 'Failed', 'Executing', 'Canceled')]
        [String] $Status,

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

    if ($StartedAfter -and $StartedBefore -and $StartedAfter -gt $StartedBefore) {
        throw 'StartedAfter datetime must be earlier than StartedBefore datetime.' 
    }

    $params = @("limit=$Limit")
    $filters = @()
    if ($Status) { $filters += "status eq `"$Status`"" }
    if ($StartedAfter) { $filters += "startTime ge `"$StartedAfter`"" }
    if ($StartedBefore) { $filters += "startTime le `"$StartedBefore`"" }
    if ($filters) {
        $params += "filters=$($filters -join ' and ')"
    }
    $baseURL = "$script:iscV3APIurl/v3/workflows/$ID/executions?$($params -join '&')"

    $executionsData = @()
    do {
        $url = "$baseURL&offset=$($executionsData.count)"
        Write-Verbose "Calling $url"
        if ($response) { Clear-Variable response }
        try {
            $response = Invoke-RestMethod -Uri $url -Method Get -ResponseHeadersVariable responseHeaders @script:bearerAuthArgs
            
            if ($DebugResponse) {
                Write-Host $response
            }

            if ($response.count -eq 0 -and $null -ne $Name) {
                throw "Failed to retrieve any executions for '$ID'. Please verify ID."
            }

            $executionsData += $response
        }
        catch {
            throw $_.Exception
        }
        Write-Verbose "Retrieved $($executionsData.count) records."
    } while ($response.count -eq $Limit)

    Write-Verbose 'Finished retrieving workflow executions.'
    return ($executionsData | Select-Object id, workflowId, requestId, startTime, closeTime, @{name = 'elapsed'; expression = { ([datetime]$_.closeTime - [datetime]$_.startTime).ToString() } }, status)
}