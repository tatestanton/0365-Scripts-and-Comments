#Bulk Update User Passwords from a csv
#Create a new csv with UserPrincipalName and NewPassword
#Populate the spreadsheet with applicable user and password information


Import-Csv C:\CSV\BulkPassword.csv|%{Set-MsolUserPassword –userPrincipalName $_.userprincipalname -NewPassword $_.newpassword -ForceChangePassword $false}