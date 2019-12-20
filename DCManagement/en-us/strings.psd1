# This is where the strings go, that are written by
# Write-PSFMessage, Stop-PSFFunction or the PSFramework validation scriptblocks
@{
	'Install-DCChildDomain.Installing' = 'Installing a new domain'
	'Install-DCChildDomain.Results' = 'Finished installation of domain {0}. The result object (including the SafeMode Administrator Password) has been stored in $DomainCreationResult'

	'Install-DCRootDomain.Installing' = 'Installing a new forest'
	'Install-DCRootDomain.Results' = 'Finished installation of domain {0}. The result object (including the SafeMode Administrator Password) has been stored in $ForestCreationResult'

	'Validate.ForestRoot.DnsDomainName' = 'Invalid DNS domain name: {0}. Please enter a valid DNS name that is not a single label domain name.'
	'Validate.Child.DomainName' = 'Invalid domain name: {0}. Please enter a valid domain name without special characters and without the full dns tail (as it will be attached to the parent domain name)'
	'Validate.Parent.DnsDomainName' = 'Invalid DNS domain name: {0}. Please enter a valid DNS name that is not a single label domain name.'
}