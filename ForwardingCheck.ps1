#This script will retrieve the forwarding address on a specific mailbox

Get-Mailbox mailboxyouwanttoverifyforwardingon@yourcompany.com | fl ForwardingSMTPAddress,DeliverToMailboxandForward