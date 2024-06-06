#Get public and private function definition files.
$publicFunctions = @(Get-ChildItem -Path "$PSScriptRoot\Public" -Recurse -Include *.ps1 -ErrorAction SilentlyContinue)
$privateFunctions = @(Get-ChildItem -Path "$PSScriptRoot\Private" -Recurse -Include *.ps1 -ErrorAction SilentlyContinue)

#Dot source the files
foreach ($import in @($publicFunctions + $privateFunctions)) {
    . $import.FullName
}

#region Set Global Module Variables

#endregion

Export-ModuleMember -Function $publicFunctions.BaseName -Alias @()