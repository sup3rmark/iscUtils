Function Get-ISCIdentity {
    <#
.SYNOPSIS
    Retrieve a specific user from Identity Security Cloud.

.DESCRIPTION
    Use this tool to retrieve a specific user from Identity Security Cloud by providing the SamAccountName, EmployeeNumber, or Identity Security Cloud ID of the user you want to see. Returns an object.

.INPUTS
    None

.OUTPUTS
    System.Management.Automation.PSCustomObject for individual identities.
    System.Object[] when run with -List flag.

.EXAMPLE
    PS> Get-ISCIdentity -SamAccountName mc12345

.EXAMPLE
    PS> Get-ISCIdentity -EmployeeNumber 12345

.EXAMPLE
    PS> Get-ISCIdentity -ID 2cXXXXXXXXXXXXXXXXXXXXXXXXXXXX50

.EXAMPLE
    PS> Get-ISCIdentity -List

.EXAMPLE
    PS> Get-ISCIdentity -List -Active

.LINK
    
#>
    [CmdletBinding()]
    param(
        # Check whether there is an active oAuth token. If not, request a new token for the previous connection.
        [Parameter (Mandatory = $false)]
        [Switch] $ReconnectAutomatically,

        # Retrieves a list of all identities from Identity Security Cloud.
        [Parameter (
            Mandatory = $true,
            ParameterSetName = 'List'
        )]
        [Switch] $List,

        # Enter the Identity Security Cloud ID of a specific identity to retrieve.
        [Parameter (
            Mandatory = $true,
            ParameterSetName = 'ID'
        )]
        [ValidateNotNullOrEmpty()]
        [String] $ID,

        # Enter the SamAccountName of a specific identity to retrieve.
        [Parameter (
            Mandatory = $true,
            ParameterSetName = 'SamAccountName'
        )]
        [ValidateNotNullOrEmpty()]
        [String] $SamAccountName,

        # Enter the EmployeeNumber of a specific identity to retrieve.
        [Parameter (
            Mandatory = $true,
            ParameterSetName = 'EmployeeNumber'
        )]
        [ValidateNotNullOrEmpty()]
        [String] $EmployeeNumber,

        # Enter a custom query.
        [Parameter (
            Mandatory = $true,
            ParameterSetName = 'CustomQuery'
        )]
        [ValidateNotNullOrEmpty()]
        [String] $CustomQuery,

        # Specify whether to retrieve only active identities.
        [Parameter ()]
        [ValidateNotNullOrEmpty()]
        [Switch] $Active,

        # Includes nested objects from returned search results, such as accounts, access, etc. This runs much more slowly, but returns more detailed results.
        [Parameter (Mandatory = $false)]
        [Switch] $IncludeNested

    )

    try {
        $spConnection = Test-ISCConnection -ReconnectAutomatically:$ReconnectAutomatically -ErrorAction Stop
        Write-Verbose "Connected to $($spConnection.Tenant) Identity Security Cloud."
    }
    catch {
        throw $_.Exception
    }

    $subQuery = switch ($PSBoundParameters.Keys) {
        'Active' {
            'attributes.cloudLifecycleState:active'
            break
        }
        'EmployeeNumber' {
            "employeeNumber:$EmployeeNumber"
            break
        }
        'SamAccountName' {
            "attributes.samaccountname:$SamAccountName"
            break
        }
        'ID' {
            "id:$ID"
            break
        }
        'CustomQuery' {
            "$CustomQuery"
            break
        }
        'List' {
            '*'
            break
        }
    }

    if ($List.IsPresent) {
        Write-Verbose "Querying full list of all identities in $($spConnection.Tenant). This may take some time."
    }

    $query = @{
        indices = @('identities')
        query   = @{ query = $($subQuery -join (' AND ')) }
        sort    = @('id')
    }

    # IncludeNested defaults to true, so we have to specify it as false if the flag was not raised.
    # Since this results in a major difference in runtime, we default to false.
    if (-not $IncludeNested) {
        $query += @{ includeNested = $false }
    }
    Write-Verbose "Query:`n$($query | ConvertTo-Json)"

    $uri = "$script:iscV3APIurl/v3/search"
    Write-Verbose "Query URL: $uri"

    $response = Invoke-RestMethod -Uri "$uri`?count=true" -Method Post -ResponseHeadersVariable responseHeaders -Body ($query | ConvertTo-Json) @script:bearerAuthArgs
    $totalCount = [int]::Parse($responseHeaders.'X-Total-Count')
    $identitiesData = $response
    $retrievedCount = $identitiesData | Measure-Object | Select-Object -ExpandProperty Count
    Write-Verbose "Retrieved $retrievedCount items out of total $totalCount."
    while ($retrievedCount -lt $totalCount) {
        try {
            $nextQuery = $query + @{searchAfter = @($identitiesData[-1].id) }
            $response = Invoke-RestMethod -Uri $uri -Method Post -Body ($nextQuery | ConvertTo-Json) @script:bearerAuthArgs
            $identitiesData += $response
            $retrievedCount = $identitiesData | Measure-Object | Select-Object -ExpandProperty Count
            Write-Verbose "Retrieved $retrievedCount items out of total $totalCount."
        }
        catch {
            Write-Verbose "Retrieval failed. Will try again. Exception: $($_.Exception.Message)"
        }
    }
    if ($retrievedCount -gt 1) {
        Write-Verbose "SUCCESS: Finished retrieving $retrievedCount identities from $($spConnection.Tenant) Identity Security Cloud."
    }
    elseif ($retrievedCount -eq 1) {
        Write-Verbose "Retrieved single identity ($($identitiesData.id))."
    }
    else {
        Write-Verbose "No identities returned from $($spConnection.Tenant) ISC."
    }

    return $identitiesData
}