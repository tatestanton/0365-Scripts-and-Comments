#This script will retrieve mailbox delegation and permissions on every mailbox in your organization
Get-Mailbox -ResultSize Unlimited | 
    Get-MailboxPermission | 
    where {$_.user.tostring() -ne "NT AUTHORITY\SELF" -and $_.IsInherited -eq $false} | 
    Select Identity,User,@{Name='Access Rights';Expression={[string]::join(', ', $_.AccessRights)}} | 
    Export-Csv -Path ".\DelegatePermissions$(Get-Date -f 'MMddyy').csv" -NoTypeInformation