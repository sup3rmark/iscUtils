Function Get-ISCAccessProfile {
    <#
.SYNOPSIS
    Retrieve a specific Access Profile or a list of Access Profiles from Identity Security Cloud.

.DESCRIPTION
    Use this tool to retrieve a specific Access Profile or a list of all existing Access Profiles from Identity Security Cloud.
    Users can pass in an Access Profile name or ID, or request the full list of all Access Profiles.

.INPUTS
    None

.OUTPUTS
    System.Management.Automation.PSCustomObject for individual access profiles.
    System.Object[] when run with -List flag.

.EXAMPLE
    PS> Get-ISCAccessProfile -List

.EXAMPLE
    PS> Get-ISCAccessProfile -Name "foo bar"

.EXAMPLE
    PS> Get-ISCAccessProfile -Name "Foo Bar" -Exact

.EXAMPLE
    PS> Get-ISCAccessProfile -ID "2cXXXXXXXXXXXXXXXXXXXXXXXXXXXX50"

.LINK
    
#>
    [CmdletBinding()]
    param(
        # Check whether there is an active oAuth token. If not, request a new token for the previous connection.
        [Parameter (Mandatory = $false)]
        [Switch] $ReconnectAutomatically,

        # Retrieves a list of all Access Profiles from Identity Security Cloud.
        [Parameter (
            Mandatory = $true,
            ParameterSetName = 'List'
        )]
        [ValidateNotNullOrEmpty()]
        [Switch] $List,

        # Enter the ID of a specific Access Profile to retrieve.
        [Parameter (
            Mandatory = $true,
            ParameterSetName = 'ID'
        )]
        [ValidateNotNullOrEmpty()]
        [String] $ID,

        # Enter the name of a specific Access Profile to retrieve.
        [Parameter (
            Mandatory = $true,
            ParameterSetName = 'Name'
        )]
        [ValidateNotNullOrEmpty()]
        [String] $Name
        
    )

    try {
        $spConnection = Test-ISCConnection -ReconnectAutomatically:$ReconnectAutomatically -ErrorAction Stop
        Write-Verbose "Connected to $($spConnection.Tenant) Identity Security Cloud."
    }
    catch {
        throw $_.Exception
    }

    $filter = if ($ID) {
        "filters=id eq `"$ID`""
    }
    elseif ($Name) {
        "filters=name eq `"$Name`""
    }
    elseif ($List) {
        $null
    }
    else {
        $null
    }
    
    $uri = "$script:iscV3APIurl/v3/access-profiles?$filter"
    $response = Invoke-RestMethod -Uri $uri @script:bearerAuthArgs
    $accessProfileData = $response
    Write-Verbose "Retrieved $($accessProfileData.count) items."
    while ($response.Count -ne 0) {
        try {
            $response = Invoke-RestMethod -Uri "$uri&offset=$($accessProfileData.count)" @script:bearerAuthArgs
            $accessProfileData += $response
            Write-Verbose "Retrieved $($accessProfileData.count) items."
        }
        catch {
            Write-Verbose "Retrieval failed. Will try again. Exception: $($_.Exception.Message)"
        }
    }
    Write-Verbose "SUCCESS: Finished retrieving $($accessProfileData.count) access profile$(if ($($accessProfileData.count) -ne 1) {'s'}) from $($spConnection.Tenant) Identity Security Cloud."

    return $accessProfileData
}