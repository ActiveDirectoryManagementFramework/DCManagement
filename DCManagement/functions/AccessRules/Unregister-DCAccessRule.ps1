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
	
	.PARAMETER ServerMode
		The processing mode the rule was assigned to.
	
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
		$ServerMode
	)
	
	process
	{
		if (-not $script:fileSystemAccessRules[$Path]) { return }
		
		$script:fileSystemAccessRules[$Path].Remove("$($Identity)þ$($ServerRole)")
		
		if (-not $script:fileSystemAccessRules[$Path]) { $script:fileSystemAccessRules.Remove($Path) }
	}
}
