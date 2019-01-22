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

# Reset user password to random value. First create a random password.
# Taken from https://blogs.technet.microsoft.com/heyscriptingguy/2013/06/03/generating-a-new-password-with-windows-powershell/
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
$SourceData = $NULL; For ($a = 48; $a –le 122; $a++) { $SourceData+=, [char][byte]$a }
$PlainPassword = Get-Password -Length 12 -SourceData $SourceData
# Convert password to secure string.
$SecurePassword = ConvertTo-SecureString $PlainPassword -asplaintext -force
# Set user password to the returned password.
Set-ADAccountPassword -Identity $UserName -NewPassword $SecurePassword

# Get the Office 365 credentials for the administrator that is deleting the user.
$Admin365Credentials = Get-Credential
# Insert read-host
# Connect to Microsoft cloud resources.
Connect-MsolService -Credential $Admin365Credentials
Connect-AzureAD -Credential $Admin365Credentials
Connect-SPOService -Url https://nacgroup-admin.sharepoint.com -Credential $Admin365Credentials

# Pull $Username and associated properties.
$UserProperties = Get-ADUser -Identity $UserName -Properties *
# Get manager.
$UserManager = $UserProperties.Manager
# Get home folder.
$UserHomeDirectory = $UserProperties.HomeDirectory
# Get group membership.
$UserGroups = $UserProperties.MemberOf
# Get email.
$UserEmail = $UserProperties.UserPrincipalName

## Start actions.
# Remove user from local AD groups.

# Remove user from GAL.

# Move to Office 365 and remove user from groups.

# Forward email messages to user's manager.

# Remove from SharePoint sites.

# Send message to third-party wireless manager and help desk for tracking.



## Follow up actions.
# After 15 days, send a warning message to user's manager to review before deletion date.

# After 30 days, remove Office 365 license.

# After 45 days, mark account for deletion in local AD.

# After 60 days, delete the account.

## Reporting.
# Send pertinent information to help desk and user manager.
