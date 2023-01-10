#This script will retrieve the owners of distribution groups from a csv you created and then export the information out to a csv
$grouplist = Import-Csv C:\CSV\Distrogroupsyouwanttocheck.csv
$grouplist | % {Get-DistributionGroup -Identity $_.PrimarySmtpAddress} | Select-Object PrimarySmtpAddress,Managedby | Export-Csv C:\CSV\GroupOwners.csv