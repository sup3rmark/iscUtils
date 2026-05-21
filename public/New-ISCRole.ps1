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
        [Parameter (Mandatory = $true, ParameterSetName = 'OwnerEmail')]
        [Parameter (Mandatory = $true, ParameterSetName = 'IdentityList-OwnerEmail')]
        [Parameter (Mandatory = $true, ParameterSetName = 'RoleCriteria-OwnerEmail')]
        [Parameter (Mandatory = $true, ParameterSetName = 'RoleCriteriaJSON-OwnerEmail')]
        [ValidateNotNullOrEmpty()]
        [String] $OwnerEmailAddress,

        # Enter the EmployeeNumber of the Role owner
        [Parameter (Mandatory = $true, ParameterSetName = 'OwnerEmployeeNumber')]
        [Parameter (Mandatory = $true, ParameterSetName = 'IdentityList-OwnerEmployeeNumber')]
        [Parameter (Mandatory = $true, ParameterSetName = 'RoleCriteria-OwnerEmployeeNumber')]
        [Parameter (Mandatory = $true, ParameterSetName = 'RoleCriteriaJSON-OwnerEmployeeNumber')]
        [ValidateNotNullOrEmpty()]
        [String] $OwnerEmployeeNumber,

        # Enter the Identity Security Cloud Identity ID of the Role owner
        [Parameter (Mandatory = $true, ParameterSetName = 'OwnerID')]
        [Parameter (Mandatory = $true, ParameterSetName = 'IdentityList-OwnerID')]
        [Parameter (Mandatory = $true, ParameterSetName = 'RoleCriteria-OwnerID')]
        [Parameter (Mandatory = $true, ParameterSetName = 'RoleCriteriaJSON-OwnerID')]
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
        [Parameter (Mandatory = $true, ParameterSetName = 'IdentityList-OwnerEmail')]
        [Parameter (Mandatory = $true, ParameterSetName = 'IdentityList-OwnerEmployeeNumber')]
        [Parameter (Mandatory = $true, ParameterSetName = 'IdentityList-OwnerID')]
        [ValidateNotNullOrEmpty()]
        [String[]] $IdentityList,

        # Enter the criteria as a PowerShell object for who to add to the Role, see API docs for object structure - https://developer.sailpoint.com/docs/api/v2025/create-role
        [Parameter (Mandatory = $true, ParameterSetName = 'RoleCriteria-OwnerEmail')]
        [Parameter (Mandatory = $true, ParameterSetName = 'RoleCriteria-OwnerEmployeeNumber')]
        [Parameter (Mandatory = $true, ParameterSetName = 'RoleCriteria-OwnerID')]
        [ValidateNotNullOrEmpty()]
        [Object] $RoleCriteriaObject,

        # Enter the criteria as JSON for who to add to the Role, see API docs for object structure - https://developer.sailpoint.com/docs/api/v2025/create-role
        [Parameter (Mandatory = $true, ParameterSetName = 'RoleCriteriaJSON-OwnerEmail')]
        [Parameter (Mandatory = $true, ParameterSetName = 'RoleCriteriaJSON-OwnerEmployeeNumber')]
        [Parameter (Mandatory = $true, ParameterSetName = 'RoleCriteriaJSON-OwnerID')]
        [ValidateNotNullOrEmpty()]
        [Object[]] $RoleCriteriaJSON,

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
        name        = $Name
        description = $Description
        owner       = @{
            id   = $OwnerID
            type = 'IDENTITY'
        }
    }

    if ($AccessProfileIds) {
        $accessProfiles = @()
        foreach ($accessProfileID in $AccessProfileIds) {
            $item = New-Object PSObject
            $item | Add-Member -Type NoteProperty -Name 'id' -Value $accessProfileID
            $item | Add-Member -Type NoteProperty -Name 'type' -Value 'ACCESS_PROFILE'
            $accessProfiles += $item
        }

        $body | Add-Member -Type NoteProperty -Name 'accessProfiles' -Value $accessProfiles

        Write-Verbose 'Access Profiles added to body.'
        Write-Verbose ($body | ConvertTo-Json)
    }
    else {
        Write-Verbose 'No access profile IDs provided.'
    }

    if ($EntitlementIds) {
        $entitlements = @()
        foreach ($entitlementID in $EntitlementIds) {
            $item = New-Object PSObject
            $item | Add-Member -Type NoteProperty -Name 'id' -Value $entitlementID
            $item | Add-Member -Type NoteProperty -Name 'type' -Value 'ENTITLEMENT'
            $entitlements += $item
        }

        $body | Add-Member -Type NoteProperty -Name 'entitlements' -Value $entitlements
        Write-Verbose 'Entitlements added to body.'
        Write-Verbose ($body | ConvertTo-Json)
    }
    else {
        Write-Verbose 'No entitlement IDs provided.'
    }

    if ($RoleCriteriaObject) {
        $membership = @{
            type     = 'STANDARD'
            criteria = $RoleCriteriaObject
        }

        Write-Verbose 'Role Criteria specified via Object.'
        Write-Verbose ($membership | ConvertTo-Json -Depth 25)
    }
    elseif ($RoleCriteriaJSON) {
        $membership = @{
            type     = 'STANDARD'
            criteria = ($RoleCriteriaJSON | ConvertFrom-Json)
        }

        Write-Verbose 'Role Criteria specified via JSON.'
    }
    elseif ($IdentityList) {
        foreach ($identity in $IdentityList) {
            $item = New-Object PSObject
            $item | Add-Member -Type NoteProperty -Name 'id' -Value $identity
            $item | Add-Member -Type NoteProperty -Name 'type' -Value 'IDENTITY'
            $memberList += $item
        }
        $membership = @{
            type       = 'IDENTITY_LIST'
            identities = $memberList
        }

        Write-Verbose 'Identity List specified.'
    }

    if ($membership) {
        $body | Add-Member -Type NoteProperty -Name 'membership' -Value $membership
    }

    $baseURL = "$script:iscAPIurl/v2025/roles"

    try {
        Write-Verbose 'JSON:'
        Write-Verbose ($body | ConvertTo-Json -Depth 25)

        $newRoleArgs = @{
            Uri    = $baseURL
            Method = 'Post'
            Body   = ($body | ConvertTo-Json -Depth 25)
        }

        $roleResponse = Invoke-RestMethod @newRoleArgs @script:bearerAuthArgs
    }
    catch {
        throw "ERROR: Failed to create role at $baseURL - $($_.Exception.Message)"
    }

    Write-Verbose 'Successfully created role.'
    return $roleResponse
}