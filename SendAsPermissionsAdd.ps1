#Add AD Send As Permissions 
Add-ADPermission -Identity mailboxyouwantaccessto@yourcompany.com -User userwhoneedsaccess@yourcompany.com -ExtendedRights "Send As"