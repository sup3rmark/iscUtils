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

    $filters = @()

    if ($ID) {
        $filters += $(if ($ID.Count -gt 1) { "id in (`"$($ID -join '","')`")" } else { "id eq `"$ID`"" })
    }

    if ($Name -and $StartsWith) {
        if ($Name.Count -gt 1) {
            throw 'StartsWith can only be used with a single Name value.'
        }
        $filters += "name sw `"$Name`""
    }
    elseif ($Name) {
        $filters += $(if ($Name.Count -gt 1) { "name in (`"$($Name -join '","')`")" } else { "name eq `"$Name`"" })
    }

    if ($Requestable) {
        $filters += 'requestable eq true'
    }
    elseif ($NotRequestable) {
        $filters += 'requestable eq false'
    }

    if ($OwnerId) {
        $filters += $(if ($OwnerId.Count -gt 1) { "owner.id in (`"$($OwnerId -join '","')`")" } else { "owner.id eq `"$OwnerId`"" })
    }

    if ($CreatedBefore) {
        $filters += "created le `"$($CreatedBefore.ToString('yyyy-MM-ddTHH:mm:ssZ'))`""
    }

    if ($CreatedAfter) {
        $filters += "created ge `"$($CreatedAfter.ToString('yyyy-MM-ddTHH:mm:ssZ'))`""
    }

    if ($ModifiedBefore) {
        $filters += "modified le `"$($ModifiedBefore.ToString('yyyy-MM-ddTHH:mm:ssZ'))`""
    }

    if ($ModifiedAfter) {
        $filters += "modified ge `"$($ModifiedAfter.ToString('yyyy-MM-ddTHH:mm:ssZ'))`""
    }

    $baseURL = "$script:iscAPIurl/v2025/roles?count=true"
    if ($filters) {
        $baseURL += "&filters=$($filters -join ' and ')"
    }

    $roleData = @()
    do {
        $url = "$baseURL&offset=$($roleData.count)&limit=$Limit"
        Write-Verbose "Calling $url"
        try {
            $response = Invoke-RestMethod -Uri $url -Method Get -ResponseHeadersVariable responseHeaders @script:bearerAuthArgs -MaximumRetryCount 2
            if ($DebugResponse) {
                Write-Host $response
            }
            $roleData += $response
            Clear-Variable response
        }
        catch {
            throw $_.Exception
        }
        Write-Verbose "Retrieved $($roleData.count) of $($responseHeaders.'X-Total-Count') records."
    } while ($roleData.count -ne $($responseHeaders.'X-Total-Count'))

    Write-Verbose 'Finished retrieving roles.'
    return $roleData
}