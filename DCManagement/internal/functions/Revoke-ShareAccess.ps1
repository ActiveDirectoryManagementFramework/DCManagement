function Revoke-ShareAccess
{
<#
	.SYNOPSIS
		Removes a specific share permission from the specified share.
	
	.DESCRIPTION
		Removes a specific share permission from the specified share.
		Requires user SID and permission match.
		This command uses PowerShell remoting to access the target computer.
	
	.PARAMETER ComputerName
		The name of the server to operate against.
	
	.PARAMETER Credential
		The credentials to use for authentication.
	
	.PARAMETER Name
		The name of the share to modifiy.
	
	.PARAMETER Identity
		The SID of the user to revoke permissions for.
	
	.PARAMETER AccessRight
		The rights of the user that has permissions revoked.
	
	.EXAMPLE
		PS C:\> Revoke-ShareAccess @parameters -Name Legal -Identity S-1-5-21-584015949-955715703-1113067636-1105 -AccessRight Full
	
		Revokes the specified user's full access right to the share "Legal"
#>
	[CmdletBinding()]
	Param (
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
		#region Permission Revocation Scriptblock
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
				Full   = 2032127
				Change = 1245631
				Read   = 1179817
			}
			
			try { $securitySettings = Get-WmiObject -Query ('SELECT * FROM Win32_LogicalShareSecuritySetting WHERE Name = "{0}"' -f $Data.Name) -ErrorAction Stop }
			catch { return Write-Result -Failed -State WMIAccess -Message $_ }
			
			$securityDescriptor = $securitySettings.GetSecurityDescriptor().Descriptor
			
			$securityDescriptor.DACL = [System.Management.ManagementBaseObject[]]($securityDescriptor.DACL | Where-Object {
				-not (
					$_.Trustee.SIDString -eq $Data.Identity -and
					$_.AccessMask -eq $accessHash[$Data.AccessRight]
				)
			})
			$result = $securitySettings.SetSecurityDescriptor($securityDescriptor)
			
			if ($result.ReturnValue -ne 0) { Write-Result -Failed -State 'FailedApply' -Message "Failed to apply with WMI code $($result.ReturnValue)" }
			else { Write-Result -State Success -Message 'Permissions successfully revoked' }
		}
		#endregion Permission Revocation Scriptblock
		
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include ComputerName, Credential
	}
	process
	{
		$data = $PSBoundParameters | ConvertTo-PSFHashtable -Include Name, Identity, AccessRight
		try { $results = Invoke-PSFCommand @parameters -ScriptBlock $scriptblock -ErrorAction Stop -ArgumentList $data }
		catch { Stop-PSFFunction -String 'Revoke-ShareAccess.WinRM.Failed' -StringValues $Identity, $Name, $ComputerName -EnableException $true -ErrorRecord $_ -Target $ComputerName -Cmdlet $PSCmdlet }
		
		if (-not $results.Success)
		{
			Stop-PSFFunction -String 'Revoke-ShareAccess.Execution.Failed' -StringValues $Identity, $Name, $ComputerName, $results.Status, $results.Message -EnableException $true -ErrorRecord $_ -Target $ComputerName -Cmdlet $PSCmdlet
		}
	}
}