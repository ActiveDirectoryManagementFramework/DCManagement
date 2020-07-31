function Resolve-ParameterValue
{
<#
	.SYNOPSIS
		Resolves parameter values, defaulting to configured values.
	
	.DESCRIPTION
		Resolves parameter values, defaulting to configured values.
	
	.PARAMETER InputObject
		The object passed by the user.
	
	.PARAMETER FullName
		The name of the configuration.
	
	.EXAMPLE
		PS C:\> Resolve-ParameterValue -FullName 'DCManagement.Defaults.NoDNS' -InputObject $NoDNS
		
		Resolves the configuration for NoDNS:
		- If it was specified by the user, use $NoDNS variable value
		- If it was not, use the 'DCManagement.Defaults.NoDNS' configuration setting
#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[AllowNull()]
		[PSObject]
		$InputObject,
		
		[Parameter(Mandatory = $true)]
		[string]
		$FullName
	)
	
	process
	{
		if ($null -ne $InputObject -and '' -ne $InputObject -and $InputObject -isnot [switch])
		{
			return $InputObject
		}
		if ($InputObject -is [switch] -and $InputObject.IsPresent) { return $InputObject }
		Get-PSFConfigValue -FullName $FullName
	}
}