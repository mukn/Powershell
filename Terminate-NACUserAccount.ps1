<#

Tasks to accomplish:
 - Change password to random value
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
  $Preserve
)

# Get the Office 365 credentials for the administrator that is deleting the user.
$Admin365Credentials = Get-Credential
# Insert read-host 
Connect-MsolService -Credential $Admin365Credentials
Connect-AzureAD -Credential $Admin365Credentials
Connect-SPOService -Url https://nacgroup-admin.sharepoint.com -Credential $Admin365Credentials

# Pull $Username and associated properties.
Get-ADUser -Identity $UserName -Properties *
# Get manager.
$UserManager = Get-ADUser -Identity $Username -Properties * | Select-Object -ExpandProperty Manager
# Get home folder.
$UserHomeDirectory = Get-ADUser -Identity sean.knight -Properties * | Select-Object -ExpandProperty HomeDirectory
# Get group membership.

