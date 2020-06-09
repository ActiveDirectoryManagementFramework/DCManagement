function Register-DCShare {
	<#
	.SYNOPSIS
		Registers an SMB share that should exist on DCs.
	
	.DESCRIPTION
		Registers an SMB share that should exist on DCs.
	
	.PARAMETER Name
		The name of the share.
		Supports string resolution.
	
	.PARAMETER Path
		The path the share points to.
		Supports string resolution.
	
	.PARAMETER FullAccess
		The principals to grant full access to.
	
	.PARAMETER WriteAccess
		The principals to grant write access to.
	
	.PARAMETER ReadAccess
		The principals to grant read access to.
	
	.PARAMETER AccessMode
		How share access rules are processed.
		Supports three configurations:
		- Constrained: The default access mode, will remove any excess access rules.
		- Additive: Ignore any access rules already on the share, even if not configured
		- Defined: Ignore any access rules already on the share, even if not configured UNLESS the identity on those rules has an access level defined for it.
	
	.PARAMETER ServerRole
		What domain controller to apply this to:
		- All:  All DCs in the enterprise
		- FSMO: Only DCs that have any FSMO role
		- PDC:  Only the PDCEmulator
	
	.EXAMPLE
		PS C:\> Get-Content .\shares.json | ConvertFrom-Json | Write-Output | Register-DCShare

		Reads all share definitions from json and imports the definitions.
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Name,

		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Path,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[AllowEmptyCollection()]
		[string[]]
		$FullAccess,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[AllowEmptyCollection()]
		[string[]]
		$WriteAccess,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[AllowEmptyCollection()]
		[string[]]
		$ReadAccess,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[ValidateSet('Constrained', 'Additive', 'Defined')]
		[string]
		$AccessMode = 'Constrained',

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[ValidateSet('All', 'FSMO', 'PDC')]
		[string]
		$ServerRole = 'All'
	)
	
	process {
		$script:shares[$Name] = [PSCustomObject]@{
			PSTypeName  = 'DCManagement.Share'	
			Name        = $Name
			Path        = $Path
			FullAccess  = $FullAccess
			WriteAccess = $WriteAccess
			ReadAccess  = $ReadAccess
			AccessMode  = $AccessMode
			ServerRole  = $ServerRole
		}
	}
}
