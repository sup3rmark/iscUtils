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

.LINK
    https://github.com/sup3rmark/iscUtils

#>
    [CmdletBinding()]
    param(
        # Check whether there is an active oAuth token. If not, request a new token for the previous connection.
        [Parameter (Mandatory = $false)]
        [Switch] $ReconnectAutomatically,

        # Specify the account ID of a specific account to aggregate.
        [Parameter (Mandatory = $true, ParameterSetName = 'AccountID')]
        [ValidateNotNullOrEmpty()]
        [String] $ID
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

        $url = "$script:iscAPIurl/v2025/accounts/$ID/reload"

        Write-Verbose "Calling $url"
        try {
            $response = Invoke-RestMethod -Uri $url -Method Post -ResponseHeadersVariable responseHeaders @script:bearerAuthArgs
            if ($DebugResponse) {
                Write-Host $response
            }
        }
        catch {
            throw $_.Exception
        }

        Write-Verbose "Finished aggregating account $ID."
    }
}