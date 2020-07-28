function Install-DCChildDomain
{
	<#
	.SYNOPSIS
		Installs a child domain.
	
	.DESCRIPTION
		Installs a child domain.
	
	.PARAMETER ComputerName
		The server to promote to a DC hosting a new subdomain.
	
	.PARAMETER Credential
		The credentials to use for connecting to the DC-to-be.
	
	.PARAMETER DomainName
		The name of the domain to install.
		Note: Only specify the first DNS element, not the full fqdn of the domain.
		(The component usually representing the Netbios Name)
	
	.PARAMETER ParentDomainName
		The FQDN of the parent domain.
	
	.PARAMETER NetBiosName
		The NetBios name of the domain.
		Will use the DomainName if not specified.
	
	.PARAMETER SafeModeAdministratorPassword
		The SafeModeAdministratorPassword specified during domain creation.
		If not specified, a random password will be chosen.
		The password is part of the return values.
	
	.PARAMETER EnterpriseAdminCredential
		The Credentials of an Enterprise administrator.
		Will prompt for credentials if not specified.
	
	.PARAMETER NoDNS
		Disables installation and configuration of the DNS role as part of the installation.
	
	.PARAMETER NoReboot
		Prevents reboot of the server after installation.
		Note: Generally a reboot is required before proceeding, disabling this will lead to having to manually reboot the computer.
	
	.PARAMETER LogPath
		The path where the NTDS logs should be stored.
	
	.PARAMETER SysvolPath
		The path where SYSVOL should be stored.
	
	.PARAMETER DatabasePath
		The path where the NTDS database is being stored.
	
	.PARAMETER NoResultCache
		Disables caching of the command's return object.
		By default, this command will cache the return object as a global variable.
	
	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.
	
	.PARAMETER Confirm
		If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.
	
	.PARAMETER WhatIf
		If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.
	
	.EXAMPLE
		PS C:\> Install-DCChildDomain -ComputerName 10.1.2.3 -Credential $cred -DomainName corp -ParentDomainName contoso.com

		Will install the childdomain corp.contoso.com under the domain contoso.com on the server 10.1.2.3.
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
		[PsfValidatePattern('^([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-_]{0,61}[a-zA-Z0-9])$', ErrorString = 'DCManagement.Validate.Child.DomainName')]
		[string]
		$DomainName,

		[Parameter(Mandatory = $true)]
		[PsfValidatePattern('^([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-_]{0,61}[a-zA-Z0-9])(\.([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-_]{0,61}[a-zA-Z0-9])){1,}$', ErrorString = 'DCManagement.Validate.Parent.DnsDomainName')]
		[string]
		$ParentDomainName,

		[string]
		$NetBiosName,

		[securestring]
		$SafeModeAdministratorPassword = (New-Password -Length 32 -AsSecureString),

		[PSCredential]
		$EnterpriseAdminCredential = (Get-Credential -Message "Enter credentials for Enterprise Administrator to create child domain"),

		[switch]
		$NoDNS = (Get-PSFConfigValue -FullName 'DCManagement.Defaults.NoDNS'),

		[switch]
		$NoReboot = (Get-PSFConfigValue -FullName 'DCManagement.Defaults.NoReboot'),

		[string]
		$LogPath = (Get-PSFConfigValue -FullName 'DCManagement.Defaults.LogPath'),

		[string]
		$SysvolPath = (Get-PSFConfigValue -FullName 'DCManagement.Defaults.SysvolPath'),

		[string]
		$DatabasePath = (Get-PSFConfigValue -FullName 'DCManagement.Defaults.DatabasePath'),

		[switch]
		$NoResultCache,

		[switch]
		$EnableException
	)
	
	begin
	{
		#region Scriptblock
		$scriptBlock = {
			param ($Configuration)

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
				NewDomainName = $Configuration.NewDomainName
				NewDomainNetBiosName = $Configuration.NewDomainNetBiosName
				ParentDomainName = $Configuration.ParentDomainName
				Credential = $Configuration.EnterpriseAdminCredential
				DomainMode = 'Win2012R2'
				DatabasePath = $Configuration.DatabasePath
				LogPath = $Configuration.LogPath
				SysvolPath = $Configuration.SysvolPath
				InstallDNS = $Configuration.InstallDNS
				SafeModeAdministratorPassword = $Configuration.SafeModeAdministratorPassword
				NoRebootOnCompletion = $Configuration.NoRebootOnCompletion
			}

			# Test Installation
			$testResult = Test-ADDSDomainInstallation @parameters -WarningAction SilentlyContinue
			if ($testResult.Status -eq "Error") {
				New-Result -Status Error -Message "Failed validating Domain Installation: $($testResult.Message)" -Data $testResult
				return
			}

			# Execute Installation
			try {
				$resultData = Install-ADDSDomain @parameters -ErrorAction Stop -Confirm:$false -WarningAction SilentlyContinue
				if ($resultData.Status -eq "Error") {
					New-Result -Status Error -Message "Failed installing domain: $($resultData.Message)" -Data $resultData
					return
				}
				New-Result -Status 'Success' -Message "Domain $($Configuration.NewDomainName) successfully installed" -Data $resultData
				return
			}
			catch {
				New-Result -Status Error -Message "Error executing domain deployment: $_" -ErrorRecord $_
				return
			}
		}
		#endregion Scriptblock
	}
	process
	{
		if (-not $NetBiosName) { $NetBiosName = $DomainName }
		$configuration = [PSCustomObject]@{
			NewDomainName = $DomainName
			NewDomainNetBiosName = $NetBiosName
			ParentDomainName = $ParentDomainName
			EnterpriseAdminCredential = $EnterpriseAdminCredential
			InstallDNS = (-not $NoDNS)
			LogPath = $LogPath
			SysvolPath = $SysvolPath
			DatabasePath = $DatabasePath
			NoRebootOnCompletion = $NoReboot
			SafeModeAdministratorPassword = $SafeModeAdministratorPassword
		}

		Invoke-PSFProtectedCommand -ActionString 'Install-DCChildDomain.Installing' -Target $DomainName -ScriptBlock {
			$result = Invoke-PSFCommand -ComputerName $ComputerName -Credential $Credential -ScriptBlock $scriptBlock -ErrorAction Stop -ArgumentList $configuration
			$result.SafeModeAdminPassword = $SafeModeAdministratorPassword
			$result = $result | Select-PSFObject -KeepInputObject -ScriptProperty @{
				Password = {
					[PSCredential]::new("Foo", $this.SafeModeAdminPassword).GetNetworkCredential().Password
				}
			} -ShowProperty Success, Message
			if (-not $NoResultCache) {
				$global:DomainCreationResult = $result
			}
			$result
		} -EnableException $EnableException -PSCmdlet $PSCmdlet
		if (Test-PSFFunctionInterrupt) { return }
		
		if (-not $NoResultCache) {
			Write-PSFMessage -Level Host -String 'Install-DCChildDomain.Results' -StringValues $DomainName
		}
	}
}
