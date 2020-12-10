<#

########################################################################################################################################################################
#       Script: Remove-NestedGroups.ps1
#       Author: Jason Dance
#       Date: Jan 28, 2020
#       Description: This script can be used to transfer the content of one group to another.
#                    Pick a group from the list presented, and the script will pull the users from the source group and add them to the target group.
#       Usage: Just run the script in Powershell or Powershell ISE. No arguments or switches are needed, just run the script and answer the prompts.
########################################################################################################################################################################

#>

$GroupCategorySource= (("Distribution","Security") | Out-GridView -Title "Select a group type for the source:" -OutputMode Single)

If (!$GroupCategorySource){
write-host("No type value selected") -BackgroundColor DarkRed
break}

$FromGroup = (Get-ADGroup -Filter 'GroupCategory -eq $GroupCategorySource') | sort | Out-GridView -Title "Select a group to pull users from:" -OutputMode Multiple


$GroupCategoryTarget= (("Distribution","Security") | Out-GridView -Title "Select a group type for the target:" -OutputMode Single)

If (!$GroupCategoryTarget){
write-host("No type value selected") -BackgroundColor DarkRed
break}

$ToGroup = (Get-ADGroup -Filter 'GroupCategory -eq $GroupCategoryTarget') | sort | Out-GridView -Title "Select a target group:" -OutputMode Multiple

If (!$ToGroup -or !$FromGroup){
write-host("No group value selected") -BackgroundColor DarkRed
break}


$users = Get-ADGroupMember -Id $FromGroup | select  @{Expression={$FromGroup};Label="Group Name"},SamAccountName

foreach ($user in $users){
write-host $user
Add-ADGroupMember -Identity $ToGroup -Members $user
}

