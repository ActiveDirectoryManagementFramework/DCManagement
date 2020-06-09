function Get-DCShare
{
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
