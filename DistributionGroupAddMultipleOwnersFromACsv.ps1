#This script will add multiple owners to a single distribution group from a csv file
$newgroup = Import-Csv C:\CSV\Distrogroupsownersyouwanttoadd.csv
$newgroup | % {Add-DistributionGroupMember -Identity distributiongroupyouwanttoaddownersto@yourcompany.com -Member $_.ManagedBy} 

