﻿function Install-DCRootDomain
{
	<#
	.SYNOPSIS
		Deploys a new forest / root domain.
	
	.DESCRIPTION
		Deploys a new forest / root domain.
	
	.PARAMETER ComputerName
		The computer on which to install it.
		Uses WinRM / PowerShell remoting if not local execution.
	
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.PARAMETER DnsName
		The name of the new domain & forest.
	
	.PARAMETER NetBiosName
		The netbios name of the new domain.
		If not specified, it will automatically use the first element of the DNS name
	
	.PARAMETER SafeModeAdministratorPassword
		The password to use as SafeModeAdministratorPassword.
		Autogenerates and reports a new password if not specified.
	
	.PARAMETER NoDNS
		Disable deploying a DNS service with the new forest.
	
	.PARAMETER NoReboot
		Prevent reboot after finishing deployment
	
	.PARAMETER LogPath
		The path where the DC will store the logs.
	
	.PARAMETER SysvolPath
		The path where the DC will store sysvol.
	
	.PARAMETER DatabasePath
		The path where the DC will store NTDS Database.

	.PARAMETER NoResultCache
		Disables caching the result object of the operation.
		By default, this command will cache the result of the installation (including the SafeModeAdministratorPassword), to reduce the risk of user error.
	
	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.
	
	.PARAMETER Confirm
		If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.
	
	.PARAMETER WhatIf
		If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.
	
	.EXAMPLE
		PS C:\> Install-DCRootDomain -DnsName 'contoso.com'

		Creates the forest "contoso.com" while promoting the computer as DC.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "")]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
	[CmdletBinding(SupportsShouldProcess = $true)]
	Param (
		[PSFComputer]
		$ComputerName = 'localhost',

		[PSCredential]
		$Credential,

		[Parameter(Mandatory = $true)]
		[PsfValidatePattern('^([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-_]{0,61}[a-zA-Z0-9])(\.([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-_]{0,61}[a-zA-Z0-9])){1,}$', ErrorString = 'DCManagement.Validate.ForestRoot.DnsDomainName')]
		[string]
		$DnsName,

		[string]
		$NetBiosName,

		[securestring]
		$SafeModeAdministratorPassword = (New-Password -Length 32 -AsSecureString),

		[switch]
		$NoDNS,

		[switch]
		$NoReboot,

		[string]
		$LogPath,

		[string]
		$SysvolPath,

		[string]
		$DatabasePath,

		[switch]
		$NoResultCache,

		[switch]
		$EnableException
	)
	
	begin
	{
		$parameters = @{ Server = $ComputerName; IsDCInstall = $true }
		if ($Credential) { $parameters['Credential'] = $Credential}
		Invoke-PSFCallback -Data $parameters -EnableException $true -PSCmdlet $PSCmdlet
		
		$NoDNS = Resolve-ParameterValue -FullName 'DCManagement.Defaults.NoDNS' -InputObject $NoDNS
		$NoReboot = Resolve-ParameterValue -FullName 'DCManagement.Defaults.NoReboot' -InputObject $NoReboot
		$LogPath = Resolve-ParameterValue -FullName 'DCManagement.Defaults.LogPath' -InputObject $LogPath
		$SysvolPath = Resolve-ParameterValue -FullName 'DCManagement.Defaults.SysvolPath' -InputObject $SysvolPath
		$DatabasePath = Resolve-ParameterValue -FullName 'DCManagement.Defaults.DatabasePath' -InputObject $DatabasePath
		
		
		#region Main Scriptblock
		$scriptBlock = {
			param (
				$Configuration
			)
			function New-Result {
				[CmdletBinding()]
				param (
					[ValidateSet('Success', 'Error')]
					[string]
					$Status = 'Success',

					[string]
					$Message,

					$ErrorRecord,

					$Data
				)

				[PSCustomObject]@{
					Status = $Status
					Success = $Status -eq 'Success'
					Message = $Message
					Error = $ErrorRecord
					Data = $Data
					SafeModeAdminPassword = $null
				}
			}
			
			# Check whether domain member
			$computerSystem = Get-CimInstance win32_ComputerSystem
			if ($computerSystem.PartOfDomain) {
				New-Result -Status Error -Message "Computer $env:COMPUTERNAME is part of AD domain: $($computerSystem.Domain)"
				return
			}

			$parameters = @{
				DomainName = $Configuration.DnsName
				DomainMode = 'Win2012R2'
				DomainNetbiosName = $Configuration.NetBiosName
				ForestMode = 'Win2012R2'
				DatabasePath = $Configuration.DatabasePath
				LogPath = $Configuration.LogPath
				SysvolPath = $Configuration.SysvolPath
				InstallDNS = $Configuration.InstallDNS
				SafeModeAdministratorPassword = $Configuration.SafeModeAdministratorPassword
				NoRebootOnCompletion = $Configuration.NoRebootOnCompletion
			}
			
			# Test Installation
			$testResult = Test-ADDSForestInstallation @parameters -WarningAction SilentlyContinue
			if ($testResult.Status -eq "Error") {
				New-Result -Status Error -Message "Failed validating Forest Installation: $($testResult.Message)" -Data $testResult
				return
			}

			# Execute Installation
			try {
				$resultData = Install-ADDSForest @parameters -ErrorAction Stop -Confirm:$false -WarningAction SilentlyContinue
				if ($resultData.Status -eq "Error") {
					New-Result -Status Error -Message "Failed installing Forest: $($resultData.Message)" -Data $resultData
					return
				}
				New-Result -Status 'Success' -Message "Domain $($Configuration.DnsName) successfully installed" -Data $resultData
				return
			}
			catch {
				New-Result -Status Error -Message "Error executing forest deployment: $_" -ErrorRecord $_
				return
			}
		}
		#endregion Main Scriptblock
	}
	process
	{
		if (-not $NetBiosName) { $NetBiosName = $DnsName -split "\." | Select-Object -First 1 }
		$configuration = [PSCustomObject]@{
			DnsName = $DnsName
			NetBiosName = $NetBiosName
			SafeModeAdministratorPassword = $SafeModeAdministratorPassword
			InstallDNS = (-not $NoDNS)
			LogPath = $LogPath
			SysvolPath = $SysvolPath
			DatabasePath = $DatabasePath
			NoRebootOnCompletion = $NoReboot
		}

		Invoke-PSFProtectedCommand -ActionString 'Install-DCRootDomain.Installing' -Target $DnsName -ScriptBlock {
			$result = Invoke-PSFCommand -ComputerName $ComputerName -Credential $Credential -ScriptBlock $scriptBlock -ErrorAction Stop -ArgumentList $configuration
			$result.SafeModeAdminPassword = $SafeModeAdministratorPassword
			$result = $result | Select-PSFObject -KeepInputObject -ScriptProperty @{
				Password = {
					[PSCredential]::new("Foo", $this.SafeModeAdminPassword).GetNetworkCredential().Password
				}
			} -ShowProperty Success, Message
			if (-not $NoResultCache) {
				$global:ForestCreationResult = $result
			}
			$result
		} -EnableException $EnableException -PSCmdlet $PSCmdlet
		if (Test-PSFFunctionInterrupt) { return }
		
		if (-not $NoResultCache) {
			Write-PSFMessage -Level Host -String 'Install-DCRootDomain.Results' -StringValues $DnsName
		}
	}
}
