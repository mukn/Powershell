﻿<#
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
xAdd user groups in Office 365.
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

# I Set the email address outside the function simply because it will have to be passed between multiple functions
$global:UserEmail = $FirstName + "." + $LastName + "@nacgroup.com"

<#due to using functions, variables will get passed both into and out of functions.#>

function Create-LocalUser (
[string]$FirstName,
[string]$LastName,
[int]$FourDigits,
[string]$Division,
[string]$Manager,
[string]$EmployeeNumber,
[string]$MobilePhone,
[string]$Description,
$UserEmail) {

# Combine the variables as needed and add info where needed to complete the formatting (edited for clarity)
$UserName = "$FirstName.$LastName"
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

Write-Host "Pushing information to Microsoft Online..."

# Sync the newly created user to Office 365 and Azure AD
start-adsyncsynccycle -policytype delta

start-sleep -Seconds 30
}

<#
 test to see if the user exists
# if the user does not exist then return to the top of the statement 
# and wait before testing

# Wrap all post sync commands into a function that is itself wrapped in an if statement. 
# This will allow us to loop back if the user is not yet synced 
#>

function Check-User {
# This funtion will check if you want to have the user be licensed and then license the user if need be
# Check to see if this is the first run of the function by checking for a value for in $LicensingInput 
if ($LicensingInput -ne $Null){
Write-Host "Do you want the user to be licensed? (y/n)"
$LicensingInput = Read-Host
}

# Run the check of if the user is going to be licensed.
if ($LicensingInput -eq "y") {
    #If the answer was y then proceed with licensing
    if ((Get-MsolUser -UserPrincipalName $UserEmail) -ne $Null)
        {
        # User first needs to be assigned a region, then a license.
        $AzureUserName = Get-AzureADUser -SearchString $UserName
        Set-AzureADUser -ObjectId $AzureUserName.ObjectId -UsageLocation US
        $LicenseSku = Get-AzureADSubscribedSku | Where-Object {$_.SkuPartNumber -eq 'O365_BUSINESS_PREMIUM'}
        $License = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicense
        $License.SkuId = $LicenseSku.SkuId
        $AssignedLicenses = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses
        $AssignedLicenses.AddLicenses = $License
        Set-AzureADUserLicense -ObjectId $AzureUserName.ObjectId -AssignedLicenses $AssignedLicenses
        } 
            else {
            start-sleep -Seconds 300
            Check-User
            }

} 
#if the answer was no, exit the function without any further steps
    elseif ($LicensingInput -eq "n") 
    {
    }
        # If the response was not y or n, tell the user to enter y or n and then begin the loop after the intital question again
        else 
        {
        Write-Host 'Invalid Response. Please enter "y" or "n"'
        Check-User
        }
# Exit Function
}

function Connect-Office365 {

# Pull credentials before moving to Office 365.
$MsolCredential = Get-Credential

#Connect to cloud services
# Sourced from https://docs.microsoft.com/en-us/powershell/azure/active-directory/enabling-licenses-sample?view=azureadps-2.0 on 11 Jan 2019.
Connect-MsolService -Credential $MsolCredential
Connect-AzureAD -Credential $MsolCredential
Connect-SPOService -Url https://nacgroup-admin.sharepoint.com -Credential $MsolCredential

$Session = New-PsSession -configurationname Microsoft.Exchange -Connectionuri https://ps.outlook.com/powershell-liveid?PSVersion=4.0/ -credential $Creds -Authentication Basic -AllowRedirection
Import-PSSession $Session

}

function AddTo-Sharepoint {
Add-SPOUser -Site https://nacgroup.sharepoint.com -LoginName $UserName -Group "Team Site Members"
}

function AddTo-Groups ([string]$Division){
#import the Division from the parameters
#Pull list of the groups, extract the displayname property and store that inside a variable

$365Group = get-unifiedgroup | where {$_.DisplayName -match $Division} | select DisplayName

#While the variable itself is a PSCustomObject typ the property inside is a system.string type so we dont need to convert

Add-UnifiedGroupLinks -Identity $365Group.DisplayName -Links $UserEmail -LinkType Members


}


# Call the functions individually
Connect-Office365

Create-LocalUser

Check-User

AddTo-Sharepoint

AddTo-Groups

<#
Josh List todo
xCreate user without licensing
(on hold)set manager of user as the admin/editor/reviewer
xAdd users to office 365 groups. Based on Division Variable
LAN Access group is based on anyone who accesses reports from sql. LAN-Access
Adding user info to documentation (csv) and username,password
 

Long Term:
GoCanvas is made by GoCanvas API
TimeCard has a reference datasheet. Wants info that requires an API call


#>
