<#
Script used to grab the last logon time in AD for servers. 
This is good to see which machines are potentially gone without the proper cleanup being done.
Note: the line with lastlogon has an additional ToString method which formats the output in a specific way. Feel free to modify it the way you want it.

systeminsecure 2022-12-22 v1
#>

$InactiveDays=90
$output=@()
$outputs = Get-ADComputer  -Filter "OperatingSystem -Like '*Server*'"  -Properties Name,CanonicalName,Enabled,LastLogonDate,ManagedBy,OperatingSystem | Where {($_.LastLogonDate -lt (Get-Date).AddDays(-$InactiveDays)) -and ($_.Enabled -eq $true)} | sort LastLogonDate |  select Name,CanonicalName,Enabled,LastLogonDate,ManagedBy

     foreach ($result in $outputs) {
        $myservices = [PSCustomObject] @{
                                "Name" = $($result.Name)
                                "CanonicalName" = $($result.canonicalname)
                                "Enabled" = $($result.enabled)
                                "LastLogonDate" = $($result.LastLogonDate).ToString("yyyy-MM-dd HH:mm:ss")
                                "ManagedBy" = $($result.ManagedBy)
        }
        $output = $output + $myservices
     }

#dump output to CSV in the users documents folder on the local machine
$OutputCSV = "C:\Users\$($env:USERNAME)\Documents\InactiveServers$($InactiveDays)days_$((Get-ADDomain).DNSRoot)_$((get-date -format 'yyyyMMdd').ToString()).csv"
$output | Export-Csv "$($OutputCSV)"  -NoTypeInformation 
