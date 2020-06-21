function Unregister-DCShare
{
<#
	.SYNOPSIS
		Removes a specific share from the list of registered shares.
	
	.DESCRIPTION
		Removes a specific share from the list of registered shares.
	
	.PARAMETER Name
		The exact name of the share to unregister.
	
	.EXAMPLE
		PS C:\> Get-DCShare | Unregister-DCShare
	
		Clears all registered shares.
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$Name
	)
	
	process
	{
		foreach ($nameString in $Name) {
			$script:shares.Remove($nameString)
		}
	}
}
