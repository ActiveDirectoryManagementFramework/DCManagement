﻿@{
	# Script module or binary module file associated with this manifest
	RootModule = 'DCManagement.psm1'
	
	# Version number of this module.
	ModuleVersion = '1.2.25'
	
	# ID used to uniquely identify this module
	GUID = '998b2262-9b38-4b54-8ce6-493a00d70b03'
	
	# Author of this module
	Author = 'Friedrich Weinmann'
	
	# Company or vendor of this module
	CompanyName = 'Microsoft'
	
	# Copyright statement for this module
	Copyright = 'Copyright (c) 2019 Friedrich Weinmann'
	
	# Description of the functionality provided by this module
	Description = 'Manage Domain Controller Configurations'
	
	# Minimum version of the Windows PowerShell engine required by this module
	PowerShellVersion = '5.0'
	
	# Modules that must be imported into the global environment prior to importing
	# this module
	RequiredModules = @(
		@{ ModuleName = 'PSFramework'; ModuleVersion = '1.6.198' }
		
		# Additional Dependencies, cannot declare due to bug in dependency handling in PS5.1
		# @{ ModuleName = 'ResolveString'; ModuleVersion = '1.0.0' }
		# @{ ModuleName = 'Principal'; ModuleVersion = '1.0.0' }
		# @{ ModuleName = 'ADMF.Core'; ModuleVersion = '1.0.0' }
	)
	
	# Assemblies that must be loaded prior to importing this module
	RequiredAssemblies = @('bin\DCManagement.dll')
	
	# Type files (.ps1xml) to be loaded when importing this module
	# TypesToProcess = @('xml\DCManagement.Types.ps1xml')
	
	# Format files (.ps1xml) to be loaded when importing this module
	FormatsToProcess = @('xml\DCManagement.Format.ps1xml')
	
	# Functions to export from this module
	FunctionsToExport = @(
		'Clear-DCConfiguration'
		'Get-DCAccessRule'
		'Get-DCShare'
		'Install-DCChildDomain'
		'Install-DCDomainController'
		'Install-DCRootDomain'
		'Invoke-DCAccessRule'
		'Invoke-DCShare'
		'Register-DCAccessRule'
		'Register-DCShare'
		'Set-DCDomainContext'
		'Test-DCAccessRule'
		'Test-DCShare'
		'Unregister-DCAccessRule'
		'Unregister-DCShare'
	)
	
	# Cmdlets to export from this module
	# CmdletsToExport = ''
	
	# Variables to export from this module
	# VariablesToExport = ''
	
	# Aliases to export from this module
	# AliasesToExport = ''
	
	# List of all modules packaged with this module
	# ModuleList = @()
	
	# List of all files packaged with this module
	# FileList = @()
	
	# Private data to pass to the module specified in ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
	PrivateData = @{
		
		#Support for PowerShellGet galleries.
		PSData = @{
			
			# Tags applied to this module. These help with module discovery in online galleries.
			Tags = @('activedirectory','dc','admf')
			
			# A URL to the license for this module.
			LicenseUri = 'https://github.com/ActiveDirectoryManagementFramework/DCManagement/blob/master/LICENSE'
			
			# A URL to the main website for this project.
			ProjectUri = 'https://admf.one'
			
			# A URL to an icon representing this module.
			# IconUri = ''
			
			# ReleaseNotes of this module
			ReleaseNotes = 'https://github.com/ActiveDirectoryManagementFramework/DCManagement/blob/master/DCManagement/changelog.md'
			
		} # End of PSData hashtable
		
	} # End of PrivateData hashtable
}
