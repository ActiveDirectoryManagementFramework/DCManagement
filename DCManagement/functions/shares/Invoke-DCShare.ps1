function Invoke-DCShare
{
<#
	.SYNOPSIS
		Brings all network shares on all DCs in the domain into the desired state.
	
	.DESCRIPTION
		Brings all network shares on all DCs in the domain into the desired state.
		Use Register-DCShare (or an ADMF Context) to define the desired state.
	
	.PARAMETER InputObject
		Individual test results to process.
		Only accepts the output of Test-DCShare.
	
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
		PS C:\> Invoke-DCShare -Server contoso.com
	
		Tests all DCs in contoso.com, validating that their network shares are as configured, correcting any deviations.
#>
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(ValueFromPipeline = $true)]
		$InputObject,
		
		[PSFComputer]
		$Server,

        [string[]]
        $TargetServer,
		
		[PSCredential]
		$Credential,
		
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
		Assert-Configuration -Type Shares -Cmdlet $PSCmdlet
		Set-DCDomainContext @parameters
		
		$cimCred = $PSBoundParameters | ConvertTo-PSFHashtable -Include Credential
		
		$cimSessions = @{ }
	}
	process
	{
        if ($TargetServer) { $parameters.TargetServer = $TargetServer }
		if (-not $InputObject) { $InputObject = Test-DCShare @parameters }
		
		foreach ($testItem in $InputObject)
		{
			# Catch invalid input - can only process test results
			if ($testItem.PSObject.TypeNames -notcontains 'DCManagement.Share.TestResult')
			{
				Stop-PSFFunction -String 'General.Invalid.Input' -StringValues 'Test-DCShare', $testItem -Target $testItem -Continue -EnableException $EnableException
			}
			
			if (-not $cimSessions[$testItem.Server])
			{
				try { $cimSessions[$testItem.Server] = New-CimSession -ComputerName $testItem.Server @cimCred -ErrorAction Stop }
				catch { Stop-PSFFunction -String 'Invoke-DCShare.Access.Error' -StringValues $testItem.Server -Target $testItem -Continue -EnableException $EnableException -ErrorRecord $_ }
			}
			$cimSession = $cimSessions[$testItem.Server]
			
			switch ($testItem.Type)
			{
				#region New Share
				'New'
				{
					$newShareParam = @{
						CimSession = $cimSession
						Name	   = $testItem.Configuration.Name
						Path	   = $testItem.Configuration.Path
						ErrorAction = 'Stop'
						WhatIf	   = $false
						Confirm    = $false
					}
					if ($testItem.Configuration.Description) { $newShareParam.Description = $testItem.Configuration.Description }
					$grantParam = @{
						ComputerName = $testItem.Server
						Name		 = $testItem.Configuration.Name
					}
					$grantParam += $cimCred
					
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DCShare.Share.Create' -ActionStringValues $testItem.Identity -Target $testItem -ScriptBlock {
						$null = New-SmbShare @newShareParam
						foreach ($identity in $testItem.Configuration.FullAccess) { Grant-ShareAccess @grantParam -Identity $identity -AccessRight Full }
						foreach ($identity in $testItem.Configuration.WriteAccess) { Grant-ShareAccess @grantParam -Identity $identity -AccessRight Change }
						foreach ($identity in $testItem.Configuration.ReadAccess) { Grant-ShareAccess @grantParam -Identity $identity -AccessRight Read }
					} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
				}
				#endregion New Share
				#region Update
				'Update'
				{
					if ($testItem.Changed -contains 'Path')
					{
						$newShareParam = @{
							CimSession = $cimSession
							Name	   = $testItem.Configuration.Name
							Path	   = $testItem.Configuration.Path
							ErrorAction = 'Stop'
							WhatIf	   = $false
							Confirm    = $false
						}
						if ($testItem.Configuration.Description) { $newShareParam.Description = $testItem.Configuration.Description }
						$grantParam = @{
							ComputerName = $testItem.Server
							Name		 = $testItem.Configuration.Name
						}
						$grantParam += $cimCred
						
						Invoke-PSFProtectedCommand -ActionString 'Invoke-DCShare.Share.Migrate' -ActionStringValues $testItem.Identity -Target $testItem -ScriptBlock {
							$null = Remove-SmbShare -Name $testItem.Configuration.Name -CimSession $cimSession
							$null = New-SmbShare @newShareParam
							foreach ($identity in $testItem.Configuration.FullAccess) { Grant-ShareAccess @grantParam -Identity $identity -AccessRight Full }
							foreach ($identity in $testItem.Configuration.WriteAccess) { Grant-ShareAccess @grantParam -Identity $identity -AccessRight Change }
							foreach ($identity in $testItem.Configuration.ReadAccess) { Grant-ShareAccess @grantParam -Identity $identity -AccessRight Read }
						} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
					}
					else
					{
						$setShareParam = @{
							CimSession = $cimSession
							Name	   = $testItem.Configuration.Name
							ErrorAction = 'Stop'
							WhatIf	   = $false
							Confirm    = $false
						}
						if ($testItem.Configuration.Description) { $setShareParam.Description = $testItem.Configuration.Description }
						
						Invoke-PSFProtectedCommand -ActionString 'Invoke-DCShare.Share.Update' -ActionStringValues $testItem.Identity -Target $testItem -ScriptBlock {
							Set-SmbShare @setShareParam
						} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
					}
				}
				#endregion Update
				#region Update Access Rules
				'AccessUpdate'
				{
					foreach ($accessEntry in $testItem.Changed)
					{
						Invoke-PSFProtectedCommand -ActionString 'Invoke-DCShare.Share.UpdateAccess' -ActionStringValues $testItem.Identity, $accessEntry.Action, $accessEntry.Identity, $accessEntry.AccessRight -Target $testItem -ScriptBlock {
							if ($accessEntry.Action -eq 'Add') { Grant-ShareAccess -ComputerName $testItem.Server @cimCred -Name $testItem.Configuration.Name -Identity $accessEntry.Identity -AccessRight $accessEntry.AccessRight }
							else { Revoke-ShareAccess -ComputerName $testItem.Server @cimCred -Name $testItem.Configuration.Name -Identity $accessEntry.Identity -AccessRight $accessEntry.AccessRight }
						} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
					}
				}
				#endregion Update Access Rules
				#region Delete Share
				'Delete'
				{
					Invoke-PSFProtectedCommand -ActionString 'Invoke-DCShare.Share.Delete' -ActionStringValues $testItem.Identity -Target $testItem -ScriptBlock {
						$null = Remove-SmbShare -Name $testItem.ADObject.Name -CimSession $cimSession -WhatIf:$false -Confirm:$false
					} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
				}
				#endregion Delete Share
			}
		}
	}
	end
	{
		$cimSessions.Values | Remove-CimSession -ErrorAction Ignore -Confirm:$false -WhatIf:$false
	}
}
