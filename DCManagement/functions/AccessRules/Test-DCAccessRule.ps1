function Test-DCAccessRule
{
<#
	.SYNOPSIS
		Tests all DCs, whether their NTFS filesystem Access Rules are configured as designed.
	
	.DESCRIPTION
		Tests all DCs, whether their NTFS filesystem Access Rules are configured as designed.
		This test ONLY considers paths, that are configured.
		In opposite to the DomainManagement AccessRule Component there is no system that considers part of the DCs filesystem as "under management".
	
	.PARAMETER Server
		The server / domain to work with.
	
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.
	
	.EXAMPLE
		PS C:\> Test-DCAccessRule -Server corp.contoso.com
	
		Tests, whether the filesystem Access Rules on all DCs of the corp.contoso.com domain are configured as designed.
#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseUsingScopeModifierInNewRunspaces", "")]
	[CmdletBinding()]
	param (
		[PSFComputer]
		$Server,
		
		[PSCredential]
		$Credential,

        [string[]]
        $TargetServer,
		
		[switch]
		$EnableException
	)
	
	begin
	{
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
        if (-not $Server -and $TargetServer) {
            $parameters.Server = $TargetServer | Select-Object -First 1
        }
		$parameters['Debug'] = $false
		Assert-ADConnection @parameters -Cmdlet $PSCmdlet
		Invoke-PSFCallback -Data $parameters -EnableException $true -PSCmdlet $PSCmdlet
		Assert-Configuration -Type fileSystemAccessRules -Cmdlet $PSCmdlet
		Set-DCDomainContext @parameters
		
		$domainControllers = Get-DomainController @parameters
		$psCred = $PSBoundParameters | ConvertTo-PSFHashtable -Include Credential
		
		#region Utility Functions
		function ConvertFrom-AccessRuleDefinition
		{
			[CmdletBinding()]
			param (
				[Parameter(ValueFromPipeline = $true)]
				$InputObject,
				
				[hashtable]
				$Parameters
			)
			
			process
			{
				$resolvedPath = Resolve-String -Text $InputObject.Path -ArgumentList $Parameters
				
				if ($InputObject.Empty)
				{
					[PSCustomObject]@{
						Path		  = $resolvedPath
						Identity	  = $null
						Principal	  = $null
						AccessRule    = $null
						Configuration = $InputObject
						IdentityError = $false
						ServerRole    = $InputObject.ServerRole
						AccessMode    = 'Constrained'
						Empty		  = $true
					}
					return
				}
				
				$resolvedIdentity = Resolve-String -Text $InputObject.Identity -ArgumentList $Parameters
				$identityError = $false
				try { $resolvedPrincipal = Resolve-Principal @Parameters -Name $resolvedIdentity -OutputType SID -ErrorAction Stop }
				catch
				{
					$identityError = $true
					$resolvedPrincipal = [System.Security.Principal.NTAccount]$resolvedIdentity
				}
				
				$rule = [System.Security.AccessControl.FileSystemAccessRule]::new($resolvedPrincipal, $InputObject.Rights, $InputObject.Inheritance, $InputObject.Propagation, $InputObject.Type)
				Add-Member -InputObject $rule -MemberType NoteProperty -Name DisplayName -Value $resolvedIdentity
				
				[PSCustomObject]@{
					Path		  = $resolvedPath
					Identity	  = $resolvedIdentity
					Principal	  = $resolvedPrincipal
					AccessRule    = $rule
					Configuration = $InputObject
					IdentityError = $identityError
					ServerRole    = $InputObject.ServerRole
					AccessMode    = $InputObject.AccessMode
					Empty		  = $false
				}
			}
		}
		
		function Get-RemoteAccessRule
		{
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
			[CmdletBinding()]
			param (
				$Session,
				
				[string]
				$Path
			)
			
			$rules = Invoke-Command -Session $Session -ScriptBlock {
				$acl = Get-Acl -Path $using:path
				foreach ($rule in $acl.Access)
				{
					if ($rule.IsInherited) { continue }
					[PSCustomObject]@{
						PSTypeName = 'Remote.FileSystemAccessRule'
						DisplayName = $rule.IdentityReference.ToString()
						FileSystemRights = $rule.FileSystemRights
						FileSystemRightsNumeric = [int]$rule.FileSystemRights
						AccessControlType = $rule.AccessControlType
						IdentityReference = $rule.IdentityReference.Translate([System.Security.Principal.SecurityIdentifier])
						InheritanceFlags = $rule.InheritanceFlags
						PropagationFlags = $rule.PropagationFlags
						OriginalRights = $rule.FileSystemRights
					}
				}
			}
			# The default object had display issues when displayed in the "Change" property
			foreach ($rule in $rules)
			{
				$rule.FileSystemRights = Convert-AccessRight -Right $rule.FileSystemRightsNumeric
				$rule
			}
		}
		
		function New-Change
		{
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
			[CmdletBinding()]
			param (
				$RuleObject
			)
			
			Add-Member -InputObject $RuleObject -MemberType ScriptMethod -Name ToString -Force -Value {
				if ($this.DisplayName) { return $this.DisplayName }
				
				return $this.IdentityReference
			} -PassThru
		}
		
		function Test-AccessRule
		{
			[CmdletBinding()]
			param (
				$RuleObject,
				
				$Reference
			)
			
			foreach ($entry in $Reference)
			{
				if ($entry.FileSystemRights -ne $RuleObject.FileSystemRights) { continue }
				if ($entry.AccessControlType -ne $RuleObject.AccessControlType) { continue }
				if ($entry.IdentityReference.ToString() -ne $RuleObject.IdentityReference.ToString()) { continue }
				if ($entry.InheritanceFlags -ne $RuleObject.InheritanceFlags) { continue }
				if ($entry.PropagationFlags -ne $RuleObject.PropagationFlags) { continue }
				
				return $true
			}
			return $false
		}
		
		function Convert-AccessRight
		{
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseUsingScopeModifierInNewRunspaces", "")]
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "")]
			[CmdletBinding()]
			param (
				[int]
				$Right
			)
			$bytes = [System.BitConverter]::GetBytes($Right)
			$uint = [System.BitConverter]::ToUInt32($bytes, 0)
			
			$definitiveRight = [DCManagement.FileSystemPermission]$uint
			
			# https://docs.microsoft.com/en-us/windows/win32/fileio/file-security-and-access-rights
			# https://docs.microsoft.com/en-us/windows/win32/secauthz/standard-access-rights
			$genericRightsMap = @{
				All = [DCManagement.FileSystemPermission]::FullControl
				Execute = ([DCManagement.FileSystemPermission]'ExecuteFile, ReadAttributes, ReadPermissions, Synchronize')
				Read = ([DCManagement.FileSystemPermission]'ReadAttributes, ReadData, ReadExtendedAttributes, ReadPermissions, Synchronize')
				Write = ([DCManagement.FileSystemPermission]'AppendData, WriteAttributes, WriteData, WriteExtendedAttributes, ReadPermissions, Synchronize')
			}
			
			if ($definitiveRight -band [DCManagement.FileSystemPermission]::GenericAll) { return [System.Security.AccessControl.FileSystemRights]::FullControl }
			if ($definitiveRight -band [DCManagement.FileSystemPermission]::GenericExecute)
			{
				$definitiveRight = $definitiveRight -bxor [DCManagement.FileSystemPermission]::GenericExecute -bor $genericRightsMap.Execute
			}
			if ($definitiveRight -band [DCManagement.FileSystemPermission]::GenericRead)
			{
				$definitiveRight = $definitiveRight -bxor [DCManagement.FileSystemPermission]::GenericRead -bor $genericRightsMap.Read
			}
			if ($definitiveRight -band [DCManagement.FileSystemPermission]::GenericWrite)
			{
				$definitiveRight = $definitiveRight -bxor [DCManagement.FileSystemPermission]::GenericWrite -bor $genericRightsMap.Write
			}
			[System.Security.AccessControl.FileSystemRights]$definitiveRight.Value__
		}
		#endregion Utility Functions
	}
	process
	{
		foreach ($domainController in $domainControllers)
		{
            if ($TargetServer -and $domainController.Name -notin $TargetServer) { continue }
			$results = @{
				ObjectType = 'FSAccessRule'
				Server	   = $domainController.Name
			}
			
			Write-PSFMessage -String 'Test-DCAccessRule.Processing' -StringValues $domainController.Name -Target $domainController.Name
			try { $psSession = New-PSSession -ComputerName $domainController.Name @psCred -ErrorAction Stop }
			catch { Stop-PSFFunction -String 'Test-DCAccessRule.PSSession.Failed' -StringValues $domainController.Name -EnableException $EnableException -Cmdlet $PSCmdlet -Continue -Target $domainController.Name -ErrorRecord $_ }
			$accessConfigurations = Get-DCAccessRule | Where-Object {
				$_.ServerRole -eq 'ALL' -or
				($_.ServerRole -eq 'FSMO' -and $domainController.IsFSMO) -or
				($_.ServerRole -eq 'PDC' -and $domainController.IsPDCEmulator)
			} | ConvertFrom-AccessRuleDefinition -Parameters $parameters
			
			$groupedByPath = $accessConfigurations | Group-Object -Property Path
			foreach ($path in $groupedByPath)
			{
				Write-PSFMessage -String 'Test-DCAccessRule.Processing.Path' -StringValues $domainController.Name, $path.Name -Target $domainController.Name
				
				$pathExists = Invoke-Command -Session $psSession -ScriptBlock { Test-Path -Path $using:path.Name }
				if (-not $pathExists)
				{
					foreach ($entry in $path.Group)
					{
						New-TestResult @results -Type NoPath -Configuration $entry -Identity $path.Name -Changed (New-Change -RuleObject $desiredRule.AccessRule)
					}
					Stop-PSFFunction -String 'Test-DCAccessRule.Path.ExistsNot' -StringValues $domainController.Name, $path.Name -EnableException $EnableException -Cmdlet $PSCmdlet -Continue -Target $domainController.Name
				}
				
				$existingRules = Get-RemoteAccessRule -Session $psSession -Path $path.Name
				
				#region Empty Mode: No explicit ACE should exist
				if ($path.Group | Where-Object Empty)
				{
					
					foreach ($rule in $existingRules)
					{
						New-TestResult @results -Type Remove -Configuration $path.Group -ADObject $existingRules -Identity $path.Name -Changed (New-Change -RuleObject $rule)
					}
					continue
				}
				#endregion Empty Mode: No explicit ACE should exist
				
				$effectiveMode = 'Additive'
				if ($path.Group | Where-Object AccessMode -EQ 'Defined') { $effectiveMode = 'Defined' }
				if ($path.Group | Where-Object AccessMode -EQ 'Constrained') { $effectiveMode = 'Constrained' }
				
				if ($path.Group | Where-Object IdentityError)
				{
					# Interrupt if Constrained and resolution error
					if ($effectiveMode -eq 'Constrained')
					{
						$errorCfg = $path.Group | Where-Object IdentityError
						Stop-PSFFunction -String 'Test-DCAccessRule.Identity.Error' -StringValues $domainController.Name, $path.Name, ($errorCfg.Identity -join ",") -EnableException $EnableException -Cmdlet $PSCmdlet -Continue -Target $domainController.Name
					}
					else
					{
						Write-PSFMessage -Level Warning -String 'Test-DCAccessRule.Identity.Error' -StringValues $domainController.Name, $path.Name, ($errorCfg.Identity -join ",")
					}
				}
				
				$effectiveDesiredState = $path.Group | Where-Object IdentityError -NE $true
				
				#region Compare desired state with existing state
				foreach ($desiredRule in $effectiveDesiredState)
				{
					if (Test-AccessRule -RuleObject $desiredRule.AccessRule -Reference $existingRules) { continue }
					New-TestResult @results -Type Add -Configuration $desiredRule -ADObject $existingRules -Identity $path.Name -Changed (New-Change -RuleObject $desiredRule.AccessRule)
				}
				
				if ($effectiveMode -eq 'Additive') { continue }
				
				foreach ($existingRule in $existingRules)
				{
					if ($effectiveMode -eq 'Defined' -and "$($existingRule.IdentityReference.ToString())" -notin ($effectiveDesiredState.AccessRule.IdentityReference | ForEach-Object ToString)) { continue }
					if (Test-AccessRule -RuleObject $existingRule -Reference $effectiveDesiredState.AccessRule) { continue }
					New-TestResult @results -Type Remove -Configuration $effectiveDesiredState -ADObject $existingRule -Identity $path.Name -Changed (New-Change -RuleObject $existingRule)
				}
				#endregion Compare desired state with existing state
			}
			
			Remove-PSSession -Session $psSession -ErrorAction Ignore -Confirm:$false
		}
	}
}