function Grant-ShareAccess
{
<#
	.SYNOPSIS
		Grants access to a network share.
	
	.DESCRIPTION
		Grants access to a network share.
		User must be specified as a SID.
		This command uses PowerShell remoting to access the target computer.
	
	.PARAMETER ComputerName
		The name of the server to operate against.
	
	.PARAMETER Credential
		The credentials to use for authentication.
	
	.PARAMETER Name
		The name of the share to modifiy.
	
	.PARAMETER Identity
		The SID of the user to grant permissions to.
	
	.PARAMETER AccessRight
		The rights of the user that has permissions granted.
	
	.EXAMPLE
		PS C:\> Grant-ShareAccess @parameters -Name Legal -Identity S-1-5-21-584015949-955715703-1113067636-1105 -AccessRight Full
	
		Grants the specified user full access right to the share "Legal"
#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWMICmdlet", "")]
	[CmdletBinding()]
	param (
		[PSFComputer]
		$ComputerName,
		
		[PSCredential]
		$Credential,
		
		[string]
		$Name,
		
		[string]
		$Identity,
		
		[ValidateSet('Full', 'Change', 'Read')]
		[string]
		$AccessRight
	)
	
	begin
	{
		#region Permission Grant Scriptblock
		$scriptblock = {
			param (
				[Hashtable]
				$Data
			)
			
			function Write-Result
			{
				[CmdletBinding()]
				param (
					[switch]
					$Failed,
					
					[string]
					$State,
					
					[string]
					$Message
				)
				
				[pscustomobject]@{
					Success = (-not $Failed)
					State   = $State
					Message = $Message
				}
			}
			
			
			$accessHash = @{
				Full = 2032127
				Change = 1245631
				Read = 1179817
			}
			
			$sid = [System.Security.Principal.SecurityIdentifier]$Data.Identity
			[byte[]]$sidBytes = New-Object System.Byte[]($sid.BinaryLength)
			$sid.GetBinaryForm($sidBytes, 0)
			
			$trustee = (New-Object System.Management.ManagementClass('Win32_Trustee')).CreateInstance()
			$trustee.SID = $sidBytes
			$trustee.SidLength = $sid.BinaryLength
			$trustee.SIDString = $sid.Value
			
			$aceObject = (New-Object System.Management.ManagementClass('Win32_ACE')).CreateInstance()
			$aceObject.AceFlags = 0
			$aceObject.AceType = 0
			$aceObject.AccessMask = $accessHash[$Data.AccessRight]
			$aceObject.Trustee = $trustee
			
			try { $securitySettings = Get-WmiObject -Query ('SELECT * FROM Win32_LogicalShareSecuritySetting WHERE Name = "{0}"' -f $Data.Name) -ErrorAction Stop }
			catch { return Write-Result -Failed -State WMIAccess -Message $_ }
			$securityDescriptor = $securitySettings.GetSecurityDescriptor().Descriptor
			[System.Management.ManagementBaseObject[]]$accessControlList = $securityDescriptor.DACL
			if (-not $accessControlList) { $accessControlList = New-Object System.Management.ManagementBaseObject[](1) }
			else { [array]::Resize([ref]$accessControlList, ($accessControlList.Length + 1)) }
			$accessControlList[-1] = $aceObject
			$securityDescriptor.DACL = $accessControlList
			$result = $securitySettings.SetSecurityDescriptor($securityDescriptor)
			
			if ($result.ReturnValue -ne 0) { Write-Result -Failed -State 'FailedApply' -Message "Failed to apply with WMI code $($result.ReturnValue)" }
			else { Write-Result -State Success -Message 'Permissions successfully applied' }
		}
		#endregion Permission Grant Scriptblock
		
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include ComputerName, Credential
	}
	process
	{
		$data = $PSBoundParameters | ConvertTo-PSFHashtable -Include Name, Identity, AccessRight
		try { $results = Invoke-PSFCommand @parameters -ScriptBlock $scriptblock -ErrorAction Stop -ArgumentList $data }
		catch { Stop-PSFFunction -String 'Grant-ShareAccess.WinRM.Failed' -StringValues $Identity, $Name, $ComputerName -EnableException $true -ErrorRecord $_ -Target $ComputerName -Cmdlet $PSCmdlet }
		
		if (-not $results.Success)
		{
			Stop-PSFFunction -String 'Grant-ShareAccess.Execution.Failed' -StringValues $Identity, $Name, $ComputerName, $results.Status, $results.Message -EnableException $true -ErrorRecord $_ -Target $ComputerName -Cmdlet $PSCmdlet
		}
	}
}