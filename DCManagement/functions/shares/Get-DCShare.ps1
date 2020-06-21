function Get-DCShare
{
<#
	.SYNOPSIS
		Returns the list of registered shares.
	
	.DESCRIPTION
		Returns the list of registered shares.
	
	.PARAMETER Name
		Filter the returned share definitions by name.
		Defaults to '*'
	
	.EXAMPLE
		PS C:\> Get-DCShare
	
		Returns the list of registered shares.
#>
	[CmdletBinding()]
	Param (
		[string]
		$Name = '*'
	)
	
	process
	{
		$script:shares.Values | Where-Object Name -like $Name
	}
}
