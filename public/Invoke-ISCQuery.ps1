function Invoke-ISCQuery {
    <#
.SYNOPSIS
    Run a specified query against Identity Security Cloud.

.DESCRIPTION
    Use this tool to run a specified query against Identity Security Cloud. Returns an object.

.INPUTS
    None

.OUTPUTS
    System.Management.Automation.PSCustomObject
    
.EXAMPLE
    PS> Invoke-ISCQuery

.LINK
    https://github.com/sup3rmark/iscUtils

#>
    [CmdletBinding()]
    param(
        # Check whether there is an active oAuth token. If not, request a new token for the previous connection.
        [Parameter (Mandatory = $false)]
        [Switch] $ReconnectAutomatically,

        # Specify the query to run.
        [Parameter (Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $Query,
    
        # Specify the index or indices to query.
        [Parameter (Mandatory = $false)]
        [Alias ('Indices')]
        [ValidateSet('AccessProfiles', 'AccountActivities', 'Entitlements', 'Events', 'Identities', 'Roles', '*')]
        [String[]] $Index
    )

    begin {}

    process {
        try {
            $spConnection = Test-ISCConnection -ReconnectAutomatically:$ReconnectAutomatically -ErrorAction Stop
            Write-Verbose "Connected to $($spConnection.Tenant) Identity Security Cloud."
        }
        catch {
            throw $_.Exception
        }

        $body = @{
            indices       = @($Index.ToLower())
            query         = @{
                query = $Query
            }
            includeNested = $false
            sort          = @('id')
        }
        $baseURL = "$script:iscAPIurl/v3/search"
        Write-Verbose "Calling $baseURL"
        Write-Verbose ($body | ConvertTo-Json)

        $resultsData = @()
        $responseData = @()
        do {
            if ($resultsData.count -gt 0) {
                $queryBody = $body + @{ searchAfter = @( $resultsData[-1].id ) }
                $url = "$baseURL"
            }
            else {
                $queryBody = $body
                $url = "$baseURL`?count=true"
            }
            try {
                $responseData = Invoke-RestMethod -Uri $url -Method Post -Body ($queryBody | ConvertTo-Json) -ResponseHeadersVariable responseHeaders @script:bearerAuthArgs
                $resultsData += $responseData
            }
            catch {
                throw $_.Exception
            }
            if ($responseHeaders.'X-Total-Count') { $totalCount = $responseHeaders.'X-Total-Count'[0] }
            Write-Verbose "Retrieved $($resultsData.count) of $totalCount records."
        } while ($resultsData.count -lt $totalCount -or $responseData.count -gt 0)

        Write-Verbose 'Finished retrieving search results.'
        if ($resultsData.count -ne $totalCount) {
            throw "Returned $($resultsData.count) results. Expected $totalCount results. Please try again."
        }
        return $resultsData
    }
}