Function Set-ISCTaskCompleted {
    <#
.SYNOPSIS
    Modifies the status of a pending task in ISC.

.DESCRIPTION
    Use this tool to modify the status of a pending task in ISC.

.INPUTS
    System.String
    You can pipe the task ID of the task you would like to update to Set-ISCTaskCompleted.

.OUTPUTS
    System.Management.Automation.PSCustomObject

.EXAMPLE
    PS> Set-ISCTaskCompleted -ID 2xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx4

.LINK
    https://github.com/sup3rmark/iscUtils

#>
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param(
        # Check whether there is an active oAuth token. If not, request a new token for the previous connection.
        [Parameter (Mandatory = $false)]
        [Switch] $ReconnectAutomatically,

        # Enter the ID of the task to modify.
        [Parameter (Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('Completed', 'Error')]
        [String] $Status = 'Completed',

        # Enter the ID of the task to modify.
        [Parameter (Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $ID
    )

    begin {}

    process {
        $changes = @(
            @{
                op    = 'replace'
                path  = '/completionStatus'
                value = $Status
            },
            @{
                op    = 'replace'
                path  = '/completed'
                value = "$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss.fffZ' -AsUTC)"
            }
        )
        
        Try {
            $body = @( $changes )
            Write-Verbose 'JSON:'
            Write-Verbose (ConvertTo-Json $body)
            $url = "$script:iscAPIurl/beta/task-status/$ID"
            Write-Verbose "URL: $url"

            $taskArgs = @{
                Uri    = $url
                Method = 'Patch'
                Body   = (ConvertTo-Json $body)
            }

            $modifiedTask = Invoke-RestMethod @taskArgs @script:bearerAuthArgs -ContentType 'application/json-patch+json'
        }
        Catch {
            throw "ERROR: Failed to update task with $($taskArgs.Body) - $($_.Exception.Message)"
        }

        Return $modifiedTask

    }
}