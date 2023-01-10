#This script will retrieve all of the shared mailbox delegates in your organization and export the information to a csv
 
$OutFile = "C:\CSV\shareddelegates.csv"
"DisplayName" + "^" + "Alias" + "^" + "Full Access" + "^" + "Send As" | Out-File $OutFile -Force
$mailboxes1 = get-content shareddelegates.csv
$Mailboxes = $mailboxes1 | Get-Mailbox -RecipientTypeDetails SharedMailbox -ResultSize:Unlimited | Select Identity, Alias, DisplayName, DistinguishedName
ForEach ($Mailbox in $Mailboxes) {
                $SendAs = Get-ADPermission $Mailbox.DistinguishedName | ? {$_.ExtendedRights -like "Send-As" -and $_.User -notlike "NT AUTHORITY\SELF" -and !$_.IsInherited} | % {$_.User}
                $FullAccess = Get-MailboxPermission $Mailbox.Identity | ? {$_.AccessRights -eq "FullAccess" -and !$_.IsInherited} | % {$_.User}
                $Mailbox.DisplayName + "^" + $Mailbox.Alias + "^" + $FullAccess + "^" + $SendAs | Out-File $OutFile -Append}