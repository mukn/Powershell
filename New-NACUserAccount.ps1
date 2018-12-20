<#
.SYNOPSIS
New-NACUserAccount creates new user accounts and assigns those users to the appropriate users based on their job role.
.DESCRIPTION

.PARAMETER FirstName
The first name (given name) of the user.

.PARAMTER LastName
The last name (surname) of the user.

.PARAMETER RanNum
The randomly assigned four digits to be used with the user's account.

.PARAMETER Division
The organizational division to be used to define OU as well as manager. Selections can be: office, const, servi, sales.

.PARAMETER Manager
If declared, this overrides the manager assigned by $Division declaration.

.EXAMPLE
.\New-NACUserAccount.ps1 -FirstName 'Chris' -LastName 'Kaufman' -RanNum '1234' -Division 'Sales'

PENDING CHANGES
Wait for user creation in Office 365.
License user in Office 365.
Add user groups in Office 365.
Grant SharePoint permissions.

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
  [string]$Division,
  [Parameter(Mandatory=$False)]
  [string]$Manager,
  [Parameter(Mandatory=$False)]
  [string]$EmployeeNumber,
  [Parameter(Mandatory=$False)]
  [string]$MobilePhone
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
Set-ADUser -Identity $Username -Description "$Division"
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
