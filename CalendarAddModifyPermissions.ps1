# Set Shared Calendar Permissions
# AccessRights options: Owner, PublishingEditor, Editor, PublishingAuthor, Author, NonEditingAuthor, Reviewer, Contributor, AvailabilityOnly, LimitedDetails
Add-MailboxFolderPermission calendaryouwantpermissionsto@yourcompany.com:\Calendar -User userwhoneedspermissions@company.com -AccessRights Author


#Modify existing user permissions
Set-MailboxFolderPermission calendaryouwantpermissionsto@yourcompany.com:\Calendar -User userwhoneedspermissions@company.com -AccessRights Owner

