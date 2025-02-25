Function Get-ISCSource {
    <#
.SYNOPSIS
    Retrieve a specific source from Identity Security Cloud.

.DESCRIPTION
    Use this tool to retrieve a specific source's configuration from Identity Security Cloud by providing the name of the source you want to see. Only able to find sources created before your current session. Returns an object.

.INPUTS
    None

.OUTPUTS
    System.Management.Automation.PSCustomObject for individual sources.
    System.Object[] when run with -List flag.
    
.EXAMPLE
    PS> Get-ISCSource -Source 'Active Directory'

.LINK
    https://github.com/sup3rmark/iscUtils

#>
    [CmdletBinding()]
    param(
        # Check whether there is an active oAuth token. If not, request a new token for the previous connection.
        [Parameter (Mandatory = $false)]
        [Switch] $ReconnectAutomatically,

        # Retrieves a list of all sources from Identity Security Cloud.
        [Parameter (Mandatory = $false)]
        [Switch] $List,

        # Specifies how many items to request per call (max 250).
        [Parameter (Mandatory = $false)]
        [ValidateRange(1, 250)]
        [Int] $Limit = 250,

        # Specifies whether to output the API response directly to the console for debugging.
        [Parameter (Mandatory = $false)]
        [Switch] $DebugResponse
    )

    # Dynamically generate the list of Sources we can select from
    DynamicParam {
        $sourceAttribute = New-Object System.Management.Automation.ParameterAttribute
        $sourceAttribute.Mandatory = $false

        $attributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $attributeCollection.Add($sourceAttribute)

        $validateSet = New-Object System.Management.Automation.ValidateSetAttribute($script:ISCSources.name)
        $attributeCollection.Add($validateSet)

        $sourceParam = New-Object System.Management.Automation.RuntimeDefinedParameter('Source', [String], $attributeCollection)
        
        $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $paramDictionary.Add('Source', $sourceParam)
        return $paramDictionary
    }

    begin {}

    process {
        # A dynamic parameter does not automatically assign a variable to a bound parameter so we're forced to be more explicit.
        if ($PSBoundParameters.Source) { $Source = $PSBoundParameters.Source }

        Try {
            $spConnection = Test-ISCConnection -ReconnectAutomatically:$ReconnectAutomatically -ErrorAction Stop
            Write-Verbose "Connected to $($spConnection.Tenant) Identity Security Cloud."
        }
        Catch {
            throw $_.Exception
        }

        $baseURL = "$script:iscAPIurl/v3/sources"

        $sourcesData = @()
        do {
            if ($Source) {
                $url = "$baseURL/$(($script:ISCSources | Where-Object {$_.Name -eq $Source}).id)"
            }
            else {
                $url = "$baseURL`?count=true&offset=$($sourcesData.count)&limit=$Limit"
            }
            Write-Verbose "Calling $url"
            try {
                $response = Invoke-RestMethod -Uri $url -Method Get -ResponseHeadersVariable responseHeaders @script:bearerAuthArgs
                if ($DebugResponse) {
                    Write-Host $response
                }
                $sourcesData += $response
                Clear-Variable response
            }
            catch {
                throw $_.Exception
            }
            Write-Verbose "Retrieved $($sourcesData.count) of $($responseHeaders.'X-Total-Count') records."
        } while ($sourcesData.count -ne $($responseHeaders.'X-Total-Count') -and $($responseHeaders.'X-Total-Count') -gt 1)

        Write-Verbose 'Finished retrieving sources.'
        return $sourcesData
    }
}