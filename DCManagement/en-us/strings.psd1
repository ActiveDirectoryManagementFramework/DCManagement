# This is where the strings go, that are written by
# Write-PSFMessage, Stop-PSFFunction or the PSFramework validation scriptblocks
@{
	'Assert-ADConnection.Failed'			  = 'Failed to connect to {0}' # $Server
	
	'Assert-Configuration.NotConfigured'	  = 'No configuration data provided for: {0}' # $Type
	
	'General.Invalid.Input'				      = 'Invalid input: {1}! This command only accepts output objects from {0}' # 'Test-DCShare', $testItem
	
	'Grant-ShareAccess.Execution.Failed'	  = 'Failed to grant access to {0} on \\{2}\{1} with status {3} : {4}' # $Identity, $Name, $ComputerName, $results.Status, $results.Message
	'Grant-ShareAccess.WinRM.Failed'		  = 'Failed to grant access to {0} on \\{2}\{1}: Remoting access failed' # $Identity, $Name, $ComputerName
	
	'Install-DCChildDomain.Installing'	      = 'Installing a new domain' # 
	'Install-DCChildDomain.Results'		      = 'Finished installation of domain {0}. The result object (including the SafeMode Administrator Password) has been stored in $DomainCreationResult' # $DomainName
	
	'Install-DCDomainController.Installing'   = 'Installing Domaincontroller into domain {0}' # $DomainName
	'Install-DCDomainController.Results'	  = 'Finished installation of DC {0}. The result object (including the SafeMode Administrator Password) has been stored in $DCCreationResult' # $DnsName
	
	'Install-DCRootDomain.Installing'		  = 'Installing a new forest' # 
	'Install-DCRootDomain.Results'		      = 'Finished installation of domain {0}. The result object (including the SafeMode Administrator Password) has been stored in $ForestCreationResult' # $DnsName
	
	'Invoke-DCShare.Access.Error'			  = 'Failed to establish CIM session to {0}' # $testItem.Server
	'Invoke-DCShare.Share.Create'			  = 'Creating share: {0}' # $testItem.Identity
	'Invoke-DCShare.Share.Delete'			  = 'Deleting share: {0}' # $testItem.Identity
	'Invoke-DCShare.Share.Migrate'		      = 'Migrating share to new folder: {0}' # $testItem.Identity
	'Invoke-DCShare.Share.Update'			  = 'Updating share: {0}' # $testItem.Identity
	'Invoke-DCShare.Share.UpdateAccess'	      = 'Updating share permissions on {0}: {1} > {2} ({3})' # $testItem.Identity, $accessEntry.Action, $accessEntry.Identity, $accessEntry.AccessRight
	
	'Revoke-ShareAccess.Execution.Failed'	  = 'Failed to revoke access for {0} on \\{2}\{1} with status {3} : {4}' # $ComputerName, $results.Status, $results.Message
	'Revoke-ShareAccess.WinRM.Failed'		  = 'Failed to revoke access for {0} on \\{2}\{1}: Remoting access failed' # $ComputerName
	
	'Test-DCShare.Access.IntegrityError'	  = 'Unable to resolve all identities for \\{1}\{0} . Skipping delegation check, as permissions integrity cannot be assured.' # $share.Name, $domainController.Name
	'Test-DCShare.CimSession.Failed'		  = 'Failed to establish CIM session to {0}' # $domainController.Name
	'Test-DCShare.Identity.Resolution.Failed' = 'Failed to resolve identity of {0}' # $entry
	'Test-DCShare.Processing'				  = 'Processing shares on {0}' # $domainController.Name
	
	'Validate.Child.DomainName'			      = 'Invalid domain name: {0}. Please enter a valid domain name without special characters and without the full dns tail (as it will be attached to the parent domain name)' # <user input>, <validation item>
	'Validate.ForestRoot.DnsDomainName'	      = 'Invalid DNS domain name: {0}. Please enter a valid DNS name that is not a single label domain name.' # <user input>, <validation item>
	'Validate.Parent.DnsDomainName'		      = 'Invalid DNS domain name: {0}. Please enter a valid DNS name that is not a single label domain name.' # <user input>, <validation item>
}