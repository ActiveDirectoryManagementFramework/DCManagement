function Install-DCDomainController
{
	<#
	.SYNOPSIS
		Adds a new domain controller to an existing domain.
	
	.DESCRIPTION
		Adds a new domain controller to an existing domain.
		The target computer cannot already be part of the domain.
	
	.PARAMETER ComputerName
		The target to promote to domain controller.
		Accepts and reuses an already established PowerShell Remoting Session.
	
	.PARAMETER Credential
		Credentials to use for authenticating to the computer account being promoted.
	
	.PARAMETER DomainName
		The fully qualified dns name of the domain to join the DC to.
	
	.PARAMETER DomainCredential
		Credentials to use when authenticating to the domain.
	
	.PARAMETER SafeModeAdministratorPassword
		The password to use as SafeModeAdministratorPassword.
		Autogenerates and reports a new password if not specified.
	
	.PARAMETER NoDNS
		Disable deploying a DNS service with the new domain controller.
	
	.PARAMETER NoReboot
		Prevent reboot after finishing deployment
	
	.PARAMETER LogPath
		The path where the DC will store the logs.
	
	.PARAMETER Sysvolpath
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
		PS C:\> Install-DCDomainController -Computer dc2.contoso.com -Credential $localCred -DomainName 'contoso.com' -DomainCredential $domCred

		Joins the server dc2.contoso.com into the contoso.com domain, as a promoted domain controller using the specified credentials.
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
		$DomainName,

		[PSCredential]
		$DomainCredential = (Get-Credential -Message 'Specify domain admin credentials needed to authorize the promotion to domain controller'),

		[securestring]
		$SafeModeAdministratorPassword = (New-Password -Length 32 -AsSecureString),

		[switch]
		$NoDNS = (Get-PSFConfigValue -FullName 'DCManagement.Defaults.NoDNS'),

		[switch]
		$NoReboot = (Get-PSFConfigValue -FullName 'DCManagement.Defaults.NoReboot'),

		[string]
		$LogPath = (Get-PSFConfigValue -FullName 'DCManagement.Defaults.LogPath'),

		[string]
		$Sysvolpath = (Get-PSFConfigValue -FullName 'DCManagement.Defaults.SysvolPath'),

		[string]
		$DatabasePath = (Get-PSFConfigValue -FullName 'DCManagement.Defaults.DatabasePath'),

		[switch]
		$NoResultCache,

		[switch]
		$EnableException
	)
	
	begin
	{
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
				DomainName = $Configuration.DomainName
				Credential = $Configuration.DomainCredential
				DatabasePath = $Configuration.DatabasePath
				LogPath = $Configuration.LogPath
				SysvolPath = $Configuration.Sysvol
				InstallDNS = $Configuration.InstallDNS
				SafeModeAdministratorPassword = $Configuration.SafeModeAdministratorPassword
				NoRebootOnCompletion = $Configuration.NoRebootOnCompletion
			}
			
			# Test Installation
			$testResult = Test-ADDSDomainController @parameters -WarningAction SilentlyContinue
			if ($testResult.Status -eq "Error") {
				New-Result -Status Error -Message "Failed validating Domain Controller Installation: $($testResult.Message)" -Data $testResult
				return
			}

			# Execute Installation
			try {
				$resultData = Install-ADDSDomainController @parameters -ErrorAction Stop -Confirm:$false -WarningAction SilentlyContinue
				if ($resultData.Status -eq "Error") {
					New-Result -Status Error -Message "Failed installing Domain Controller: $($resultData.Message)" -Data $resultData
					return
				}
				New-Result -Status 'Success' -Message "Domain $($Configuration.DomainName) successfully installed" -Data $resultData
				return
			}
			catch {
				New-Result -Status Error -Message "Error executing Domain Controller deployment: $_" -ErrorRecord $_
				return
			}
		}
		#endregion Main Scriptblock
	}
	process
	{
		if (-not $NetBiosName) { $NetBiosName = $DnsName -split "\." | Select-Object -First 1 }
		$configuration = [PSCustomObject]@{
			DomainName = $DomainName
			DomainCredential = $DomainCredential
			SafeModeAdministratorPassword = $SafeModeAdministratorPassword
			InstallDNS = (-not $NoDNS)
			LogPath = $LogPath
			SysvolPath = $SysvolPath
			DatabasePath = $DatabasePath
			NoRebootOnCompletion = $NoReboot
		}
		
		Invoke-PSFProtectedCommand -ActionString 'Install-DCDomainController.Installing' -ActionStringValues $DomainName -Target $DnsName -ScriptBlock {
			$result = Invoke-PSFCommand -ComputerName $ComputerName -Credential $Credential -ScriptBlock $scriptBlock -ErrorAction Stop -ArgumentList $configuration
			$result.SafeModeAdminPassword = $SafeModeAdministratorPassword
			$result = $result | Select-PSFObject -KeepInputObject -ScriptProperty @{
				Password = {
					[PSCredential]::new("Foo", $this.SafeModeAdminPassword).GetNetworkCredential().Password
				}
			} -ShowProperty Success, Message
			if (-not $NoResultCache) {
				$global:DCCreationResult = $result
			}
			$result
		} -EnableException $EnableException -PSCmdlet $PSCmdlet
		if (Test-PSFFunctionInterrupt) { return }

		if (-not $NoResultCache) {
			Write-PSFMessage -Level Host -String 'Install-DCDomainController.Results' -StringValues $DnsName
		}
	}
}
