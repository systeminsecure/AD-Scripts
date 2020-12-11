<#

########################################################################################################################################################################
#       Script: Remove-NestedGroups.ps1
#       Author: Jason Dance
#       Date: Jan 28, 2020
#       Last Updated: Dec 11, 2020
#       Description: This script can be essentially used to "de-nest" your groups!
#                    Pick a group from the list presented, and the script will pull users from nested groups in the original, and add the users to the group you picked. 
#                    This will also pull users from groups nested in the nested groups and add them to the original group you picked.
#       Usage: Just run the script in Powershell or Powershell ISE. No arguments or switches are needed, just run the script and answer the prompts.
########################################################################################################################################################################

#>

import-module activedirectory

If (!(Get-Module ActiveDirectory)){
write-host("Not able to load the Active Directory powershell module (is it installed?)   https://theitbros.com/install-and-import-powershell-active-directory-module") -BackgroundColor DarkRed
break}

$GroupCategory= (("Distribution","Security") | Out-GridView -Title "Select a group type:" -OutputMode Single)

If (!$GroupCategory){
write-host("No value selected") -BackgroundColor DarkRed
break}

$TargetGroups = (Get-ADGroup -Filter 'GroupCategory -eq $GroupCategory') | sort | Out-GridView -Title "Select a group:" -OutputMode Multiple

If (!$TargetGroups){
write-host("No value selected") -BackgroundColor DarkRed
break}

$GroupDelete= (("$False","$True") | Out-GridView -Title "Remove nested groups from $($TargetGroups)?" -OutputMode Single)


foreach($TargetGroup in $TargetGroups){
$pass=0
$groupctrcmp=0
$groupctr = 0

do{
        $pass += 1
        $groupctrcmp = $groupctr
        $groupctr = 0
        $Members=$null
        ForEach ($Member in Get-ADGroupMember -Identity $TargetGroup) {
            if ($Member.objectclass -eq 'group') {
                $Members += "          $($Member.name)`r`n"
            }

        }
            if ($Members){
                write-host ("`r`nPass $Pass, $(($TargetGroup).name): found these nested groups:-") -BackgroundColor Yellow -ForegroundColor Black

                        ForEach ($Member in Get-ADGroupMember -Identity $TargetGroup) {
                            
                            if ($Member.objectclass -eq 'group') {
                                write-host (">> $($Member.objectClass): $($Member.name)") -BackgroundColor Yellow -ForegroundColor Black
                                
                                ForEach ($SubMember in Get-ADGroupMember -Identity $Member.Name) {
                                        Add-ADGroupMember -Identity $TargetGroup -Members $SubMember.SamAccountName -Confirm:$FALSE #-whatif  #<===--- Remove "-whatif" to apply the actual changes
                                        If ($SubMember.objectClass -eq "user") {
                                                
                                                write-host ("  >> Add $($SubMember.objectClass): $($SubMember.name)") -BackgroundColor Cyan -ForegroundColor DarkBlue
                                                }
                                        If ($SubMember.objectClass -eq "group") {
                                        $groupctr += 1
                                                write-host ("  >> Add nested $($SubMember.objectClass): $($SubMember.name)") -BackgroundColor DarkYellow -ForegroundColor Black
                                                }
                                }
                                if ($GroupDelete -eq "True") {
                               write-host (">> Remove $($Member.objectClass): $($Member.name)") -BackgroundColor Gray -ForegroundColor Black
                               Remove-ADGroupMember -Identity $TargetGroup -Members $Member -Confirm:$FALSE #-whatif  #<===--- Remove "-whatif" to apply the actual changes
                               }
                               
                            }
                }
            }
            else{
            write-host ("$(($TargetGroup).name): no nested groups") -BackgroundColor Green -ForegroundColor DarkBlue
            }
    write-host ("`r`nPausing to let Active Directory catch up....") -BackgroundColor DarkCyan -ForegroundColor Blue
    sleep 5

    } while ( (($GroupDelete -eq "True") -and (Get-ADGroupMember -Identity $TargetGroup | where {$_.objectClass -eq 'group'}).name.count -gt 0) -or (($GroupDelete -ne "True") -and ($groupctr -ne $groupctrcmp)) )  # 


}
