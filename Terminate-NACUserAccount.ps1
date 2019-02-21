<#

Tasks to accomplish:
 x Change password to random value
 - Write new password value to some location (for manager to review data)
 - Disable mail logon
 - Remove from Office 365 groups
 - Remove from SharePoint access
 - Download a copy of mailbox
 - Download a copy of OneDrive
 - Download a copy of user account on assigned computer(s)
 - Archive all to a cool storage location
 - Set mail forward to manager for 30 days
 - After 15 days, send warning message to manager
 - After 30 days, reclaim assigned licenses
 - After 45 days, mark AD account for deletion (in description field)
 - After 60 days, delete the account
 - Report steps by email to helpdesk and former manager throughout the process

Extras:
  - Reclaim GoCanvas license (as necessary)
  - Reclaim Barracuda license
  - Remove user from GAL
  - Send message to wireless plan manager

#>

# Set parameters.
param (
  [Parameter(Mandatory=$True)]
  [string]$Username,
  [Parameter(Mandatory=$False)]
  $Preserve=$False
)

<# Functions in the script.DESCRIPTION
Function Send-EmailMessage () {
  param (
    [Parameter(Mandatory=$False)]
    [string]$Recipients="helpdesk@nacgroup.com",
    [Parameter(Mandatory=$False)]
    [string]$ReportTitle,
    [Parameter(Mandatory=$False)]
    [string]$HTMLContent
  )

  #region Variables and Arguments
  $fromemail = "noyes-information@nacgroup.com"
  $server = "smtp.office365.com" #enter your own SMTP server DNS name / IP address here

  #Internal settings for email.
  $SourceMailbox = "noyes-information@nacgroup.com"
  $ReceiveMailbox = "$UserManagerEmail"
  $SourceMailboxPasswordSecure = ".\001Ref-SecureString.txt"
  $Creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $SourceMailbox,(Get-Content $SourceMailboxPasswordSecure | ConvertTo-SecureString)
  $ReportTitle = "User account terminated ($UserName)"

  #endregion

  # Assemble the HTML Header and CSS for our Report
  $HTMLHeader = @"
  <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">
  <html><head><title>$ReportTitle</title>
  <style type="text/css">
  <!--
  body {
  font-family: Verdana, Geneva, Arial, Helvetica, sans-serif;
  }

      #report { width: 835px; }

      table{
  	border-collapse: collapse;
  	border: none;
  	font: 10pt Verdana, Geneva, Arial, Helvetica, sans-serif;
  	color: black;
  	margin-bottom: 10px;
  }

      table td{
  	font-size: 12px;
  	padding-left: 0px;
  	padding-right: 20px;
  	text-align: left;
  }

      table th {
  	font-size: 12px;
  	font-weight: bold;
  	padding-left: 0px;
  	padding-right: 20px;
  	text-align: left;
  }

  h2{ clear: both; font-size: 130%; }

  h3{
  	clear: both;
  	font-size: 115%;
  	margin-left: 20px;
  	margin-top: 30px;
  }

  p{ margin-left: 20px; font-size: 12px; }

  table.list{ float: left; }

      table.list td:nth-child(1){
  	font-weight: bold;
  	border-right: 1px grey solid;
  	text-align: right;
  }

  table.list td:nth-child(2){ padding-left: 7px; }
  table tr:nth-child(even) td:nth-child(even){ background: #CCCCCC; }
  table tr:nth-child(odd) td:nth-child(odd){ background: #F2F2F2; }
  table tr:nth-child(even) td:nth-child(odd){ background: #DDDDDD; }
  table tr:nth-child(odd) td:nth-child(even){ background: #E5E5E5; }
  div.column { width: 320px; float: left; }
  div.first{ padding-right: 20px; border-right: 1px  grey solid; }
  div.second{ margin-left: 30px; }
  table{ margin-left: 20px; }
  -->
  </style>
  </head>
  <body>

  @

  # Create HTML body for the report.
  $HTMLMiddle = "The password for $UserName was reset to $PlainPassword. Please log into the user mailbox (https://outlook.office.com) and OneDrive to identify any data that needs immediate attention. Mail will be forwarded to you for 30 days. After 30 days, the account will be marked for deletion. After 60 days, the account will be deleted."

  # Assemble the closing HTML for our report.
  $HTMLEnd = @
  </div>
  </body>
  </html>
  @

  # Assemble the final report from all our HTML sections
  $HTMLmessage = $HTMLHeader + $HTMLContent + $HTMLMiddle + $HTMLEnd
  # Save the report out to a file in the current path
  $HTMLmessage | Out-File ((Get-Location).Path + "\report.html")
  # Email our report out
  Send-MailMessage -To $ReceiveMailbox,$Recipients -Subject "[Report] $ReportTitle" -BodyAsHTML -Body $HTMLmessage -Attachments $ListOfAttachments -UseSsl -Port 587 -SmtpServer smtp.office365.com -From $SourceMailbox -Credential $Creds
}
#>

Function Get-Password () {
  param (
    [int]$Length=12,
    [string[]]$SourceData
  )
  For ($Loop = 1; $Loop -le $Length; $Loop++) {
    $Password += ($SourceData | Get-Random)
  }
  return $Password
}

# Reset user password to random value. First create a random password.
# Taken from https://blogs.technet.microsoft.com/heyscriptingguy/2013/06/03/generating-a-new-password-with-windows-powershell/
$SourceData = $NULL; For ($a = 48; $a –le 122; $a++) { $SourceData+=, [char][byte]$a }
$PlainPassword = Get-Password -Length 12 -SourceData $SourceData
# Convert password to secure string.
$SecurePassword = ConvertTo-SecureString $PlainPassword -AsPlainText -Force
# Set user password to the returned password.
Set-ADAccountPassword -Identity $UserName -NewPassword $SecurePassword

# Get the Office 365 credentials for the administrator that is deleting the user.
$Admin365Credentials = Get-Credential
# Insert read-host
# Connect to Microsoft cloud resources.
Connect-MsolService -Credential $Admin365Credentials
Connect-AzureAD -Credential $Admin365Credentials
# $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $Admin365Credentials -Authentication Basic -AllowRedirection
# Import-PSSession $Session -DisableNameChecking
Connect-SPOService -Url https://nacgroup-admin.sharepoint.com -Credential $Admin365Credentials

# Pull $Username and associated properties.
$UserProperties = Get-ADUser -Identity $UserName -Properties *
# Get manager.
$UserManager = $UserProperties.Manager
$UserManagerEmail = Get-ADUser -Identity $UserManager | Select-Object -ExpandProperty UserPrincipalName
# Get home folder.
$UserHomeDirectory = $UserProperties.HomeDirectory
# Get group membership.
$UserGroups = $UserProperties.MemberOf
# Get email.
$UserEmail = $UserProperties.UserPrincipalName

## Start actions.
# Remove user from local AD groups.
Foreach ( $Group in $UserGroups ) {
  Remove-ADGroupMember -Identity $Group -Members $UserName
}
# Move to Office 365 and remove user from groups.

# Remove user from GAL.
# There is no Connect-ExchangeOnline cmdlt at this point and no method of
# opening a nested PSSession per below. Removal from GAL is manual at this point.
# Enter-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $Admin365Credentials -Authentication Basic -AllowRedirection
# Forward email messages to user's manager.

# Remove from SharePoint sites.
Remove-SPOUser -LoginName $UserEmail -Site https://nacgroup.sharepoint.com
# Send messages to third-party wireless manager and help desk for tracking.



## Follow up actions.
# After 15 days, send a warning message to user's manager to review before deletion date.
# Send-EmailMessage

# After 30 days, remove Office 365 license.
# User first needs to be assigned a region, then a license.
Set-MsolUserLicense -UserPrincipalName $UserEmail -RemoveLicenses "nacgroup:O365_BUSINESS_PREMIUM"
# After 45 days, mark account for deletion in local AD.

# After 60 days, delete the account.

## Reporting.
# Send pertinent information to help desk and user manager.
