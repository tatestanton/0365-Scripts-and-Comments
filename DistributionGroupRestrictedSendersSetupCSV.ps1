#Add Restricted Senders to a distribution group

$Userlist = gc C:\csv\restrictedsenders.txt
ForEach ($User in $UserList)
     {
     Set-DistributionGroup "distroyouwanttorestrictsenders@yourcompany.com" -AcceptMessagesOnlyFrom ((Get-DistributionGroup -identity "distroyouwanttorestrictsenders@yourcompany.com").AcceptMessagesOnlyFrom + "$User") 
     } 
