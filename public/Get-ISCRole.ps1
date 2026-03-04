function Get-ISCRole {
    <#
.SYNOPSIS
    Retrieve a specific role from Identity Security Cloud.

.DESCRIPTION
    Use this tool to retrieve a specific role from Identity Security Cloud by providing the role ID of the role you want to see. Returns an object.

.INPUTS
    None

.OUTPUTS
    System.Management.Automation.PSCustomObject for individual roles.
    System.Object[] when run with -List flag.
    
.EXAMPLE
    PS> Get-ISCRole -ID 2cXXXXXXXXXXXXXXXXXXXXXXXXXXXX50

.LINK
    https://github.com/sup3rmark/iscUtils

#>
    [CmdletBinding()]
    param(
        # Check whether there is an active oAuth token. If not, request a new token for the previous connection.
        [Parameter (Mandatory = $false)]
        [Switch] $ReconnectAutomatically,

        # Specify one or more role IDs to retrieve
        [Parameter (Mandatory = $false, ParameterSetName = 'RoleID')]
        [ValidateNotNullOrEmpty()]
        [String[]] $ID,

        # Specify one or more role names to retrieve
        [Parameter (Mandatory = $true, ParameterSetName = 'RoleName')]
        [ValidateNotNullOrEmpty()]
        [String[]] $Name,

        # Do a StartsWith search using the provided Name value
        [Parameter (Mandatory = $false, ParameterSetName = 'RoleName')]
        [Switch] $StartsWith,

        # Retrieves a list of all roles from Identity Security Cloud.
        [Parameter (Mandatory = $false, ParameterSetName = 'List')]
        [Switch] $List,

        # Filter to only requestable roles
        [Parameter(Mandatory = $false, ParameterSetName = 'Requestable')]
        [Parameter (Mandatory = $false, ParameterSetName = 'List')]
        [Switch] $Requestable,

        # Filter to only non-requestable roles
        [Parameter (Mandatory = $false, ParameterSetName = 'NotRequestable')]
        [Parameter (Mandatory = $false, ParameterSetName = 'List')]
        [Switch] $NotRequestable,

        # Filter for roles whose owner matches the provided value(s)
        [Parameter (Mandatory = $false, ParameterSetName = 'OwnerID')]
        [ValidateNotNullOrEmpty()]
        [String[]] $OwnerId,

        # Filter for roles created before a specified date
        [Parameter (Mandatory = $false, ParameterSetName = 'CreatedBefore')]
        [ValidateNotNullOrEmpty()]
        [datetime] $CreatedBefore,

        # Filter for roles created after a specified date
        [Parameter (Mandatory = $false, ParameterSetName = 'CreatedAfter')]
        [ValidateNotNullOrEmpty()]
        [datetime] $CreatedAfter,

        # Filter for roles modified before a specified date
        [Parameter (Mandatory = $false, ParameterSetName = 'ModifiedBefore')]
        [ValidateNotNullOrEmpty()]
        [datetime] $ModifiedBefore,

        # Filter for roles modified after a specified date
        [Parameter (Mandatory = $false, ParameterSetName = 'ModifiedAfter')]
        [ValidateNotNullOrEmpty()]
        [datetime] $ModifiedAfter,

        # Specifies how many items to request per call (max 50).
        [Parameter (Mandatory = $false)]
        [ValidateRange(1, 50)]
        [Int] $Limit = 50,

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