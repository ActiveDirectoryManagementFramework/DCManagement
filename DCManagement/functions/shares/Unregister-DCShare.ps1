function Unregister-DCShare
{
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
