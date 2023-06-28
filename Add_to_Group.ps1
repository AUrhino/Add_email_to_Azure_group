<#
.SYNOPSIS
  This script will:
   * Connect to Azure
   * Prompt for user's email
   * Build a menu of Azure groups
   * Add to user to the LM AZ group.
  
.DESCRIPTION
  This should run from a host that can connect to Azure via Powershell
  
.INPUTS
  Will prompt user and will connect to AD and set user with groups  
  Will prompt for email and allow you to enter the number of the group you want.

.OUTPUTS
  Will write Email and groups to the screen.

.NOTES
  Author:         Ryan Gillan
  Creation Date:  28-Jun-2023
  1.0  live version
  
   To get a list of Azure groups, use the following:
     Connect-AzureAD
     Get-AzureADGroup -Filter "startswith(Displayname, 'AU.Sec.G.What.Ever')" |select DisplayName

.EXAMPLE
   get-help .\Add_to_Group.ps1
  
  #Run via:
  .\Add_to_Group.ps1

.LINK
    This file has been added to github. Log issues there.

#>
#=================================================================================================

# Check if AzureAD module is installed
try {
  $azureADModule = Get-Module -Name AzureAD -ListAvailable
  if ($azureADModule) {
    Write-Host "AzureAD module is installed."
    }
  else {
    Write-Host "AzureAD module is not installed. Installing..." -ForegroundColor Red
    # Install the AzureAD module
    Install-Module -Name AzureAD -Force -AllowClobber
    Write-Host "AzureAD module installed successfully." -ForegroundColor Green
    }
}
catch {
  Write-Host "An error occurred: $($_.Exception.Message)" -ForegroundColor Red
  }

#Clear the screen
Clear-Host

# Connect to Azure AD
Connect-AzureAD

# Set the user's email address
$userEmailAddress = Read-Host -Prompt 'Enter the users email address: '
Write-Host "Entered: $userEmailAddress"  -ForegroundColor Yellow
read-host "Press ENTER to continue or ctrl + c to kill this script."

# Get the group by display name
#$groupName = "AU.Sec.G.What.Ever"
#$group = Get-AzureADGroup -Filter "DisplayName eq '$groupName'"
Write-Host "==========================================="
Write-Host "Displaying the LM group options"
$grouplist = Get-AzureADGroup -Filter "startswith(Displayname, 'AU.Sec.G.NTT.LM')"
# Display the menu of groups
Write-Host "Select a group to add to:"
for ($i = 0; $i -lt $grouplist.Count; $i++) {
    Write-Host ("{0}. {1}" -f ($i + 1), $grouplist[$i].DisplayName)
}
# Prompt for the group selection
$selection = Read-Host "Enter the number of the group to add the user to."
# Validate the selection
if ($selection -ge 1 -and $selection -le $grouplist.Count) {
    $selectedGroup = $grouplist[$selection - 1]  
    Write-Host "User '$userEmailAddress' will be added to group '$($selectedGroup.DisplayName)'."
    Write-Host "$selectedGroup.DisplayName"
}
else {
    Write-Host "Invalid selection. Please try again."
}
Write-Host "==========================================="
#$group = Read-Host -Prompt 'Enter a group from the above list to add the user: '
#Write-Host "Will add: $userEmailAddress to $groupname"

if ($selectedGroup.DisplayName -eq $null) {
    Write-Host "Group '$selectedGroup.DisplayName' not found or you do not have access under your subscription." -ForegroundColor Red
} else {
    # Get the user by email address
    $user = Get-AzureADUser -Filter "UserPrincipalName eq '$userEmailAddress'"
    
    if ($user -eq $null) {
        Write-Host "The user: '$userEmailAddress' was not found." -ForegroundColor Red
    } else {
        # Add the user to the group
        #Add-AzureADGroupMember -ObjectId $group.ObjectId -RefObjectId $user.ObjectId
        Add-AzureADGroupMember -ObjectId $selectedGroup.ObjectId -RefObjectId $user.ObjectId
        Write-Host "User '$userEmailAddress' added to group '$selectedGroup.DisplayName'' successfully."
    }
}

Write-Host "==========================================="
Write-Host "`nPost addition work."-ForegroundColor Green
Write-Host "`nThe email: $userEmailAddress' should have been added to the group. Checking....."-ForegroundColor Green

$groupMembers = Get-AzureADGroupMember -ObjectId $selectedGroup.ObjectId | Select-Object -ExpandProperty UserPrincipalName
if ($groupMembers -contains $userEmailAddress) {
  Write-Host "The email: $userEmailAddress' is a member of the group."-ForegroundColor Green
  } else {
  Write-Host "The email: '$userEmailAddress' is NOT a member of the group." -ForegroundColor RED
}

# Disconnect from Azure AD
Disconnect-AzureAD

# EOF
