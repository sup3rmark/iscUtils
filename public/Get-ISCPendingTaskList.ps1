Function Get-ISCPendingTaskList {
    <#
.SYNOPSIS
    Retrieve a list of pending tasks from Identity Security Cloud.

.DESCRIPTION
    Use this tool to retrieve all pending tasks from Identity Security Cloud. Returns an object.

.INPUTS
    None

.OUTPUTS
    System.Management.Automation.PSCustomObject
    
.EXAMPLE
    PS> Get-ISCPendingTaskList

.LINK
    https://github.com/sup3rmark/iscUtils

#>
    [CmdletBinding()]
    param(
        # Check whether there is an active oAuth token. If not, request a new token for the previous connection.
        [Parameter (Mandatory = $false)]
        [Switch] $ReconnectAutomatically,

        # Specifies how many items to request per call (max 250).
        [Parameter (Mandatory = $false)]
        [ValidateRange(1, 250)]
        [Int] $Limit = 250,

        # Specifies whether to output the API response directly to the console for debugging.
        [Parameter (Mandatory = $false)]
        [Switch] $DebugResponse
    )

    begin {}

    process {
        Try {
            $spConnection = Test-ISCConnection -ReconnectAutomatically:$ReconnectAutomatically -ErrorAction Stop
            Write-Verbose "Connected to $($spConnection.Tenant) Identity Security Cloud."
        }
        Catch {
            throw $_.Exception
        }

        $baseURL = "$script:iscV3APIurl/beta/task-status/pending-tasks?limit=$Limit"

        $tasksData = @()
        do {
            $url = "$baseURL&offset=$($tasksData.count)"
            Write-Verbose "Calling $url"
            try {
                $response = Invoke-RestMethod -Uri $url -Method Get -ResponseHeadersVariable responseHeaders @script:bearerAuthArgs
                if ($DebugResponse) {
                    Write-Host $response
                }
                $tasksData += $response
            }
            catch {
                throw $_.Exception
            }
            Write-Verbose "Retrieved $($tasksData.count) records."
        } while ($response.count -gt 0)

        Write-Verbose 'Finished retrieving tasks.'
        return $tasksData
    }
}