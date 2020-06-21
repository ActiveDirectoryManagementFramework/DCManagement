function Set-DCDomainContext
{
	<#
		.SYNOPSIS
			Updates the domain settings for string replacement.
		
		.DESCRIPTION
			Updates the domain settings for string replacement.
		
		.PARAMETER Server
			The server / domain to work with.
		
		.PARAMETER Credential
			The credentials to use for this operation.
		
		.EXAMPLE
			PS C:\> Set-DCDomainContext @parameters

			Updates the current domain context
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding()]
	param (
		[PSFComputer]
		$Server,
		
		[PSCredential]
		$Credential
	)
	
	begin
	{
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
	}
	process
	{
		$domainObject = Get-ADDomain @parameters
		$forestObject = Get-ADForest @parameters
		if ($forestObject.RootDomain -eq $domainObject.DNSRoot)
		{
			$forestRootDomain = $domainObject
			$forestRootSID = $forestRootDomain.DomainSID.Value
		}
		else
		{
			try
			{
				$cred = $PSBoundParameters | ConvertTo-PSFHashtable -Include Credential
				$forestRootDomain = Get-ADDomain @cred -Server $forestObject.RootDomain -ErrorAction Stop
				$forestRootSID = $forestRootDomain.DomainSID.Value
			}
			catch
			{
				$forestRootDomain = [PSCustomObject]@{
					Name = $forestObject.RootDomain.Split(".", 2)[0]
					DNSRoot = $forestObject.RootDomain
					DistinguishedName = 'DC={0}' -f ($forestObject.RootDomain.Split(".") -join ",DC=")
				}
				$forestRootSID = (Get-ADObject @parameters -SearchBase "CN=System,$($domainObject.DistinguishedName)" -SearchScope OneLevel -LDAPFilter "(&(objectClass=trustedDomain)(trustPartner=$($forestObject.RootDomain)))" -Properties securityIdentifier).securityIdentifier.Value
			}
		}
		
		Register-StringMapping -Name '%DomainName%' -Value $domainObject.Name
		Register-StringMapping -Name '%DomainNetBIOSName%' -Value $domainObject.NetbiosName
		Register-StringMapping -Name '%DomainFqdn%' -Value $domainObject.DNSRoot
		Register-StringMapping -Name '%DomainDN%' -Value $domainObject.DistinguishedName
		Register-StringMapping -Name '%DomainSID%' -Value $domainObject.DomainSID.Value
		Register-StringMapping -Name '%RootDomainName%' -Value $forestRootDomain.Name
		Register-StringMapping -Name '%RootDomainFqdn%' -Value $forestRootDomain.DNSRoot
		Register-StringMapping -Name '%RootDomainDN%' -Value $forestRootDomain.DistinguishedName
		Register-StringMapping -Name '%RootDomainSID%' -Value $forestRootSID
		Register-StringMapping -Name '%ForestFqdn%' -Value $forestObject.Name
	}
}