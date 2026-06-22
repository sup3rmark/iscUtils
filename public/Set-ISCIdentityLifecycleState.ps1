function Set-ISCIdentityLifecycleState {
    <#
.SYNOPSIS
    Modifies an identity's lifecycle state in ISC.

.DESCRIPTION
    Use this tool to modify an identity's lifecycle state in ISC.

.INPUTS
    System.String
    You can pipe the identity ID of the identity you would like to update to Set-ISCIdentityLifecycleState.

.OUTPUTS
    System.Management.Automation.PSCustomObject

.EXAMPLE
    PS> Set-ISCIdentityLifecycleState -ID 2xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx4 -LifecycleState Active

.LINK
    https://github.com/sup3rmark/iscUtils

#>
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param(
        # Check whether there is an active oAuth token. If not, request a new token for the previous connection.
        [Parameter (Mandatory = $false)]
        [Switch] $ReconnectAutomatically,

        # Enter the ID of the identity to modify.
        [Parameter (Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $ID,

        # Enter the name of the lifecycle state you want to set the identity to.
        [Alias('LCS')]
        [Parameter (Mandatory = $false)]
        [String] $LifecycleState
    )

    begin {}

    process {
        # Retrieve specified identity
        try {
            $identity = Get-ISCIdentity -ID $ID
            if ($identity) {
                Write-Verbose 'Identity retrieved'
            }
            else {
                Write-Error 'No Identity found.'
            }
        }
        catch {
            throw "ERROR: Failed to retrieve identity for ID $ID - $($_.Exception.Message)"
        }

        # Retrieve all Lifecycle States for specified identity's Identity Profile
        try {
            $lcstates = Invoke-RestMethod -Uri "$script:iscAPIurl/v2026/identity-profiles/$($identity.identityProfile.id)/lifecycle-states" @script:bearerAuthArgs
            if ($lcstates) {
                Write-Verbose 'Lifecycle States retrieved'
            }
            else {
                Write-Error 'No Lifecycle States found.'
            }
        }
        catch {
            throw "ERROR: Failed to retrieve lifecycle states for $($identity.identityProfile.name) identity profile (ID: $($identity.identityProfile.id)) - $($_.Exception.Message)"
        }

        
        try {
            $targetLCS = $lcstates | Where-Object { $_.name -eq $LifecycleState }
            if ($targetLCS) {
                $body = @{ lifecycleStateId = $targetLCS.id }
                Write-Verbose 'JSON:'
                Write-Verbose (ConvertTo-Json $body)
                $setLCSURL = "$script:iscAPIurl/v2026/identities/$id/set-lifecycle-state"
                Write-Verbose "URL: $setLCSURL"

                $setLCSArgs = @{
                    Uri    = $setLCSURL
                    Method = 'Post'
                    Body   = (ConvertTo-Json $body)
                }

                Invoke-RestMethod @setLCSArgs @script:bearerAuthArgs
            }
            else {
                Write-Error "No Lifecycle State found with name '$LifecycleState' for identity ID $id."
            }
        }
        catch {
            throw "ERROR: Failed to set LCS to $LifecycleState for identity ID $id - $($_.Exception.Message)"
        }
    }
}