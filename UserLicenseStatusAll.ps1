#This script will retrieve the licensing status for all users in your organization and export it as a scv
Get-MSOLUser -All | select userprincipalname,islicensed,{$_.Licenses.AccountSkuId},UsageLocation,Country | Export-CSV c:\csv\alluserlicenseinfo.csv -NoTypeInformation

