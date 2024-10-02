Function Get-ISCEntitlement {
    <#
.SYNOPSIS
    Retrieve a specific entitlement from Identity Security Cloud.

.DESCRIPTION
    Use this tool to retrieve a specific entitlement from Identity Security Cloud by providing the entitlement ID of the entitlement you want to see. Returns an object.

.INPUTS
    None

.OUTPUTS
    System.Management.Automation.PSCustomObject for individual entitlements.
    
.EXAMPLE
    PS> Get-ISCEntitlement -ID 2cXXXXXXXXXXXXXXXXXXXXXXXXXXXX50

.LINK
    https://github.com/sup3rmark/iscUtils

#>
    [CmdletBinding()]
    param(
        # Check whether there is an active oAuth token. If not, request a new token for the previous connection.
        [Parameter (Mandatory = $false)]
        [Switch] $ReconnectAutomatically,

        # Specify one or more entitlement IDs to retrieve
        [Parameter (Mandatory = $false, ParameterSetName = 'EntitlementID')]
        [ValidateNotNullOrEmpty()]
        [String[]] $ID,

        # Specify an account to retrieve all of its assigned entitlements
        [Parameter (Mandatory = $false, ParameterSetName = 'AccountID')]
        [ValidateNotNullOrEmpty()]
        [String] $AccountID,

        # Specify one or more entitlement names to retrieve
        [Parameter (Mandatory = $true, ParameterSetName = 'EntitlementName')]
        [ValidateNotNullOrEmpty()]
        [String[]] $Name,

        # Do a StartsWith search using the provided Name value
        [Parameter (Mandatory = $false, ParameterSetName = 'EntitlementName')]
        [Switch] $StartsWith,

        # Retrieves a list of all entitlements from Identity Security Cloud.
        [Parameter (Mandatory = $false, ParameterSetName = 'List')]
        [Switch] $List,

        # Specify one or more types of entitlements to retrieve
        [Parameter (Mandatory = $false, ParameterSetName = 'Type')]
        [ValidateNotNullOrEmpty()]
        [String[]] $Type,

        # Filter to only requestable entitlements
        [Parameter (Mandatory = $false, ParameterSetName = 'Requestable')]
        [Switch] $Requestable,

        # Filter to only non-requestable entitlements
        [Parameter (Mandatory = $false, ParameterSetName = 'NotRequestable')]
        [Switch] $NotRequestable,

        # Filter for entitlements whose owner matches the provided value(s)
        [Parameter (Mandatory = $false, ParameterSetName = 'OwnerID')]
        [ValidateNotNullOrEmpty()]
        [String[]] $OwnerId,

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

        $query = @()
        if ($AccountID) {
            $query += "account-id=$AccountID"
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

        if ($Type) {
            $filters += $(if ($Type.Count -gt 1) { "type in (`"$($Type -join '","')`")" } else { "type eq `"$Type`"" })
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

        if ($Source) {
            $filters += "source.id eq `"$(($script:ISCSources | Where-Object {$_.Name -eq $Source}).id)`""
        }

        $baseURL = "$script:iscV3APIurl/beta/entitlements?count=true"
        if ($filters) {
            $query += "&filters=$($filters -join ' and ')"
        }
        if ($query) {
            $baseURL += "&$query"
        }

        $entitlementsData = @()
        do {
            $url = "$baseURL&offset=$($entitlementsData.count)&limit=$Limit"
            Write-Verbose "Calling $url"
            try {
                $response = Invoke-RestMethod -Uri $url -Method Get -ResponseHeadersVariable responseHeaders @script:bearerAuthArgs -MaximumRetryCount 2
                if ($DebugResponse) {
                    Write-Host $response
                }
                $entitlementsData += $response
                Clear-Variable response
            }
            catch {
                throw $_.Exception
            }
            Write-Verbose "Retrieved $($entitlementsData.count) of $($responseHeaders.'X-Total-Count') records."
        } while ($entitlementsData.count -ne $($responseHeaders.'X-Total-Count'))

        Write-Verbose 'Finished retrieving entitlements.'
        return $entitlementsData
    }
}