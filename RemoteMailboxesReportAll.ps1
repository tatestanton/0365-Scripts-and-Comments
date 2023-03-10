#This script will retrieve all of the remote mailboxes (mailboxes stored on O365). It needs to be run in the Exchange Shell in your on-premise environment. It can be run on multiple on premise Exchange servers.
$allRemoteMailboxes = @();

$allRemoteMailboxes = Get-RemoteMailbox -ResultSize 10000 -DomainController dc1servername.dc.domain.com|Sort-Object -Property primarysmtpaddress| Select-Object  @{n="DC";e={"dc.domain.com"}},displayname,primarysmtpaddress,userprincipalname
$allRemoteMailboxes = Get-RemoteMailbox -ResultSize 10000 -DomainController dc2servername.dc.domain.com|Sort-Object -Property primarysmtpaddress| Select-Object  @{n="DC";e={"dc.domain.com"}},displayname,primarysmtpaddress,userprincipalname

$allRemoteMailboxes |ft
$allRemoteMailboxes | Measure-Object
$allRemoteMailboxes | Sort-Object -Property primarysmtpaddress | Export-Csv -NoTypeInformation C:\CSV\AllRemoteMailboxes.csv

