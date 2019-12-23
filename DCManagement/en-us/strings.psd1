# This is where the strings go, that are written by
# Write-PSFMessage, Stop-PSFFunction or the PSFramework validation scriptblocks
@{
	'Install-DCChildDomain.Installing'	    = 'Installing a new domain' # 
	'Install-DCChildDomain.Results'		    = 'Finished installation of domain {0}. The result object (including the SafeMode Administrator Password) has been stored in $DomainCreationResult' # $DomainName
	
	'Install-DCDomainController.Installing' = 'Installing Domaincontroller into domain {0}' # 
	'Install-DCDomainController.Results'    = 'Finished installation of DC {0}. The result object (including the SafeMode Administrator Password) has been stored in $DCCreationResult' # $DnsName
	
	'Install-DCRootDomain.Installing'	    = 'Installing a new forest' # 
	'Install-DCRootDomain.Results'		    = 'Finished installation of domain {0}. The result object (including the SafeMode Administrator Password) has been stored in $ForestCreationResult' # $DnsName
	
	'Validate.Child.DomainName'			    = 'Invalid domain name: {0}. Please enter a valid domain name without special characters and without the full dns tail (as it will be attached to the parent domain name)' # <user input>, <validation item>
	'Validate.ForestRoot.DnsDomainName'	    = 'Invalid DNS domain name: {0}. Please enter a valid DNS name that is not a single label domain name.' # <user input>, <validation item>
	'Validate.Parent.DnsDomainName'		    = 'Invalid DNS domain name: {0}. Please enter a valid DNS name that is not a single label domain name.' # <user input>, <validation item>
}