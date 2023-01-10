#Retrieve the distribution group owners and export to a csv

Get-DistributionGroup -identity "distroyouwanttocheck@yourcompany.com" | Select SMTPAddress,ManagedBy | Export-Csv C:/csv/distroowners.csv