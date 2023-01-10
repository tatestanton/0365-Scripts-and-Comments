#Add Members to Distribution Group using a CSV file
$newgroup = Import-Csv C:\CSV\DistoGroup.csv

$newgroup | % {Add-DistributionGroupMember -Identity distributiongroup@yourcompany.com -Member $_.PrimarySmtpAddress}
