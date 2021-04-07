function Invoke-DCAccessRule
{
<#
	.SYNOPSIS
		Applies the desired state for filesystem permissions on paths on relevant DCs.
	
	.DESCRIPTION
		Applies the desired state for filesystem permissions on paths on relevant DCs.
		Use Register-DCAccessRule to define the desired state.
		Use Test-DCAccessRule to test, what should be changed.
		By default, all pending access rule changes will be applied, specify the explicit test results you want to process to override this.
	
	.PARAMETER InputObject
		The specific test results produced by Test-DCAccessRule to apply.
		If you do not specify this parameter, ALL pending changes will be performed!
	
	.PARAMETER Server
		The server / domain to work with.
	
	.PARAMETER Credential
		The credentials to use for this operation.
	
	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.
	
	.PARAMETER Confirm
		If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.
	
	.PARAMETER WhatIf
		If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.
	
	.EXAMPLE
		PS C:\> Invoke-DCAccessRule -Server corp.contoso.com
	
		Brings all DCs of the corp.contoso.com domain into their desired state as far as filesystem Access Rules are concerned.
#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseUsingScopeModifierInNewRunspaces", "")]
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(ValueFromPipeline = $true)]
		$InputObject,
		
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
		
		$psCred = $PSBoundParameters | ConvertTo-PSFHashtable -Include Credential
		
		$psSessions = @{ }
		
		#region Functions
		function Add-AccessRule
		{
			[CmdletBinding()]
			param (
				$Session,
				
				[string]
				$Path,
				
				$AccessRule
			)
			
			$result = Invoke-Command -Session $Session -ScriptBlock {
				$referenceRule = $using:AccessRule
				try
				{
					$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
						([System.Security.Principal.SecurityIdentifier]$referenceRule.IdentityReference.ToString()),
						$referenceRule.FileSystemRights,
						$referenceRule.InheritanceFlags,
						$referenceRule.PropagationFlags,
						$referenceRule.AccessControlType
					)
					$acl = Get-Acl -Path $using:Path -ErrorAction Stop
					$acl.AddAccessRule($rule)
					$acl | Set-Acl -Path $using:Path -ErrorAction Stop -Confirm:$false
					
					[PSCustomObject]@{
						Success = $true
						Path    = $using:Path
						Rule    = $referenceRule
						Error   = $null
					}
				}
				catch
				{
					[PSCustomObject]@{
						Success = $false
						Path    = $using:Path
						Rule    = $referenceRule
						Error   = $_
					}
				}
			}
			if (-not $result.Success)
			{
				throw "Error: $($result.Error)"
			}
		}
		
		function Remove-AccessRule
		{
			[CmdletBinding()]
			param (
				$Session,
				
				[string]
				$Path,
				
				$AccessRule
			)
			
			$result = Invoke-Command -Session $Session -ScriptBlock {
				function Convert-UintToInt([uint32]$Number) { [System.BitConverter]::ToInt32(([System.BitConverter]::GetBytes($Number)), 0) }
				try
				{
					$referenceRule = $using:AccessRule
					$acl = Get-Acl -Path $using:Path -ErrorAction Stop
					foreach ($rule in $acl.Access)
					{
						if ($rule.IsInherited) { continue }
						if ($rule.IdentityReference.Translate([System.Security.Principal.SecurityIdentifier]).ToString() -ne $referenceRule.IdentityReference.ToString()) { continue }
						if ([int]$rule.FileSystemRights -ne (Convert-UintToInt -Number $referenceRule.FileSystemRightsNumeric)) { continue }
						if ($rule.InheritanceFlags -ne $referenceRule.InheritanceFlags) { continue }
						if ($rule.PropagationFlags -ne $referenceRule.PropagationFlags) { continue }
						if ($rule.AccessControlType -ne $referenceRule.AccessControlType) { continue }
						$null = $acl.RemoveAccessRule($rule)
					}
					$acl | Set-Acl -Path $using:Path -ErrorAction Stop -Confirm:$false
					
					[PSCustomObject]@{
						Success = $true
						Path    = $using:Path
						Rule    = $referenceRule
						Error   = $null
					}
				}
				catch
				{
					[PSCustomObject]@{
						Success = $false
						Path    = $using:Path
						Rule    = $using:AccessRule
						Error   = $_
					}
				}
			}
			if (-not $result.Success)
			{
				throw "Error: $($result.Error)"
			}
		}
		#endregion Functions
	}
	process
	{
		if ($TargetServer) { $parameters.TargetServer = $TargetServer }
		if (-not $InputObject) { $InputObject = Test-DCAccessRule @parameters }
		
		foreach ($testItem in ($InputObject | Sort-Object Type -Descending)) # Delete before Add
		{
			# Catch invalid input - can only process test results
			if ($testItem.PSObject.TypeNames -notcontains 'DCManagement.FSAccessRule.TestResult')
			{
				Stop-PSFFunction -String 'General.Invalid.Input' -StringValues 'Test-DCAccessRule', $testItem -Target $testItem -Continue -EnableException $EnableException
			}
			
			if (-not $psSessions[$testItem.Server])
			{
				try { $psSessions[$testItem.Server] = New-PSSession -ComputerName $testItem.Server @psCred -ErrorAction Stop }
				catch { Stop-PSFFunction -String 'Invoke-DCAccessRule.Access.Error' -StringValues $testItem.Server -Target $testItem -Continue -EnableException $EnableException -ErrorRecord $_ }
			}
			$psSession = $psSessions[$testItem.Server]
			
			switch ($testItem.Type)
			{
				#region Add
				'Add'
				{
					$change = @($testItem.Changed)[0]
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DCAccessRule.AccessRule.Add' -ActionStringValues $change.DisplayName, $change.FileSystemRights, $change.AccessControlType -Target $testItem -ScriptBlock {
						Add-AccessRule -Session $psSession -Path $testItem.Identity -AccessRule $change
					} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
				}
				#endregion Add
				#region Remove
				'Remove'
				{
					$change = @($testItem.Changed)[0]
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DCAccessRule.AccessRule.Remove' -ActionStringValues $change.DisplayName, $change.FileSystemRights, $change.AccessControlType -Target $testItem -ScriptBlock {
						Remove-AccessRule -Session $psSession -Path $testItem.Identity -AccessRule $change
					} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
				}
				#endregion Remove
			}
		}
	}
	end
	{
		$psSessions.Values | Remove-PSSession -Confirm:$false -ErrorAction Ignore
	}
}
