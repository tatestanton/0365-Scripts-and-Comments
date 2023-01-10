#Search a users mailbox for a calendar item
 Search-Mailbox -Identity useraccount@yourcompany.com
 -SearchQuery 'Subject:"Meeting Name"' 
 
 #Delete the item from the users mailbox
 Search-Mailbox -Identity useraccount@yourcompany.com -SearchQuery 'Meeting Name' -DeleteContent 
 
 
#Delete calendar item as a mailbox and  calendar delegate
  Search-Mailbox -Identity "targetusersemailaddress@yourcompany.com" -SearchQuery 'Subject:"Meeting Name"' 
  -TargetMailbox "delegatesemailaddress@yourcompany.com" -TargetFolder "Calendar" -LogOnly -LogLevel Full 
