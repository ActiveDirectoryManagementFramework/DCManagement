function Get-DomainController {
	<#
	.SYNOPSIS
		Returns a list of domain controllers with their respective FSMO state.
	
	.DESCRIPTION
		Returns a list of domain controllers with their respective FSMO state.
	
	.PARAMETER Server
		The server / domain to work with.
	
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.EXAMPLE
		PS C:\> Get-DomainController

		List all DCs of the current domain with their respective FSMO membership
	#>
	[CmdletBinding()]
	Param (
		[PSFComputer]
		$Server,

		[pscredential]
		$Credential
	)
	
	begin {
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
	}
	process {
		$forest = Get-ADForest @parameters
		$domain = Get-ADDomain @parameters

		$fsmo = $forest.DomainNamingMaster, $forest.SchemaMaster, $domain.PDCEmulator, $domain.InfrastructureMaster, $domain.RIDMaster

		$domainControllers = Get-ADComputer @parameters -LdapFilter '(primaryGroupID=516)'

		foreach ($controller in $domainControllers) {
			[PSCustomObject]@{
				Name                   = $controller.DNSHostName
				IsFSMO                 = $controller.DNSHostName -in $fsmo
				IsPDCEmulator          = $domain.PDCEmulator -eq $controller.DNSHostName
				IsDomainNamingMaster   = $forest.DomainNamingMaster -eq $controller.DNSHostName
				IsSchemaMaster         = $forest.SchemaMaster -eq $controller.DNSHostName
				IsInfrastructureMaster = $domain.InfrastructureMaster -eq $controller.DNSHostName
				IsRIDMaster            = $domain.RIDMaster -eq $controller.DNSHostName
			}
		}
	}
}