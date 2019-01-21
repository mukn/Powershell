<#

.SYNOPSIS
Disable-NACUserAccount is used when a user is terminated. It goes through several steps to lock the former user out of network resources, to backup important information, and to close accounts.

.DESCRIPTION
Disable-NACUserAccount goes through several steps.
  1) Resets the user's password.
  2) Sends a message to the user's supervisor.
  3) Archives both the user's mailbox and personal folders.
  4) Removes the user account from the various groups it is a member of.
  5) Removes the user account from any SharePoint sites.
  6) Reclaims licenses from Barracuda, Office 365, GoCanvas, SalesForce, and other resources.
  7) Identifies any devices that still need to be recovered.
  8) Forwards any other relevant information to the user's manager for review.
  9) Disables the user account and moves the user object to the appropriate OU.



.PARAMETER

.EXAMPLE

#>
