#This script will retrieve the licensed users in your organization
#You will need to know the associated license sku 

Write-Output "get-msolaccountsku:"
get-msolaccountsku
Write-Output "Get Licensed Users:"
get-msoluser -all|where islicensed -like "True"|measure-object -line
