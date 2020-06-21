function Clear-DCConfiguration
{
<#
	.SYNOPSIS
		Resets all DC specific configuration settings.
	
	.DESCRIPTION
		Resets all DC specific configuration settings.
	
	.EXAMPLE
		PS C:\> Clear-DCConfiguration
	
		Resets all DC specific configuration settings.
#>
	[CmdletBinding()]
	Param (
	
	)
	
	process
	{
		. "$script:ModuleRoot\internal\scripts\variables.ps1"
	}
}