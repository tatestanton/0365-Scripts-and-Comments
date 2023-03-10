#This script will retrieve forwarding information for every mailbox in your organization adn export it as a csv

$mb = Get-Mailbox -Resultsize Unlimited | where { $_.ForwardingAddress -ne $Null }
$SAM = $mb.SamAccountName
$mboof = Get-MailboxAutoReplyConfiguration $SAM

$userObj = New-Object PSObject
	$userObj | Add-Member NoteProperty -Name "Display Name" -Value $mb.DisplayName
	$userObj | Add-Member NoteProperty -Name "Forwarding Address" -Value $mb.ForwardingAddress
	$userObj | Add-Member NoteProperty -Name "Forwarding SMTP Address" -Value $mb.ForwardingSMTPAddress
	$userObj | Add-Member NoteProperty -Name "Deliver To Both?" -Value $mb.DeliverToMailboxAndForward

	$userObj | Add-Member NoteProperty -Name "OOF Enabled" -Value $mboof.AutoReplyState
	$userObj | Add-Member NoteProperty -Name "OOF Start" -Value $mboof.StartTime
	$userObj | Add-Member NoteProperty -Name "OOF End" -Value $mboof.EndTime
	$userObj | Add-Member NoteProperty -Name "Internal Message" -Value $mboof.InternalMessage
	$userObj | Add-Member NoteProperty -Name "External Enabled?" -Value $mboof.ExternalAudience
	$userObj | Add-Member NoteProperty -Name "External Message" -Value $mboof.ExternalMessage
	$userObj | Add-Member NoteProperty -Name "OOF Valid?" -Value $mboof.IsValid

$userObj | Export-CSV ./ForwardingUsers.CSV