#This will remove mailbox permissions
Remove-MailboxPermission -Identity mailboxyouwanttoremovepermissionsfrom@yourcompany.com -User "userwhodoesntneedaccessanymore" -AccessRights FullAccess