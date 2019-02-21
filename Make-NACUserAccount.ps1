<#
.SYNOPSIS
New-NACUserAccount creates new user accounts and assigns those users to the appropriate users based on their job role.
.DESCRIPTION

.PARAMETER FirstName
The first name (given name) of the user.

.PARAMETER LastName
The last name (surname) of the user.

.PARAMETER RanNum
The randomly assigned four digits to be used with the user's account.

.PARAMETER Division
The organizational division to be used to define OU as well as manager. Selections can be controls, office, sales, service, or specialprojects.

.PARAMETER Manager
If declared, this overrides the manager assigned by $Division declaration.

.PARAMETER Description
If declared, this populates the description field in AD. This field should reflect the user's job title.

.EXAMPLE
.\New-NACUserAccount.ps1 -FirstName 'Chris' -LastName 'Kaufman' -RanNum '1234' -Division 'Sales'

PENDING CHANGES
xDeclare description or job title.
xWait for user creation in Office 365.
xLicense user in Office 365.
Add user groups in Office 365.
Add user to LAN access group, as necessary.
xGrant SharePoint permissions.
Add user information to documentation.
Add user to GoCanvas (if applicable).
Add user to time card (if applicable).
Pass Office 365 credentials, somehow.
Create switch to create a user without licensing.
Set user manager as OneDrive site reader/contributor/something.

#>

# Set parameters.
param (
  [Parameter(Mandatory=$True)]
  [Alias('First')]
  [string]$FirstName,
  [Parameter(Mandatory=$True)]
  [Alias('Last')]
  [string]$LastName,
  [Parameter(Mandatory=$True)]
  [Alias('SSN')]
  [Alias('Date')]
  [int]$FourDigits,
  [Parameter(Mandatory=$True)]
  [ValidateSet("Controls","Office","Sales","Service","SpecialProjects")]
  [string]$Division,
  [Parameter(Mandatory=$False)]
  [string]$Manager,
  [Parameter(Mandatory=$False)]
  [string]$EmployeeNumber,
  [Parameter(Mandatory=$False)]
  [string]$MobilePhone,
  [Parameter(Mandatory=$False)]
  [Alias('JobTitle')]
  [string]$Description
)

# Set other variables.
$UserName = "$FirstName.$LastName"
$UserEmail = "$UserName@nacgroup.com"
$UserTemplate = Get-ADUser -Identity "$Division.Template"
$ManagerCN = Get-ADUser -Identity $UserTemplate -Properties Manager
$ProfilePath = ($UserTemplate.DistinguishedName -split ",",2)[1]

# Initial user account creation.
New-ADUser -SamAccountName $UserName -Name "$FirstName $LastName"

# Set user properties: Description, DisplayName, EmailAddress, EmployeeNumber, GivenName, Manager, MobilePhone, Surname, UserPrincipalName.
Set-ADUser -Identity $Username -Description "$Description"
Set-ADUser -Identity $Username -DisplayName "$FirstName $LastName"
Set-ADUser -Identity $Username -EmailAddress "$UserName@nacgroup.com"
Set-ADUser -Identity $UserName -GivenName $FirstName
Set-ADUser -Identity $UserName -Manager $ManagerCN
Set-ADUser -Identity $UserName -Surname $LastName
Set-ADUser -Identity $UserName -UserPrincipalName "$FirstName.$LastName@nacgroup.com"

# Move to correct OU.
Get-ADUser -Identity $UserName | Move-ADObject -TargetPath $ProfilePath

# Set proxy address(es).
Get-ADUser -Identity $UserName | Set-ADUser -Add @{ProxyAddresses="SMTP:$UserEmail"}

# Reset user password and enable account.
Set-ADAccountPassword -Identity $UserName -Reset
Set-ADUser -Identity $UserName -Enabled $True

# Pull credentials before moving to Office 365.
$MsolCredential = Get-Credential

# Wait for user account to replicate to Azure AD.
Write-Host "Pushing information to Microsoft Online..."
Start-Sleep -Seconds 900

## Move to Office 365.
# Sourced from https://docs.microsoft.com/en-us/powershell/azure/active-directory/enabling-licenses-sample?view=azureadps-2.0 on 11 Jan 2019.
Connect-MsolService -Credential $MsolCredential
Connect-AzureAD -Credential $MsolCredential

# User first needs to be assigned a region, then a license.
$AzureUserName = Get-AzureADUser -SearchString $UserName
Set-AzureADUser -ObjectId $AzureUserName.ObjectId -UsageLocation US
$LicenseSku = Get-AzureADSubscribedSku | Where-Object {$_.SkuPartNumber -eq 'O365_BUSINESS_PREMIUM'}
$License = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicense
$License.SkuId = $LicenseSku.SkuId
$AssignedLicenses = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses
$AssignedLicenses.AddLicenses = $License
Set-AzureADUserLicense -ObjectId $AzureUserName.ObjectId -AssignedLicenses $AssignedLicenses

<# Add the user to the relevant groups.
### This is on hold as Microsoft does not currently support updating to non-Office 365 groups.
#########################
$AzureDistributionLists = "company@nacgroup.com","nac@nacgroup.com","$Division@nacgroup.com"
ForEach-Object ($_.List -in $AzureDistributionLists) {
$ListId = Get-AzureADGroup -SearchString $List
Add-AzureADGroupMember -ObjectId $ListId.ObjectId -RefObjectId $AzureUserName.ObjectId
}
#>

# Add new user to the relevant SharePoint site(s) and libraries.
Connect-SPOService -Url https://nacgroup-admin.sharepoint.com -Credential $MsolCredential
Add-SPOUser -Site https://nacgroup.sharepoint.com -LoginName $UserName -Group "Team Site Members"
