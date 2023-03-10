#This script will retrieve all of the distribution group member count and export it as a csv
$distgroups = @(Get-DistributionGroup -ResultSize Unlimited)
foreach ($dg in $distgroups)
{
    $count = @(Get-ADGroupMember -Recursive $dg.DistinguishedName).Count

    $reportObj = New-Object PSObject
    $reportObj | Add-Member NoteProperty -Name "Group Name" -Value $dg.Name
    $reportObj | Add-Member NoteProperty -Name "DN" -Value $dg.distinguishedName
    $reportObj | Add-Member NoteProperty -Name "Manager" -Value $dg.managedby.Name
    $reportObj | Add-Member NoteProperty -Name "Member Count" -Value $count

    Write-Host "$($dg.Name) has $($count) members"

    $report += $reportObj

}

$report | Export-CSV -Path C:\csv\DistributionGroupMemberCounts.csv -NoTypeInformation -Encoding UTF8
