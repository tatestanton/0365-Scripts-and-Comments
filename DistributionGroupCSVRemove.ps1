#Remove a users from a distribution group using a .csv file 
$newgroup = Import-Csv C:\CSV\DistoGroup.csv

$newgroup | % {Remove-DistributionGroupMember -Identity distrogroupname -Member $_.PrimarySmtpAddress}

Foreach ($group in $newgroup)
{
remove-distributiongroupmember $group.GroupName -member $group.groupmember 
}
