Function Get-ISCSourceSchema {
    <#
.SYNOPSIS
    Retrieve a specific source schema from Identity Security Cloud.

.DESCRIPTION
    Use this tool to retrieve a specific source's schema from Identity Security Cloud by providing the name of the source and which type of schema you want to see. Only able to find sources created before your current session. Returns an object.

.INPUTS
    None

.OUTPUTS
    System.Management.Automation.PSCustomObject
    
.EXAMPLE
    PS> Get-ISCSourceSchema -Source 'Foo' -SchemaName account

.EXAMPLE
    PS> Get-ISCSourceSchema -Source 'Bar' -SchemaName group

.EXAMPLE
    PS> Get-ISCSourceSchema -Source 'Bas' -SchemaId 166xxxxxxxxxxxxxxxxxxxxxxxxxx1af

.LINK
    https://github.com/sup3rmark/iscUtils

#>
    [CmdletBinding()]
    param(
        # Check whether there is an active oAuth token. If not, request a new token for the previous connection.
        [Parameter (Mandatory = $false)]
        [Switch] $ReconnectAutomatically,

        # Specifies the name of the schema to request.
        [Parameter (Mandatory = $true, ParameterSetName = 'SchemaName')]
        [ValidateNotNullOrEmpty()]
        [String] $SchemaName,

        # Specifies the ID of the schema to request.
        [Parameter (Mandatory = $true, ParameterSetName = 'SchemaId')]
        [ValidateNotNullOrEmpty()]
        [String] $SchemaId,

        # Retrieves a list of all schemas for the specified Source from Identity Security Cloud.
        [Parameter (Mandatory = $true, ParameterSetName = 'List')]
        [Switch] $List,

        # Specifies whether to output the API response directly to the console for debugging.
        [Parameter (Mandatory = $false)]
        [Switch] $DebugResponse
    )

    # Dynamically generate the list of Sources we can select from
    DynamicParam {
        $sourceAttribute = New-Object System.Management.Automation.ParameterAttribute
        $sourceAttribute.Mandatory = $true

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

        if (-not $Source) {
            throw 'No Source provided. Please try again with a Source specified.'
        }

        Try {
            $spConnection = Test-ISCConnection -ReconnectAutomatically:$ReconnectAutomatically -ErrorAction Stop
            Write-Verbose "Connected to $($spConnection.Tenant) Identity Security Cloud."
        }
        Catch {
            throw $_.Exception
        }

        $baseURL = "$script:iscAPIurl/v3/sources/$(($script:ISCSources | Where-Object {$_.Name -eq $Source}).id)/schemas"

        $schamasData = @()
        do {
            if ($SchemaName) {
                Write-Verbose "Retrieving schema with name $SchemaName."
                $url = "$baseURL`?include-names=$SchemaName"
            }
            elseif ($SchemaId) {
                Write-Verbose "Retrieving schema with ID $SchemaId."
                $url = "$baseURL`/$SchemaId"
            }
            elseif ($List) {
                Write-Verbose 'Retrieving list of all schemas.'
                $url = $baseURL
            }
            Write-Verbose "Calling $url"
            try {
                $response = Invoke-RestMethod -Uri $url -Method Get -ResponseHeadersVariable responseHeaders @script:bearerAuthArgs
                if ($DebugResponse) {
                    Write-Host $response
                }
                $schamasData += $response
                Clear-Variable response
            }
            catch {
                throw $_.Exception
            }
            Write-Verbose "Retrieved $($schamasData.count) of $($responseHeaders.'X-Total-Count') records."
        } while ($schamasData.count -ne $($responseHeaders.'X-Total-Count') -and $($responseHeaders.'X-Total-Count') -gt 1)

        Write-Verbose 'Finished retrieving schemas.'
        return $schamasData
    }
}