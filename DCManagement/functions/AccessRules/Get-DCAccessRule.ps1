function Get-DCAccessRule
{
<#
	.SYNOPSIS
		Returns the list of registered filesystem access rules.
	
	.DESCRIPTION
		Returns the list of registered filesystem access rules.
	
	.PARAMETER Path
		Filter by the path it is assigned to.
		Defaults to: '*'
	
	.PARAMETER Identity
		Filter by the Identity granted permissions to.
		Default to: '*'
	
	.EXAMPLE
		PS C:\> Get-DCAccessRule
	
		Returns the list of all registered filesystem access rules.
#>
	[CmdletBinding()]
	Param (
		[string]
		$Path = '*',
		
		[string]
		$Identity = '*'
	)
	
	process
	{
		($script:fileSystemAccessRules.Values.Values | Where-Object Path -Like $Path | Where-Object Identity -Like $Identity)
	}
}
