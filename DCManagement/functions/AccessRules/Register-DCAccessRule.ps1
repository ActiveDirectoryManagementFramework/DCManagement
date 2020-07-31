function Register-DCAccessRule
{
<#
	.SYNOPSIS
		Registers an access rule for FileSystem paths on a domain controller.
	
	.DESCRIPTION
		Registers an access rule for FileSystem paths on a domain controller.
	
	.PARAMETER Path
		The path to the filesystem object to grant permissions on.
		Supports string resolution.
	
	.PARAMETER Identity
		What identity / principal to grant access.
		Supports string resolution.
	
	.PARAMETER Rights
		What file system right to grant.
	
	.PARAMETER Type
		Whether this is an allow or a deny rule.
		Defaults to Allow.
	
	.PARAMETER Inheritance
		Who and how are access rules inherited.
		Defaults to 'ContainerInherit, ObjectInherit', meaning everything beneath the path inherits as well.
	
	.PARAMETER Propagation
		How access rules are being propagated.
		Defaults to "None", the windows default behavior.
	
	.PARAMETER Empty
		This path should have no explicit ACE defined.
	
	.PARAMETER AccessMode
		How filesystem access rules are processed.
		Supports three configurations:
		- Constrained: The default access mode, will remove any excess access rules.
		- Additive: Ignore any access rules already on the path, even if not configured
		- Defined: Ignore any access rules already on the path, even if not configured UNLESS the identity on those rules has an access level defined for it.
	
	.PARAMETER ServerRole
		What domain controller to apply this to:
		- All:  All DCs in the enterprise
		- FSMO: Only DCs that have any FSMO role
		- PDC:  Only the PDCEmulator
	
	.PARAMETER ContextName
		The name of the context defining the setting.
		This allows determining the configuration set that provided this setting.
		Used by the ADMF, available to any other configuration management solution.
	
	.EXAMPLE
		PS C:\> Get-Content .\accessrules.json | ConvertFrom-Json | Write-Output | Register-DCAccessRule
		
		Reads all access rule definitions from json and imports the definitions.
#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Path,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ACE')]
		[string]
		$Identity,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ACE')]
		[System.Security.AccessControl.FileSystemRights]
		$Rights,
		
		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ACE')]
		[System.Security.AccessControl.AccessControlType]
		$Type = 'Allow',
		
		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ACE')]
		[System.Security.AccessControl.InheritanceFlags]
		$Inheritance = 'ContainerInherit, ObjectInherit',
		
		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ACE')]
		[System.Security.AccessControl.PropagationFlags]
		$Propagation = 'None',
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Empty')]
		[bool]
		$Empty,
		
		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ACE')]
		[ValidateSet('Constrained', 'Additive', 'Defined')]
		[string]
		$AccessMode = 'Constrained',
		
		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[ValidateSet('All', 'FSMO', 'PDC')]
		[string]
		$ServerRole = 'All',
		
		[string]
		$ContextName = '<Undefined>'
	)
	
	process
	{
		if (-not $script:fileSystemAccessRules[$Path]) { $script:fileSystemAccessRules[$Path] = @{ } }
		
		$script:fileSystemAccessRules[$Path]["$($Identity)þ$($ServerRole)þ$($Rights)þ$($Type)þ$($Inheritance)þ$($Propagation)"] = [pscustomobject]@{
			PSTypeName  = 'DCManagement.AccessRule'
			Path	    = $Path
			Identity    = $Identity
			Rights	    = $Rights
			Type	    = $Type
			Inheritance = $Inheritance
			Propagation = $Propagation
			AccessMode  = $AccessMode
			ServerRole  = $ServerRole
			Empty	    = $Empty
		}
	}
}
