<#
Taken from https://stackoverflow.com/questions/50411539/retrieving-bitlocker-recovery-keys-from-ad
#>

$TestOU = "OU=ABC,DC=XYZ,DC=com"
$PCs = Get-ADComputer -Filter * -SearchBase $TestOU
$Results = ForEach ($Computer in $PCs) {
	New-Object PSObject -Property 
		@{
			ComputerName = $Computer.Name
			RecoveryPassword = Get-ADObject -Filter 'objectclass -eq "msFVE-RecoveryInformation"' -SearchBase $computer.DistinguishedName -Properties msFVE-RecoveryPassword,whencreated | sort whencreated -Descending | select -expandProperty msfve-recoverypassword
		}
	}
$Results
