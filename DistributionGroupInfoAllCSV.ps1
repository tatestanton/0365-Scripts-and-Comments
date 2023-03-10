param([switch]$rebuildGroupInfo
)


$DistribGroupInfoCsv    = "C:\CSV\Distributiongroupall.csv"

#
# get mailbox accounts
#
$Limit                  = (Get-Date).AddDays(-1);

#
# get Group Lists
#
function getGroupInfo {
    if ($rebuildGroupInfo -or $(get-childitem $DistribGroupInfoCsv).LastWriteTime -lt $Limit) {
        Write-Output "Getting updated GroupInfo list, please wait..."
    #    $groupinfo = Get-Mailbox -ResultSize unlimited | select primarysmtpaddress,displayname,RecipientTypeDetails | Where-Object -Property RecipientTypeDetails -eq "UserMailbox"
        $groupinfo = Get-DistributionGroup -ResultSize unlimited | select primarysmtpaddress,displayname,RecipientType,RecipientTypeDetails |Sort-Object -Property primarysmtpaddress
        Remove-Item $DistribGroupInfoCsv
        $groupinfo | Export-Csv $DistribGroupInfoCsv -NoTypeInformation
    }
}

#PrimarySmtpAddress	DisplayName	RecipientType	RecipientTypeDetails
getGroupInfo
$groupinfo = Import-Csv $DistribGroupInfoCsv 
Write-Output "GroupInfo Count $($groupinfo.Count)"
return $groupinfo
