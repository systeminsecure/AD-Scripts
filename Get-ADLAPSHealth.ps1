<#
Script used to grab the last updated time from the LAPS attribute in AD for servers. 
This is good to see which machines have a broken/misconfigured LAPS client
systeminsecure 2023-08-01 v4
#>

$PWChangeTolerance = 3 #Days - any pw expiry with age greater than this value will fail

$NearestDC = $((Get-ADDomainController -Discover).hostname)
$servers = Get-ADComputer -Server $NearestDC -Filter "OperatingSystem -Like '*Windows Server*' -and Enabled -eq 'True' -and servicePrincipalName -notlike '*MSClusterVirtualServer*' -and servicePrincipalName -notlike '*GC/*'" -Properties DNSHostName,ms-mcs-AdmPwd,ms-Mcs-AdmPwdExpirationTime,lastLogonTimestamp,Enabled,Samaccountname `
| Select @{Name="DNSHostName"; Expression = {$_.DNSHostName}}, @{Name="AdmPwd"; Expression = {$_.'ms-mcs-AdmPwd'}}, @{Name="AdmPwdExpirationTime"; Expression = {$([datetime]::FromFileTime([convert]::ToInt64($_.'ms-MCS-AdmPwdExpirationTime',10)))}},@{Name="lastLogonTimestamp"; Expression = {$([datetime]::FromFileTime([convert]::ToInt64($_.'lastLogonTimestamp',10)))}},Enabled,Samaccountname `
| sort ms-Mcs-AdmPwdExpirationTime

Write-host ("[Servers loaded]: $($servers.count)") -ForegroundColor Cyan

# We don't want the actual passwords....
$ServerOutput = @()
foreach ($server in $servers){
    $inpoweredoffgroup = "No"
    $Groups = (Get-ADComputer $server.samaccountname -Properties memberof)
    if ($Groups.MemberOf -like "*Powered Down*"){
        $inpoweredoffgroup = "Yes"
    }

    $DifferenceDays = $null
    $Actions = $null

    if($server.AdmPwdExpirationTime -ne $null){
        $AdmPwdExpirationTime = $server.AdmPwdExpirationTime.ToString("yyyy-MM-dd HH:mm")
        $days_diff_boot_pw_change = (([datetime]$server.AdmPwdExpirationTime)-([datetime]$server.lastLogonTimestamp)).days
        $pw_change_days = (([datetime]$server.AdmPwdExpirationTime)-(Get-Date)).days

        if ($inpoweredoffgroup -eq "No"){
            if ($days_diff_boot_pw_change -lt 0){
                $Actions = "Boot date later than expiry date. Confirm that LAPS set to cycle password. "
            }
            if ($pw_change_days -lt 0){
                    $Actions = $Actions + "Expiry date in the past. Confirm that LAPS set to cycle password.  "
            }
        }
    } else {
        $AdmPwdExpirationTime = ""
    }


    if ($server."AdmPwd" -eq "" -or $server."AdmPwd" -eq $null){
            $result = [PSCustomObject] @{
                            "DNSHostName" = $server.DNSHostName
                            "AdmPwd" = "EMPTY!!"
                            "AdmPwdExpirationTime" = $AdmPwdExpirationTime 
                            "lastLogonTimestamp" = $server.lastLogonTimestamp.ToString("yyyy-MM-dd HH:mm")
                            "enabled" = $server.Enabled
                            "days_diff_boot_pw_change" = ""
                            "power_off_group" = $inpoweredoffgroup
                            "actions" = "Configure LAPS!"
                            }
            $ServerOutput = $ServerOutput + $result
    } else {
           $result = [PSCustomObject] @{
                            "DNSHostName" = $server.DNSHostName
                            "AdmPwd" = "Present"
                            "AdmPwdExpirationTime" = $AdmPwdExpirationTime 
                            "lastLogonTimestamp" = $server.lastLogonTimestamp.ToString("yyyy-MM-dd HH:mm")
                            "enabled" = $server.Enabled
                            "days_diff_boot_pw_change" = $days_diff_boot_pw_change
                            "power_off_group" = $inpoweredoffgroup
                            "actions" = $Actions
                            }
           $ServerOutput = $ServerOutput + $result
    }
}

#dump output to CSV in the users documents folder on the local machine
$OutputCSV = "C:\Users\$($env:USERNAME)\Documents\ADLAPSExport-$((Get-ADDomain).DNSRoot)_$((get-date -format 'yyyyMMdd').ToString()).csv"
$ServerOutput | sort lastLogonTimestamp | Export-Csv "$($OutputCSV)"  -NoTypeInformation 

$EmptyCount = $ServerOutput | ? {$_.AdmPwd -like "EMPTY*"}
$ActionsNeeded = $ServerOutput | ? {$_.actions -ne $null}

Write-host("[Empty passwords]: $($EmptyCount.count)") -ForegroundColor Red
Write-host("[Actions needed]: $($ActionsNeeded.count)") -ForegroundColor Cyan

<# --== Errata ==--

Prerequisites needed before launching:
- Powershell 5.1 or better
- AzureAD module installed (you need to do this in an elevated powershell window): > install-module AzureAD
- Permissions (or an elevated role) to read the Conditional Access policy properties

Restrictions
- None

To do in later versions:
- Nothing planned

Changelog:
- 1 Initial version. Dec, 2022.
- 2 Added Last Logon timestamp for comparison and removed actual passwords.  Feb 21, 2023
- 3 Tweak timestamp reporting on expiration time and last logon time to correctly format in Excel on any timezone.   July 5, 2023
- 4 Added suggested action checks and summary output August 1, 2023
#>
