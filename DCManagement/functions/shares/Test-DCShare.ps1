function Test-DCShare
{
<#
	.SYNOPSIS
		Tests all DCs in the target domain for share compliance.
	
	.DESCRIPTION
		Tests all DCs in the target domain, by comparing existing shares with the list of defined shares.
		Use Register-DCShare (or an ADMF Context) to define shares.
	
	.PARAMETER Server
		The server / domain to work with.
	
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.
	
	.EXAMPLE
		PS C:\> Test-DCShare -Server contoso.com
	
		Tests all DCs in the domain contoso.com, whether their shares are as configured.
#>
	[CmdletBinding()]
	Param (
		[PSFComputer]
		$Server,
		
		[PSCredential]
		$Credential,
		
		[switch]
		$EnableException
	)
	
	begin
	{
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$parameters['Debug'] = $false
		Assert-ADConnection @parameters -Cmdlet $PSCmdlet
		Invoke-PSFCallback -Data $parameters -EnableException $true -PSCmdlet $PSCmdlet
		Assert-Configuration -Type Shares -Cmdlet $PSCmdlet
		Set-DCDomainContext @parameters
		
		$domainControllers = Get-DomainController @parameters
		$cimCred = $PSBoundParameters | ConvertTo-PSFHashtable -Include Credential
		
		#region Utility Functions
		function ConvertFrom-ShareConfiguration
		{
			[CmdletBinding()]
			param (
				[Parameter(ValueFromPipeline = $true)]
				$ShareConfiguration,
				
				[hashtable]
				$Parameters
			)
			
			process
			{
				$cfgHash = $ShareConfiguration | ConvertTo-PSFHashtable
				$cfgHash.Name = $cfgHash.Name | Resolve-String -ArgumentList $Parameters
				$cfgHash.Path = $cfgHash.Path | Resolve-String -ArgumentList $Parameters
				$cfgHash.Description = $cfgHash.Description | Resolve-String -ArgumentList $Parameters
				$cfgHash.AccessIdentityIntegrity = $true
				$cfgHash.FullAccess = foreach ($entry in $cfgHash.FullAccess)
				{
					try { ($entry | Resolve-String -ArgumentList $Parameters | Resolve-Principal @Parameters -OutputType SID -ErrorAction Stop) -as [string] }
					catch
					{
						Write-PSFMessage -Level Warning -String 'Test-DCShare.Identity.Resolution.Failed' -StringValues $entry -Target $ShareConfiguration
						$cfgHash.AccessIdentityIntegrity = $false
					}
				}
				$cfgHash.WriteAccess = foreach ($entry in $cfgHash.WriteAccess)
				{
					try { ($entry | Resolve-String -ArgumentList $Parameters | Resolve-Principal @Parameters -OutputType SID -ErrorAction Stop) -as [string] }
					catch
					{
						Write-PSFMessage -Level Warning -String 'Test-DCShare.Identity.Resolution.Failed' -StringValues $entry -Target $ShareConfiguration
						$cfgHash.AccessIdentityIntegrity = $false
					}
				}
				$cfgHash.ReadAccess = foreach ($entry in $cfgHash.ReadAccess)
				{
					try { ($entry | Resolve-String -ArgumentList $Parameters | Resolve-Principal @Parameters -OutputType SID -ErrorAction Stop) -as [string] }
					catch
					{
						Write-PSFMessage -Level Warning -String 'Test-DCShare.Identity.Resolution.Failed' -StringValues $entry -Target $ShareConfiguration
						$cfgHash.AccessIdentityIntegrity = $false
					}
				}
				[pscustomobject]$cfgHash
			}
		}
		
		function Compare-ShareAccess
		{
			[CmdletBinding()]
			param (
				$Configuration,
				
				$ShareAccess,
				
				[hashtable]
				$Parameters
			)
			
			$access = @{
				Full = @()
				Change = @()
				Read = @()
			}
			foreach ($accessItem in $ShareAccess)
			{
				$access["$($accessItem.AccessRight)"] += ($accessItem.AccountName | Resolve-Principal @Parameters -OutputType SID) -as [string]
			}
			
			#region Compare Defined with current state
			foreach ($entity in $Configuration.FullAccess)
			{
				if ($entity -notin $access.Full) { New-AccessChange -AccessRight Full -Identity $entity -Action Add }
			}
			foreach ($entity in $Configuration.WriteAccess)
			{
				if ($entity -notin $access.Change) { New-AccessChange -AccessRight Change -Identity $entity -Action Add }
			}
			foreach ($entity in $Configuration.ReadAccess)
			{
				if ($entity -notin $access.Read) { New-AccessChange -AccessRight Read -Identity $entity -Action Add }
			}
			#endregion Compare Defined with current state
			
			# If we will not remove any rights, no point inspecting the existing access rights
			if ($Configuration.AccessMode -eq 'Additive') { return }
			
			#region Compare current with defined state
			#region Full Access
			foreach ($entity in $access.Full)
			{
				if ($entity -notin $Configuration.FullAccess)
				{
					if ($Configuration.AccessMode -eq 'Constrained')
					{
						New-AccessChange -AccessRight Full -Identity $entity -Action Remove
						continue
					}
					
					if ($entity -notin $Configuration.WriteAccess -and $entity -notin $Configuration.ReadAccess) { continue }
					New-AccessChange -AccessRight Full -Identity $entity -Action Remove
				}
			}
			#endregion Full Access
			#region Write Access
			foreach ($entity in $access.Change)
			{
				if ($entity -notin $Configuration.WriteAccess)
				{
					if ($Configuration.AccessMode -eq 'Constrained')
					{
						New-AccessChange -AccessRight Change -Identity $entity -Action Remove
						continue
					}
					
					if ($entity -notin $Configuration.FullAccess -and $entity -notin $Configuration.ReadAccess) { continue }
					New-AccessChange -AccessRight Change -Identity $entity -Action Remove
				}
			}
			#endregion Write Access
			#region Read Access
			foreach ($entity in $access.Read)
			{
				if ($entity -notin $Configuration.ReadAccess)
				{
					if ($Configuration.AccessMode -eq 'Constrained')
					{
						New-AccessChange -AccessRight Read -Identity $entity -Action Remove
						continue
					}
					
					if ($entity -notin $Configuration.FullAccess -and $entity -notin $Configuration.WriteAccess) { continue }
					New-AccessChange -AccessRight Read -Identity $entity -Action Remove
				}
			}
			#endregion Read Access
			#endregion Compare current with defined state
		}
		
		function New-AccessChange
		{
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
			[CmdletBinding()]
			param (
				[ValidateSet('Full','Change','Read')]
				[string]
				$AccessRight,
				
				[string]
				$Identity,
				
				[ValidateSet('Add','Remove')]
				[string]
				$Action
			)
			
			[PSCustomObject]@{
				PSTypeName = 'DCManagement.Share.AccessChange'
				Action	   = $Action
				AccessRight = $AccessRight
				Identity    = $Identity
			}
		}
		#endregion Utility Functions
	}
	process
	{
		foreach ($domainController in $domainControllers)
		{
			$results = @{
				ObjectType = 'Share'
				Server = $domainController.Name
			}
			
			Write-PSFMessage -String 'Test-DCShare.Processing' -StringValues $domainController.Name
			try { $cimSession = New-CimSession -ComputerName $domainController.Name @cimCred -ErrorAction Stop }
			catch { Stop-PSFFunction -String 'Test-DCShare.CimSession.Failed' -StringValues $domainController.Name -EnableException $EnableException -Cmdlet $PSCmdlet -Continue -Target $domainController.Name -ErrorRecord $_ }
			$shareConfigurations = Get-DCShare | Where-Object {
				$_.ServerRole -eq 'ALL' -or
				($_.ServerRole -eq 'FSMO' -and $domainController.IsFSMO) -or
				($_.ServerRole -eq 'PDC' -and $domainController.IsPDCEmulator)
			} | ConvertFrom-ShareConfiguration -Parameters $parameters
			
			$shares = Get-SmbShare -CimSession $cimSession -IncludeHidden | Add-Member -MemberType NoteProperty -Name ComputerName -Value $domainController.Name -Force -PassThru
			
			foreach ($share in $shares)
			{
				$sResults = $results.Clone()
				$sResults.Identity = '\\{0}\{1}' -f $share.ComputerName, $share.Name
				$sResults.ADObject = $share
				
				#region Share exists, but is not defined
				if ($share.Name -notin $shareConfigurations.Name)
				{
					# The special builtin shares will not trigger delete actions
					if ($share.Special) { continue }
					if ($share.Name -in 'NETLOGON','SYSVOL') { continue }
					
					New-Testresult @sResults -Type Delete
					continue
				}
				#endregion Share exists, but is not defined
				
				$configuration = $shareConfigurations | Where-Object Name -EQ $share.Name
				$sResults.Configuration = $configuration
				
				#region Handle Property Settings
				[System.Collections.ArrayList]$changes = @()
				Compare-Property -Configuration $configuration -ADObject $share -Changes $changes -Property Path
				Compare-Property -Configuration $configuration -ADObject $share -Changes $changes -Property Description
				
				if ($changes)
				{
					New-Testresult @sResults -Type Update -Changed $changes.ToArray()
				}
				#endregion Handle Property Settings
				
				#region Delegation
				if (-not $configuration.AccessIdentityIntegrity)
				{
					Write-PSFMessage -Level Warning -String 'Test-DCShare.Access.IntegrityError' -StringValues $share.Name, $domainController.Name -Tag panic, error, fail
					continue
				}
				$access = Get-SmbShareAccess -CimSession $cimSession -Name $share.Name
				$delta = Compare-ShareAccess -Configuration $configuration -ShareAccess $access -Parameters $parameters
				if ($delta)
				{
					New-Testresult @sResults -Type AccessUpdate -Changed $delta
				}
				#endregion Delegation
			}
			
			foreach ($cfgShare in $shareConfigurations)
			{
				if ($cfgShare.Name -in $shares.Name) { continue }
				
				New-TestResult @results -Type New -Identity "\\$($domainController.Name)\$($cfgShare.Name)" -Configuration $cfgShare
			}
			
			Remove-CimSession -CimSession $cimSession -ErrorAction Ignore -WhatIf:$false -Confirm:$false
		}
	}
}
