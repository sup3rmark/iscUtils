function Set-ISCRole {
    <#
.SYNOPSIS
    Modifies an existing role in ISC.

.DESCRIPTION
    Use this tool to modify a role in ISC.

.INPUTS
    System.String
    You can pipe the role ID of the role you would like to update to Set-ISCRole.

.OUTPUTS
    System.Management.Automation.PSCustomObject

.EXAMPLE
    PS> Set-ISCRole -ID 2xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx4 -Description "updated description"

.EXAMPLE
    PS> Set-ISCRole -ID 2xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx4 -OwnerID 3xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd

.EXAMPLE
    PS> Get-ISCRole -Name testRole | Set-ISCRole -Description "description change via pipe"

.EXAMPLE
    PS> Get-ISCRole -Name testRole | Set-ISCRole -OwnerEmID 1234567

.EXAMPLE
    PS> Get-ISCRole -Name testRole | Set-ISCRole -Requestable $true

.EXAMPLE
    PS> Get-ISCRole -Name testRole | Set-ISCRole -Privileged $false

.LINK
    https://github.com/sup3rmark/iscUtils

#>
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param(
        # Check whether there is an active oAuth token. If not, request a new token for the previous connection.
        [Parameter (Mandatory = $false)]
        [Switch] $ReconnectAutomatically,

        # Enter the ID of the role to modify.
        [Parameter (Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $ID,

        # Enter the new display name you want to set on the role.
        [Parameter (Mandatory = $false)]
        [String] $DisplayName,

        # Enter the new description you want to set on the role.
        [Parameter (Mandatory = $false)]
        [String] $Description,

        # Select whether the Role should be enabled.
        [Parameter (Mandatory = $false)]
        [bool] $Enabled,

        # Enter the Email Address of the Role owner.
        [Parameter (Mandatory = $true, ParameterSetName = 'OwnerEmail')]
        [ValidateNotNullOrEmpty()]
        [String] $OwnerEmail,

        # Enter the EmployeeNumber of the Role owner.
        [Parameter (Mandatory = $true, ParameterSetName = 'OwnerEmployeeNumber')]
        [ValidateNotNullOrEmpty()]
        [String] $OwnerEmployeeNumber,

        # Enter the Identity Security Cloud ID of the Role owner.
        [Parameter (Mandatory = $true, ParameterSetName = 'OwnerID')]
        [ValidateNotNullOrEmpty()]
        [String] $OwnerID,

        # Remove the Role owner without setting a new one.
        [Parameter (Mandatory = $true, ParameterSetName = 'RemoveOwner')]
        [ValidateNotNullOrEmpty()]
        [Switch] $RemoveOwner,

        # Select whether the Role should be requestable.
        [Parameter (Mandatory = $false)]
        [bool] $Requestable

    )

    begin {}

    process {
        $spUserParam = @{}
        $spUserParam = $(if ($OwnerEmployeeNumber) {
                @{EmployeeNumber = "$OwnerEmployeeNumber" }
            }
            elseif ($OwnerEmail) {
                @{Email = "$OwnerEmail" }
            }
        )
        
        if ($spUserParam.Count -gt 0) {
            try {
                $OwnerID = Get-ISCIdentity @spUserParam -ErrorAction Stop | Select-Object -ExpandProperty ID
                Write-Verbose 'Successfully retrieved user record from Identity Security Cloud.'
            }
            catch {
                Write-Error 'Failed to retrieve user record for specified owner from Identity Security Cloud.'
                throw $_.Exception
            }
        }

        $existingRole = Get-ISCRole -ID $ID
        $changes = @()
        if ($DisplayName -and ($DisplayName -ne $existingRole.name)) { $changes += @{ op = 'replace'; path = '/name'; value = "$DisplayName" } }
        if ($Description -and ($Description -ne $existingRole.description)) { $changes += @{ op = 'replace'; path = '/description'; value = "$Description" } }
        if ($OwnerID -and ($OwnerID -ne $existingRole.owner.id)) { $changes += @{ op = 'replace'; path = '/owner'; value = @{ id = $OwnerID; type = 'IDENTITY' } } }
        if ($null -ne $Requestable -and ($Requestable -ne $existingRole.requestable)) { $changes += @{ op = 'replace'; path = '/requestable'; value = $Requestable } }
        if ($null -ne $Enabled -and ($Enabled -ne $existingRole.Enabled)) { $changes += @{ op = 'replace'; path = '/enabled'; value = $Enabled } }

        if ($RemoveOwner) { $changes += @{ op = 'remove'; path = '/owner' } }
    
        if ($changes.count -ne 0) {
            try {
                $body = @( $changes )
                Write-Verbose 'JSON:'
                Write-Verbose (ConvertTo-Json $body)
                $setRoleURL = "$script:iscAPIurl/v2025/roles/$ID"
                Write-Verbose "URL: $setRoleURL"

                $setRoleArgs = @{
                    Uri    = $setRoleURL
                    Method = 'Patch'
                    Body   = (ConvertTo-Json $body)   
                }

                $modifiedRole = Invoke-RestMethod @setRoleArgs @script:bearerAuthArgs -ContentType 'application/json-patch+json'
            }
            catch {
                throw "ERROR: Failed to update $($existingRole.name) at $setRoleURL with $($setRoleArgs.Body) - $($_.Exception.Message)"
            }

            return $modifiedRole

        }
        else {
            Write-Host 'No changes needed.'
            return $existingRole
        }
    }
}