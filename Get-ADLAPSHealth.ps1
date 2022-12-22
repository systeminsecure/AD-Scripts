<#
Script used to grab the last updated time from the LAPS attribute in AD for servers. 
This is good to see which machines have a broken/misconfigured LAPS client
systeminsecure 2022-12-22 v1
#>

$servers = Get-ADComputer -Filter "OperatingSystem -Like '*Windows Server*' -and Enabled -eq 'True' -and -not description -like '*cluster*' -and servicePrincipalName -notlike '*MSClusterVirtualServer*' -and servicePrincipalName -notlike '*GC/*'" -Properties DNSHostName,ms-Mcs-AdmPwdExpirationTime `
| Select @{Name="DNSHostName"; Expression = {$_.DNSHostName}}, @{Name="ms-mcs-AdmPwd"; Expression = {$_.'ms-mcs-AdmPwd'}}, @{Name="ms-Mcs-AdmPwdExpirationTime"; Expression = {$([datetime]::FromFileTime([convert]::ToInt64($_.'ms-MCS-AdmPwdExpirationTime',10)))}} `
| sort ms-Mcs-AdmPwdExpirationTime

#dump output to CSV in the users documents folder on the local machine
$OutputCSV = "C:\Users\$($env:USERNAME)\Documents\LAPSExport-$((Get-ADDomain).DNSRoot)_$((get-date -format 'yyyyMMdd').ToString()).csv"
$servers | Export-Csv "$($OutputCSV)"  -NoTypeInformation 
