#Retrieve Alias information in a CSV
get-content 1.csv | foreach {
$Temp = Get-remoteMailbox -identity $_.Identity
$Temp.EmailAddresses.Add($_.EmailAddress2,$_.EmailAddress3,$_.EmailAddress3,$_.EmailAddress4,)
Set-remoteMailbox -Instance $Temp }