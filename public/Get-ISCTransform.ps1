Function Get-ISCTransform {
    <#
.SYNOPSIS
    Retrieve a specific transform from Identity Security Cloud.

.DESCRIPTION
    Use this tool to retrieve a specific transform from Identity Security Cloud by providing the name of the transform you want to see. Returns a string.

.INPUTS
    None

.OUTPUTS
    System.Management.Automation.PSCustomObject for individual transforms.
    System.Object[] when run with -All flag.
    
.EXAMPLE
    PS> Get-ISCTransform -Transform 'oulookup'
    
.EXAMPLE
    PS> Get-ISCTransform -All

.LINK
    https://github.csnzoo.com/shared/pwsh-iscUtils
#>
    [CmdletBinding()]
    param(
        # Check whether there is an active oAuth token. If not, request a new token for the previous connection.
        [Parameter (Mandatory = $false)]
        [Switch] $ReconnectAutomatically,

        [Parameter (
            Mandatory = $true,
            ParameterSetName = 'All',
            HelpMessage = 'Retrieves all transforms from Identity Security Cloud.'
        )]
        [Switch] $All,

        [Parameter (
            Mandatory = $true,
            ParameterSetName = 'Name',
            HelpMessage = 'Enter the name of a specific transform to retrieve.'
        )]
        [ValidateNotNullOrEmpty()]
        [String] $Name,

        # Specifies how many items to request per call (max 250).
        [Parameter (Mandatory = $false)]
        [ValidateRange(1, 250)]
        [Int] $Limit = 250,

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

    $baseURL = "$script:iscV3APIurl/v3/transforms?count=true"
    if ($Name) {
        $baseURL += "&name=$Name"
    }

    $transformData = @()
    do {
        $url = "$baseURL&offset=$($transformData.count)&limit=$Limit"
        Write-Verbose "Calling $url"
        try {
            $response = Invoke-RestMethod -Uri $url -Method Get -ResponseHeadersVariable responseHeaders @script:bearerAuthArgs
            
            if ($DebugResponse) {
                Write-Host $response
            }

            if ($response.count -eq 0 -and $null -ne $Name) {
                throw "Failed to retrieve any transforms for '$Name'. Please verify name by using -All instead of specifying a name."
            }

            $transformData += $response
            Clear-Variable response

            
        }
        catch {
            throw $_.Exception
        }
        Write-Verbose "Retrieved $($transformData.count) of $($responseHeaders.'X-Total-Count') records."
    } while ($transformData.count -ne $($responseHeaders.'X-Total-Count'))

    Write-Verbose 'Finished retrieving transforms.'
    return $transformData
}