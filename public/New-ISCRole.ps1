function New-ISCRole {
    <#
.SYNOPSIS
    Create a new role in Identity Security Cloud.

.DESCRIPTION
    Use this tool to create a new role in Identity Security Cloud. Roles will be created in a disabled state by default and will need to be manually enabled in the UI. Returns an object.

.INPUTS
    None

.OUTPUTS
    System.Management.Automation.PSCustomObject for individual roles.
    System.Object[] when run with -List flag.
    
.EXAMPLE
    PS> New-ISCRole -Name "My New Role"

.LINK
    https://github.com/sup3rmark/iscUtils

#>
    [CmdletBinding()]
    param(
        # Check whether there is an active oAuth token. If not, request a new token for the previous connection.
        [Parameter (Mandatory = $false)]
        [Switch] $ReconnectAutomatically,

        # Specify a name for the new role
        [Parameter (Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $Name,
        
        # Specify a description for the new role
        [Parameter (Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $Description,

        # Enter the Email Address of the Role owner
        [Parameter (Mandatory = $true, ParameterSetName = 'OwnerEmailAddress')]
        [ValidateNotNullOrEmpty()]
        [String] $OwnerEmailAddress,

        # Enter the EmployeeNumber of the Role owner
        [Parameter (Mandatory = $true, ParameterSetName = 'OwnerEmployeeNumber')]
        [ValidateNotNullOrEmpty()]
        [String] $OwnerEmployeeNumber,

        # Enter the Identity Security Cloud Identity ID of the Role owner
        [Parameter (Mandatory = $true, ParameterSetName = 'OwnerID')]
        [ValidateNotNullOrEmpty()]
        [String] $OwnerID,

        # Enter an array of Access Profile IDs to add to the Role
        [Parameter (Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String[]] $AccessProfileIds,

        # Enter an array of Entitlement IDs to add to the Role
        [Parameter (Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String[]] $EntitlementIds,

        # Enter a list of Identity IDs to add to the Role
        [Parameter (Mandatory = $true, ParameterSetName = 'IdentityList')]
        [ValidateNotNullOrEmpty()]
        [String[]] $IdentityList,

        # Enter the criteria for who to add to the Role, see API docs for object structure - https://developer.sailpoint.com/docs/api/v2025/create-role
        [Parameter (Mandatory = $true, ParameterSetName = 'RoleCriteria')]
        [ValidateNotNullOrEmpty()]
        [Object[]] $RoleCriteria,

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

    # Retrieve OwnerID if email or employee number provided
    $spUserParam = @{}
    $spUserParam = $(if ($OwnerEmployeeNumber) {
            @{EmployeeNumber = "$OwnerEmployeeNumber" }
        }
        elseif ($OwnerEmailAddress) {
            @{Email = "$OwnerEmailAddress" }
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

    $body = @{
        name             = $Name
        description      = $Description
        ownerId          = @{
            id   = $OwnerID
            type = 'IDENTITY'
            name = 'Identity'
        }
        accessProfileIds = $AccessProfileIds
        entitlementIds   = $EntitlementIds
        identityList     = $IdentityList
        roleCriteria     = $RoleCriteria
    }

    if ($AccessProfileIds) {
        $accessProfiles = @()
        $accessProfiles += foreach ($accessProfileID in $AccessProfileIds) {
            @{
                id   = $accessProfileID
                type = 'ACCESS_PROFILE'
                name = 'Access Profile'
            }
        }

        $body += $accessProfiles
    }

    if ($EntitlementIds) {
        $entitlements = @()
        $entitlements += foreach ($entitlementID in $EntitlementIds) {
            @{
                id   = $entitlementID
                type = 'ENTITLEMENT'
                name = 'Entitlement'
            }
        }

        $body += $entitlements
    }

    $baseURL = "$script:iscAPIurl/v2025/roles"

    try {
        Write-Verbose 'JSON:'
        Write-Verbose (ConvertTo-Json $body)

        $newRoleArgs = @{
            Uri    = $baseURL
            Method = 'Post'
            Body   = (ConvertTo-Json $body)
        }

        $roleResponse = Invoke-RestMethod @newRoleArgs @script:bearerAuthArgs
    }
    catch {
        throw "ERROR: Failed to create role at $baseURL - $($_.Exception.Message)"
    }

    Write-Verbose 'Successfully created role.'
    return $roleResponse
}