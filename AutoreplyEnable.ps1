#Setup an autoreply (internal and external) on a user mailbox
Set-MailboxAutoReplyConfiguration -Identity useraccountname -AutoReplyState Enabled -InternalMessage "Internal auto-reply message." -ExternalMessage "External auto-reply message."