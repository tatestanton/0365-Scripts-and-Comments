#Add Mailbox Permissions In Exchange
Add-MailboxPermission -Identity mailboxyouwanttoacces@yourcompany.com -User useraccountthatneedspermission@yourcompany.com -AccessRights FullAccess

Add-MailboxPermission -Identity mailboxyouwanttoacces@yourcompany.com -User useraccountthatneedspermission@yourcompany.com -AccessRights Sendas
