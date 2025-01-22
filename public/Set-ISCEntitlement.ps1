Function Set-ISCEntitlement {
    <#
.SYNOPSIS
    Modifies an existing entitlement in ISC.

.DESCRIPTION
    Use this tool to modify an entitlement in ISC.

.INPUTS
    System.String
    You can pipe the entitlement ID of the entitlement you would like to update to Set-ISCEntitlement.

.OUTPUTS
    System.Management.Automation.PSCustomObject

.EXAMPLE
    PS> Set-ISCEntitlement -ID 2xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx4 -Description "updated description"

.EXAMPLE
    PS> Set-ISCEntitlement -ID 2xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx4 -OwnerID 3xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd

.EXAMPLE
    PS> Get-ISCEntitlement -Name testEntitlement | Set-ISCEntitlement -Description "description change via pipe"

.EXAMPLE
    PS> Get-ISCEntitlement -Name testEntitlement | Set-ISCEntitlement -OwnerEmID 1234567

.EXAMPLE
    PS> Get-ISCEntitlement -Name testEntitlement | Set-ISCEntitlement -Requestable $true

.EXAMPLE
    PS> Get-ISCEntitlement -Name testEntitlement | Set-ISCEntitlement -Privileged $false

.LINK
    https://github.com/sup3rmark/iscUtils

#>
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param(
        # Check whether there is an active oAuth token. If not, request a new token for the previous connection.
        [Parameter (Mandatory = $false)]
        [Switch] $ReconnectAutomatically,

        # Enter the ID of the entitlement to modify.
        [Parameter (Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $ID,

        # Enter the new display name you want to set on the entitlement.
        [Parameter (Mandatory = $false)]
        [String] $DisplayName,

        # Enter the new description you want to set on the entitlement.
        [Parameter (Mandatory = $false)]
        [String] $Description,

        # Select whether the Entitlement should be marked as privileged.
        [Parameter (Mandatory = $false)]
        [bool] $Privileged,

        # Enter the SamAccountName of the Entitlement owner.
        [Parameter (Mandatory = $true, ParameterSetName = 'OwnerSamAccountName')]
        [ValidateNotNullOrEmpty()]
        [String] $OwnerSamAccountName,

        # Enter the EmployeeNumber of the Entitlement owner.
        [Parameter (Mandatory = $true, ParameterSetName = 'OwnerEmployeeNumber')]
        [ValidateNotNullOrEmpty()]
        [String] $OwnerEmployeeNumber,

        # Enter the Identity Security Cloud ID of the Entitlement owner.
        [Parameter (Mandatory = $true, ParameterSetName = 'OwnerID')]
        [ValidateNotNullOrEmpty()]
        [String] $OwnerID,

        # Remove the Entitlement owner without setting a new one.
        [Parameter (Mandatory = $true, ParameterSetName = 'RemoveOwner')]
        [ValidateNotNullOrEmpty()]
        [Switch] $RemoveOwner,

        # Select whether the Entitlement should be requestable.
        [Parameter (Mandatory = $false)]
        [bool] $Requestable

    )

    begin {}

    process {
        $spUserParam = @{}
        $spUserParam = $(if ($OwnerEmployeeNumber) {
                @{EmployeeNumber = "$OwnerEmployeeNumber" }
            }
            elseif ($OwnerSamAccountName) {
                @{SamAccountName = "$OwnerSamAccountName" }
            })
        
        if ($spUserParam.Count -gt 0) {
            Try {
                $OwnerID = Get-ISCIdentity @spUserParam -ErrorAction Stop | Select-Object -ExpandProperty ID
                Write-Verbose 'Successfully retrieved user record from Identity Security Cloud.'
            }
            Catch {
                Write-Error 'Failed to retrieve user record for specified owner from Identity Security Cloud.'
                throw $_.Exception
            }
        }

        $existingEntitlement = Get-ISCEntitlement -ID $ID
        $changes = @{}
        if ($DisplayName -and ($DisplayName -ne $existingEntitlement.name)) { $changes += @{ op = 'replace'; path = '/name'; value = "$DisplayName" } }
        if ($Description -and ($Description -ne $existingEntitlement.description)) { $changes += @{ op = 'replace'; path = '/description'; value = "$Description" } }
        if ($OwnerID -and ($OwnerID -ne $existingEntitlement.owner.id)) { $changes += @{ op = 'replace'; path = '/owner'; value = @{ id = $OwnerID; type = 'IDENTITY' } } }
        if ($Privileged -and ($Privileged -ne $existingEntitlement.privileged)) { $changes += @{ op = 'replace'; path = '/privileged'; value = $Privileged } }
        if ($Requestable -and ($Requestable -ne $existingEntitlement.requestable)) { $changes += @{ op = 'replace'; path = '/requestable'; value = $Requestable } }

        if ($RemoveOwner) { $changes += @{ op = 'remove'; path = '/owner' } }
    
        if ($changes.count -ne 0) {
            Try {
                $body = @( $changes )
                Write-Verbose 'JSON:'
                Write-Verbose (ConvertTo-Json $body)
                $setEntitlementURL = "$script:iscV3APIurl/beta/entitlements/$ID"
                Write-Verbose "URL: $setEntitlementURL"

                $setEntitlementArgs = @{
                    Uri    = $setEntitlementURL
                    Method = 'Patch'
                    Body   = (ConvertTo-Json $body)
                }

                $modifiedEntitlement = Invoke-RestMethod @setEntitlementArgs @script:bearerAuthArgs
            }
            Catch {
                throw "ERROR: Failed to update $($existingEntitlement.name) at $setEntitlementURL with $($setEntitlementArgs.Body) - $($_.Exception.Message)"
            }

            Return $modifiedEntitlement

        }
        else {
            Write-Host 'No changes needed.'
            Return $existingEntitlement
        }
    }
}