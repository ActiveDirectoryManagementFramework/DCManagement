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
		PS C:\> Resolve-ParameterValue -InputObject $InputObject -FullName 'value2'
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
		if ($null -ne $InputObject -and '' -ne $InputObject)
		{
			return $InputObject
		}
		Get-PSFConfigValue -FullName $FullName
	}
}