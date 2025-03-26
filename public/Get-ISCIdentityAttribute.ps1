Function Get-ISCIdentityAttribute {
    <#
.SYNOPSIS
    Retrieve an identity attribute from Identity Security Cloud.

.DESCRIPTION
    Use this tool to retrieve an identity attribute from Identity Security Cloud for a given technical name. Returns an object.

.INPUTS
    None

.OUTPUTS
    System.Management.Automation.PSCustomObject for individual identity attributes.
    System.Object[] when run with -List flag.

.EXAMPLE
    PS> Get-ISCIdentityAttribute -Name displayName

.EXAMPLE
    PS> Get-ISCIdentityAttribute -List

.LINK
    https://github.com/sup3rmark/iscUtils

#>
    [CmdletBinding()]
    param(
        # Check whether there is an active oAuth token. If not, request a new token for the previous connection.
        [Parameter (Mandatory = $false)]
        [Switch] $ReconnectAutomatically,

        # Retrieves a list of all identity attributes from Identity Security Cloud.
        [Parameter (
            Mandatory = $true,
            ParameterSetName = 'List'
        )]
        [Switch] $List,

        # Include 'system' attributes in the response.
        [Parameter (
            Mandatory = $true,
            ParameterSetName = 'List'
        )]
        [Switch] $IncludeSystem,

        # Include 'silent' attributes in the response.
        [Parameter (
            Mandatory = $true,
            ParameterSetName = 'List'
        )]
        [Switch] $IncludeSilent,

        # Include only 'searchable' attributes in the response.
        [Parameter (
            Mandatory = $true,
            ParameterSetName = 'List'
        )]
        [Switch] $SearchableOnly,

        # Enter the name of a specific Identity Attribute to retrieve.
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

    if ($List.IsPresent) {
        Write-Verbose "Retrieving full list of all identity attributes in $($spConnection.Tenant). This may take some time."
        $uri = "$script:iscAPIurl/beta/identity-attributes"
        $params = @()
        if ($IncludeSystem.IsPresent) { $params += 'includeSystem=true' }
        if ($IncludeSilent.IsPresent) { $params += 'includeSilent=true' }
        if ($SearchableOnly.IsPresent) { $params += 'searchableOnly=true' }
        if ($params) { $uri = "$uri?$($params -join '&')" }
    }
    Write-Verbose "Identity Attributes URL: $uri"

    $response = Invoke-RestMethod -Uri "$uri`?count=true" -Method Post -ResponseHeadersVariable responseHeaders -Body ($query | ConvertTo-Json) @script:bearerAuthArgs
    $totalCount = [int]::Parse($responseHeaders.'X-Total-Count')
    $identityAttributeData = $response
    $retrievedCount = $identityAttributeData | Measure-Object | Select-Object -ExpandProperty Count
    Write-Verbose "Retrieved $retrievedCount items out of total $totalCount."
    while ($retrievedCount -lt $totalCount) {
        try {
            $nextQuery = $query + @{searchAfter = @($identityAttributeData[-1].id) }
            $response = Invoke-RestMethod -Uri $uri -Method Post -Body ($nextQuery | ConvertTo-Json) @script:bearerAuthArgs
            $identityAttributeData += $response
            $retrievedCount = $identityAttributeData | Measure-Object | Select-Object -ExpandProperty Count
            Write-Verbose "Retrieved $retrievedCount items out of total $totalCount."
        }
        catch {
            Write-Verbose "Retrieval failed. Will try again. Exception: $($_.Exception.Message)"
        }
    }
    if ($retrievedCount -gt 1) {
        Write-Verbose "SUCCESS: Finished retrieving $retrievedCount identity attributes from $($spConnection.Tenant) Identity Security Cloud."
    }
    elseif ($retrievedCount -eq 1) {
        Write-Verbose 'Retrieved single identity attribute.'
    }
    else {
        Write-Verbose "No identity attributes returned from $($spConnection.Tenant) ISC."
    }

    return $identityAttributeData
}