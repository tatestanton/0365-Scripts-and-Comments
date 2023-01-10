#This script will delete a sent message
#You will need to create a new csv spreadsheet with primarysmtpaddress (user who sent the mail), subject, date, and target (user mailbox the mail was sent to) columns
$subject = "Email Subject Name"
$date    = "Date the mail was sent"
$target  = "mailboxthemessagewassentto@yourcompany"

$csvInput = Import-Csv C:\CSV\MessageRecall.csv


$csvInput[200] | % {Search-Mailbox -Identity $_.PrimarySmtpAddress -SearchQuery 'sent:01/01/2001 Subject:"Email Subject Name"" from:mailboxthatyousentfrom@yourcompany.com' -TargetMailbox $target -TargetFolder purge -LogOnly -LogLevel full}