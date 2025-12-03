#Get all function definition files.
$allFunctions = @(Get-ChildItem -Path $PSScriptRoot -Recurse -Include *.ps1)

#Dot source the files
foreach ($import in $allFunctions) {
    . $import.FullName
}

Export-ModuleMember -Function 'Connect-ISC', 'Get-ISCAccessProfile', 'Get-ISCAccount', 'Get-ISCConnection', 'Get-ISCConnectorRule', 'Get-ISCEntitlement', 'Get-ISCIdentity', 'Get-ISCIdentityAttribute', 'Get-ISCIdentityAttributeList', 'Get-ISCPendingTaskList', 'Get-ISCSource', 'Get-ISCSourceSchema', 'Get-ISCTaskList', 'Get-ISCTransform', 'Get-ISCWorkflow', 'Get-ISCWorkflowExecution', 'Get-ISCWorkflowExecutionList', 'Invoke-ISCAccountAggregation', 'Invoke-ISCQuery', 'New-ISCTenant', 'Remove-ISCTenant', 'Set-ISCAccessProfile', 'Set-ISCEntitlement', 'Set-ISCTaskCompleted', 'Test-ISCConnection' -Alias @()