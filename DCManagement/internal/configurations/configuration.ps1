<#
This is an example configuration file

By default, it is enough to have a single one of them,
however if you have enough configuration settings to justify having multiple copies of it,
feel totally free to split them into multiple files.
#>

<#
# Example Configuration
Set-PSFConfig -Module 'DCManagement' -Name 'Example.Setting' -Value 10 -Initialize -Validation 'integer' -Handler { } -Description "Example configuration setting. Your module can then use the setting using 'Get-PSFConfigValue'"
#>

Set-PSFConfig -Module 'DCManagement' -Name 'Import.DoDotSource' -Value $false -Initialize -Validation 'bool' -Description "Whether the module files should be dotsourced on import. By default, the files of this module are read as string value and invoked, which is faster but worse on debugging."
Set-PSFConfig -Module 'DCManagement' -Name 'Import.IndividualFiles' -Value $false -Initialize -Validation 'bool' -Description "Whether the module files should be imported individually. During the module build, all module code is compiled into few files, which are imported instead by default. Loading the compiled versions is faster, using the individual files is easier for debugging and testing out adjustments."

Set-PSFConfig -Module 'DCManagement' -Name 'Defaults.NoDNS' -Value $false -Validation bool -Initialize -Description 'Default value for "NoDNS" parameter when creating a new forest'
Set-PSFConfig -Module 'DCManagement' -Name 'Defaults.NoReboot' -Value $false -Validation bool -Initialize -Description 'Default value for "NoReboot" parameter when creating a new forest'
Set-PSFConfig -Module 'DCManagement' -Name 'Defaults.LogPath' -Value 'C:\Windows\NTDS' -Validation string -Initialize -Description 'Default value for "LogPath" parameter when creating a new forest'
Set-PSFConfig -Module 'DCManagement' -Name 'Defaults.SysvolPath' -Value 'C:\Windows\SYSVOL' -Validation string -Initialize -Description 'Default value for "SysvolPath" parameter when creating a new forest'
Set-PSFConfig -Module 'DCManagement' -Name 'Defaults.DatabasePath' -Value 'C:\Windows\NTDS' -Validation string -Initialize -Description 'Default value for "DatabasePath" parameter when creating a new forest'