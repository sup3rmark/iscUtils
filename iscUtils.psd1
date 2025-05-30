@{

    # Script module or binary module file associated with this manifest.
    RootModule        = 'iscUtils.psm1'

    # Version number of this module.
    ModuleVersion     = '1.0'

    # ID used to uniquely identify this module
    GUID              = '097101ac-69c9-436f-9fd3-bfac15c648f8'

    # Author of this module
    Author            = 'Mark Corsillo'

    # Company or vendor of this module
    CompanyName       = ''

    # Copyright statement for this module
    Copyright         = '(c) 2023-2025 Mark Corsillo. All rights reserved.'

    # Description of the functionality provided by this module
    Description       = 'A module to store functions that call the SailPoint Identity Security Cloud (formerly IdentityNow) API.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '7.2'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules   = @('Microsoft.PowerShell.SecretManagement', 'Microsoft.PowerShell.SecretStore')

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = '*'

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport   = '*'

    # Variables to export from this module
    VariablesToExport = '*'

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport   = '*'

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData       = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('PSEdition_Desktop', 'PSEdition_Core', 'Windows', 'MacOS', 'SailPoint', 'ISC', 'IDN', 'IdentityNow', 'Identity Security Cloud')

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/sup3rmark/iscUtils'

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/sup3rmark/iscUtils?tab=MIT-1-ov-file#readme'

            # ReleaseNotes of this module
            # ReleaseNotes = ''
        } # End of PSData hashtable
    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    HelpInfoURI = 'https://github.com/sup3rmark/iscUtils'
}

