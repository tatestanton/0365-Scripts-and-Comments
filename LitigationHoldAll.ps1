Get-Mailbox -ResultSize Unlimited -Filter {RecipientTypeDetails -eq "UserMailbox"} | Set-Mailbox -LitigationHoldEnabled $True


#Connection Script
$credential = Get-Credential
Import-Module MSOnline

Connect-MsolService -Credential $credential

Set-ExecutionPolicy 'RemoteSigned' -Scope Process -Confirm:$false

Set-ExecutionPolicy 'RemoteSigned' -Scope CurrentUser -Confirm:$false

#Exchange Online Connect

$session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri “https://outlook.office365.com/powershell-liveid/” -Credential $credential -Authentication “Basic” –AllowRedirection

Import-PSSession $session


Get-Mailbox -ResultSize Unlimited -Filter {RecipientTypeDetails -eq "UserMailbox"} | Set-Mailbox -LitigationHoldEnabled $True