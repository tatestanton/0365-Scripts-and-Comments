#This is an alternative method to add members to a distribution group from a CSV
#Name of Distribution Group/List to add user(s) to
$TargetDL = "distroyouwanttoaddmembersto@yourcompany.com"


#Import List of Users to add from .txt file
$UserListFile = "C:\csv\DLMembers.csv"
$UserList = Get-Content $UserListFile

#Cycle through list of users and add them to 'Accept Messages Only From' list for DL
ForEach ($User in $UserList)
     {
     Set-DistributionGroup "$TargetDL" -AcceptMessagesOnlyFrom ((Get-DistributionGroup -identity "$TargetDL").AcceptMessagesOnlyFrom + "$User") 
     }