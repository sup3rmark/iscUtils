Function Get-ISCIdentityAttributeList {
    <#
.SYNOPSIS
    Retrieve a list of Identity Attributes from Identity Security Cloud.

.DESCRIPTION
    Use this tool to retrieve a list of all Identity Attributes from Identity Security Cloud. Returns an object.

.INPUTS
    None

.OUTPUTS
    System.Management.Automation.PSCustomObject
    
.EXAMPLE
    PS> Get-ISCIdentityAttributes

.LINK
    https://github.com/sup3rmark/iscUtils

#>
    [CmdletBinding()]
    param(
        # Check whether there is an active oAuth token. If not, request a new token for the previous connection.
        [Parameter (Mandatory = $false)]
        [Switch] $ReconnectAutomatically
    )

    begin {}

    process {

        Try {
            $spConnection = Test-ISCConnection -ReconnectAutomatically:$ReconnectAutomatically -ErrorAction Stop
            Write-Verbose "Connected to $($spConnection.Tenant) Identity Security Cloud."
        }
        Catch {
            throw $_.Exception
        }

        $url = "$script:iscAPIurl/v2024/identity-attributes"
        
        $script:bearerAuthArgs.headers.authorization
        $response = Invoke-RestMethod -Uri $url -Method Get -ResponseHeadersVariable responseHeaders -Headers @{'X-SailPoint-Experimental' = $true; Authorization = $script:bearerAuthArgs.headers.authorization } -Verbose 

        $requiredIdentityAttributes = @(
            'email'
            'lastname'
            'uid'
        )
        $defaultIdentityAttributes = $response | Where-Object { $_.standard -and $_.name -notin $requiredIdentityAttributes }
        $customIdentityAttributes = $response | Where-Object { -not $_.standard }

        $orderedIdentityAttributes = ($requiredIdentityAttributes + $defaultIdentityAttributes.name + $customIdentityAttributes.name)

        $response = $response | Sort-Object { $orderedIdentityAttributes.IndexOf($_.name) }

        Write-Verbose 'Finished retrieving Identity Attributes.'
        return $response
    }
}