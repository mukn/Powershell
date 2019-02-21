$Creds = Get-Credential
$Session = New-PsSession -configurationname Microsoft.Exchange -Connectionuri https://ps.outlook.com/powershell-liveid?PSVersion=4.0/ -credential $Creds -Authentication Basic -AllowRedirection
Import-PSSession $Session
