Function Set-ISCAccessProfile {
    <#
.SYNOPSIS
    Modifies an existing access profile in ISC.

.DESCRIPTION
    Use this tool to modify an access profile in ISC.

DYNAMIC PARAMETERS
- Source
    Specifies the source from which you want to pull entitlements. This parameter is required with the -Entitlements parameter.
    Its values are calculated when the connection to Identity Security Cloud is established or renewed based on the existing sources in the Identity Security Cloud org.

.INPUTS
    System.String
    You can pipe the access profile ID of the access profile you would like to update to Set-ISCAccessProfile.

.OUTPUTS
    System.Management.Automation.PSCustomObject

.EXAMPLE
    PS> Set-ISCAccessProfile -ID 2c9180866bd2c84f016be28f55180d04 -Description "updated description"

.EXAMPLE
    PS> Set-ISCAccessProfile -ID 2c9180866bd2c84f016be28f55180d04 -Entitlements 'ISC Users' -Source 'devCorp Employees'

.EXAMPLE
    PS> Get-ISCAccessProfile -Name testProfile | Set-ISCAccessProfile -Description "description change via pipe"

.EXAMPLE
    PS> Get-ISCAccessProfile -Name testProfile | Set-ISCAccessProfile -OwnerEmID 2798

.LINK
    https://github.csnzoo.com/shared/pwsh-iscUtils
#>
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param(
        # Check whether there is an active oAuth token. If not, request a new token for the previous connection.
        [Parameter (Mandatory = $false)]
        [Switch] $ReconnectAutomatically,

        # Enter the ID of the access profile to modify.
        [Parameter (
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [String] $ID,

        # Enter the new name you want to set on the access profile.
        [Parameter (Mandatory = $false, ParameterSetName = 'Name')]
        [String] $Name,

        # Enter the new description you want to set on the access profile.
        [Parameter (Mandatory = $false, ParameterSetName = 'Description')]
        [String] $Description,

        # Select whether the Access Profile should be enabled.
        [Parameter (Mandatory = $false, ParameterSetName = 'Enabled')]
        [Bool] $Enabled,

        # Enter the SamAccountName of the Access Profile owner.
        [Parameter (
            Mandatory = $true,
            ParameterSetName = 'OwnerSamAccountName'
        )]
        [ValidateNotNullOrEmpty()]
        [String] $OwnerSamAccountName,

        # Enter the EmployeeNumber of the Access Profile owner.
        [Parameter (
            Mandatory = $true,
            ParameterSetName = 'OwnerEmployeeNumber'
        )]
        [ValidateNotNullOrEmpty()]
        [String] $OwnerEmployeeNumber,

        # Enter the Identity Security Cloud ID of the Access Profile owner.
        [Parameter (
            Mandatory = $true,
            ParameterSetName = 'OwnerID'
        )]
        [ValidateNotNullOrEmpty()]
        [String] $OwnerID,

        # Select whether the Access Profile should be requestable.
        [Parameter (Mandatory = $false, ParameterSetName = 'Requestable')]
        [Bool] $Requestable

        <# Skipping these for now

        # Enter an array of new entitlements to add to the specified access profile. Appends to the existing list.
        [Parameter (Mandatory = $true, ParameterSetName = 'AddEntitlements')]
        [ValidateNotNullOrEmpty()]
        [String[]] $AddEntitlements,

        # Enter an array of new entitlements to set on the specified access profile. Replaces the existing list.
        [Parameter (Mandatory = $true, ParameterSetName = 'ReplaceEntitlements')]
        [ValidateNotNullOrEmpty()]
        [String[]] $ReplaceEntitlements,

        # Use this flag to remove specific entitlements from an access profile.
        [Parameter (Mandatory = $true, ParameterSetName = 'RemoveEntitlements')]
        [String[]] $RemoveEntitlements

        # Access request configuration for this object
        accessRequestConfig
            commentsRequired
            deniedCommentsRequired
            approvalSchemes
                approverType (APP_OWNER, OWNER, SOURCE_OWNER, MANAGER, GOVERNANCE_GROUP)
                approverId (only used when approverType is GOVERNANCE_GROUP)

        # Revocation request configuration for this object.
        revokeRequestConfig
            commentsRequired
                deniedCommentsRequired
                approvalSchemes
                    approverType (APP_OWNER, OWNER, SOURCE_OWNER, MANAGER, GOVERNANCE_GROUP)
                    approverId (only used when approverType is GOVERNANCE_GROUP)
        
        # List of IDs of segments, if any, to which this Access Profile is assigned.
        segments

        # When an Identity has multiple Accounts on the Source with which an Access Profile is associated, this expression is evaluated against those Accounts to choose one to provision with the Access Profile.
        # provisioningCriteria
        #>

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

        $spUserParam = @{}
        $spUserParam = $(if ($OwnerEmployeeNumber) {
                @{EmID = "$OwnerEmployeeNumber" }
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

        $existingAccessProfile = Get-ISCAccessProfile -ID $ID
        $changes = @{}
        if ($Name -and ($Name -ne $existingAccessProfile.name)) { $changes += @{ path = '/name'; value = "$Name" } }
        if ($Description -and ($Description -ne $existingAccessProfile.description)) { $changes += @{ path = '/description'; value = "$Description" } }
        if ($OwnerID -and ($OwnerID -ne $existingAccessProfile.owner.id)) { $changes += @{ path = '/owner'; value = @{ id = $OwnerID; type = 'IDENTITY' } } }
        if ($Enabled -and ($Enabled -ne $existingAccessProfile.enabled)) { $changes += @{ path = '/enabled'; value = $Enabled } }
        if ($Requestable -and ($Requestable -ne $existingAccessProfile.requestable)) { $changes += @{ path = '/requestable'; value = $Requestable } }
        <# Skipping these for now
        if ($entitlementList) { $changes += @{entitlements = $entitlementList } }
        if ($RemoveEntitlements.isPresent) { $changes += @{entitlements = @() } }
        if ($RequestCommentsRequired) { $changes += @{requestCommentsRequired = $(if ($RequestCommentsRequired) { $true } else { $false }) } }
        if ($DeniedCommentsRequired) { $changes += @{deniedCommentsRequired = $(if ($DeniedCommentsRequired) { $true } else { $false }) } }

        if (($ApprovalSchemes) -and ($ApprovalSchemes -notcontains 'noApproval')) {
            $changes += @{approvalSchemes = "$approvalSchemes" }
        }
        #>
    
        if ($changes.count -ne 0) {
            Try {
                $changes += @{ op = 'replace' }
                $body = @( $changes )
                Write-Verbose 'JSON:'
                Write-Verbose (ConvertTo-Json $body)
                $setAccessProfileURL = "$script:iscV3APIurl/v3/access-profiles/$ID"
                Write-Verbose "URL: $setAccessProfileURL"

                $setAccessProfileArgs = @{
                    Uri    = $setAccessProfileURL
                    Method = 'Patch'
                    Body   = (ConvertTo-Json $body)
                }

                $modifiedAccessProfile = Invoke-RestMethod @setAccessProfileArgs @script:bearerAuthArgs
            }
            Catch {
                throw "ERROR: Failed to update $($existingAccessProfile.name) at $setAccessProfileURL with $($setAccessProfileArgs.Body) - $($_.Exception.Message)"
            }

            Return $modifiedAccessProfile

        }
        else {
            Write-Host 'No changes needed.'
            Return $existingAccessProfile
        }
    }
}