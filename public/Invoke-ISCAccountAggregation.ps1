function Invoke-ISCAccountAggregation {
    <#
.SYNOPSIS
    Aggregate a specific account from Identity Security Cloud.

.DESCRIPTION
    Use this tool to trigger an aggregation for a specific account from Identity Security Cloud by providing the account ID..

.INPUTS
    None

.OUTPUTS
    None
    
.EXAMPLE
    PS> Invoke-ISCAccountAggregation -ID 2cXXXXXXXXXXXXXXXXXXXXXXXXXXXX50

.EXAMPLE
    PS> Invoke-ISCAccountAggregation -Source Workday

.EXAMPLE
    PS> Invoke-ISCAccountAggregation -Source 'Active Directory' -Unoptimized

.LINK
    https://github.com/sup3rmark/iscUtils

#>
    [CmdletBinding()]
    param(
        # Check whether there is an active oAuth token. If not, request a new token for the previous connection.
        [Parameter (Mandatory = $false)]
        [Switch] $ReconnectAutomatically,

        # Specify the account ID of a specific account to aggregate.
        [Alias('ID')]
        [Parameter (Mandatory = $true, ParameterSetName = 'AccountID')]
        [ValidateNotNullOrEmpty()]
        [String] $AccountID,

        # Run this as an unoptimized aggregation.
        [Parameter (Mandatory = $false, ParameterSetName = 'Source')]
        [Switch] $Unoptimized
    )

    # Dynamically generate the list of Sources we can select from
    dynamicparam {
        $sourceAttribute = New-Object System.Management.Automation.ParameterAttribute
        $sourceAttribute.Mandatory = $false
        $sourceAttribute.ParameterSetName = 'Source'

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

        try {
            $spConnection = Test-ISCConnection -ReconnectAutomatically:$ReconnectAutomatically -ErrorAction Stop
            Write-Verbose "Connected to $($spConnection.Tenant) Identity Security Cloud."
        }
        catch {
            throw $_.Exception
        }

        if ($AccountID) {
            $aggArguments = @{ Uri = "$script:iscAPIurl/v2025/accounts/$AccountID/reload" }
        }
        else {
            
            if ($Source) {
                $aggArguments = @{ Uri = "$script:iscAPIurl/v2026/sources/$(($script:ISCSources | Where-Object {$_.Name -eq $Source}).id)/load-accounts" }
            }
            else {
                Write-Error 'No source found.'
            }

            if ($Unoptimized) {
                $aggArguments += @{ form = @{ disableOptimization = $true } }
            }
        }

        Write-Verbose "Calling $($aggArguments.Uri)"

        try {
            $response = Invoke-RestMethod @aggArguments -Method Post @script:bearerAuthArgs -Verbose
            if ($DebugResponse) {
                Write-Host $response
            }
        }
        catch {
            throw $_.Exception
        }

        if ($Source) {
            if ($response.success) {
                Write-Verbose 'Aggregation started successfully:'
                Write-Verbose $response.task.attributes
            }
            else {
                Write-Host $response
                Write-Error 'Aggregation invocation unsuccessful.'
            }
        }
        else {
            Write-Verbose "Aggregation invoked for $AccountID."
        }
    }
}