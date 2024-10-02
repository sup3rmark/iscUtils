Function Get-ISCAccount {
    <#
.SYNOPSIS
    Retrieve a specific account from Identity Security Cloud.

.DESCRIPTION
    Use this tool to retrieve a specific account from Identity Security Cloud by providing the account ID of the account you want to see. Returns an object.

.INPUTS
    None

.OUTPUTS
    System.Management.Automation.PSCustomObject for individual transforms.
    
.EXAMPLE
    PS> Get-ISCAccount -ID 2cXXXXXXXXXXXXXXXXXXXXXXXXXXXX50

.LINK
    https://github.com/sup3rmark/iscUtils

#>
    [CmdletBinding()]
    param(
        # Check whether there is an active oAuth token. If not, request a new token for the previous connection.
        [Parameter (Mandatory = $false)]
        [Switch] $ReconnectAutomatically,

        # Specify the account ID of a specific account to retrieve.
        [Parameter (Mandatory = $true, ParameterSetName = 'AccountID')]
        [ValidateNotNullOrEmpty()]
        [String] $ID,

        # Specify an identity ID to retrieve all of its correlated accounts.
        [Parameter (Mandatory = $true, ParameterSetName = 'IdentityID')]
        [ValidateNotNullOrEmpty()]
        [String] $IdentityID,

        # Retrieves a list of all accounts from Identity Security Cloud.
        [Parameter (Mandatory = $true, ParameterSetName = 'List')]
        [Switch] $List,

        # Specifies how many items to request per call (max 250).
        [Parameter (Mandatory = $false)]
        [ValidateRange(1, 250)]
        [Int] $Limit = 250,

        # Specifies whether to only retrieve uncorrelated accounts.
        [Parameter (Mandatory = $false, ParameterSetName = 'List')]
        [Switch] $Uncorrelated,

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

        $filters = @()
        if ($ID) {
            $filters += "id eq `"$ID`""
        }
        if ($IdentityID) {
            $filters += "identityId eq `"$IdentityID`""
        }
        if ($List) {
            # No filter needed if we're looking for _all_ accounts
        }
        if ($Uncorrelated) {
            $filters += 'uncorrelated eq true'
        }
        if ($Source) {
            $filters += "sourceId eq `"$(($script:ISCSources | Where-Object {$_.Name -eq $Source}).id)`""
        }

        $baseURL = "$script:iscV3APIurl/v3/accounts?count=true"
        if ($filters) {
            $baseURL += "&filters=$($filters -join ' and ')"
        }

        $accountsData = @()
        do {
            $url = "$baseURL&offset=$($accountsData.count)&limit=$Limit"
            Write-Verbose "Calling $url"
            try {
                $response = Invoke-RestMethod -Uri $url -Method Get -ResponseHeadersVariable responseHeaders @script:bearerAuthArgs
                if ($DebugResponse) {
                    Write-Host $response
                }
                $accountsData += $response
                Clear-Variable response
            }
            catch {
                throw $_.Exception
            }
            Write-Verbose "Retrieved $($accountsData.count) of $($responseHeaders.'X-Total-Count') records."
        } while ($accountsData.count -ne $($responseHeaders.'X-Total-Count'))

        Write-Verbose 'Finished retrieving accounts.'
        return $accountsData
    }
}