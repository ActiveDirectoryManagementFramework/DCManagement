function Unregister-DCAccessRule
{
<#
	.SYNOPSIS
		Removes an access rule from the list of registered access rules.
	
	.DESCRIPTION
		Removes an access rule from the list of registered access rules.
	
	.PARAMETER Path
		The path to the filesystem resource being managed.
	
	.PARAMETER Identity
		The identity (user, group, etc.) whose permissions ar being removed from the list of intended permissions.
	
	.PARAMETER ServerRole
		The processing mode the rule was assigned to.
	
	.PARAMETER Rights
		The rights assigned.
	
	.PARAMETER Type
		Allow or Deny rule?
	
	.PARAMETER Inheritance
		Who gets to inherit?
	
	.PARAMETER Propagation
		How does it propagate?
	
	.EXAMPLE
		PS C:\> Get-DCaccessRule | Unregister-DCAccessRule
		
		Clears all configured access rules.
#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Path,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Identity,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$ServerRole,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Rights,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Type,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Inheritance,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Propagation
	)
	
	process
	{
		if (-not $script:fileSystemAccessRules[$Path]) { return }
		
		$script:fileSystemAccessRules[$Path].Remove("$($Identity)þ$($ServerRole)þ$($Rights)þ$($Type)þ$($Inheritance)þ$($Propagation)")
		
		if (-not $script:fileSystemAccessRules[$Path]) { $script:fileSystemAccessRules.Remove($Path) }
	}
}
