<#
Script used to grab the extensionAttributes attribute in AD for servers. 
This is good to see which ones are in use and what values they hold
systeminsecure 2023-08-02 v1
#>

$users = get-aduser -Filter * -properties extensionAttribute1,extensionAttribute2,extensionAttribute3,extensionAttribute4,extensionAttribute5,extensionAttribute6,extensionAttribute7,extensionAttribute8,extensionAttribute9,extensionAttribute10
write-host("[User count]: $($users.count)") -ForegroundColor Blue -BackgroundColor Cyan
1..10 | % {
$extensionattr = "extensionAttribute" + $_
write-host("[$($extensionattr)]: $(($users | ? {$_.$($extensionattr) -ne '' -and $_.$($extensionattr) -ne $null}).count)  [values]: $(($users.$($extensionattr) | Group-Object).Name -join(','))") -ForegroundColor Cyan
}
