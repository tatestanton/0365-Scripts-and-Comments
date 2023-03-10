#Verify that batch users are not in a different migration batch before submitting the batch

$CSV = import-csv C:\CSV\BatchName.csv
$MigUsers = Get-MigrationUser -ResultSize Unlimited

ForEach ($x in $CSV) {
$x.emailaddress
    $MigUsers | Where {$_.MailboxEmailAddress -eq $x.emailaddress}
}
