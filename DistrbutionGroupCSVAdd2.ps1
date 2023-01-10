
#Create the distribution group first and then create a csv with appropriate names
#Create a CSV with Member as a column you can use the formula =CONCATENATE(A1,"@yourcompany.com ") to add the email address at the end. Select all the cells with formulas that you want to convert.
#Press Ctrl + C or Ctrl + Ins to copy formulas and their results to clipboard.
#Press Shift+F10 and then V to paste only values back to Excel cells.
Import-Csv C:\csv\DLMembers.csv| ForEach { Add-DistributionGroupMember –Identity distroyouwanttoaddmembersto@yourcompany.com –Member $_.Member}
