#This script will retrieve calendar permissions on everyone mailbox in your organization and export out the data as a csv

$Report = @()
  
   $Mailboxes = Get-Mailbox -ResultSize Unlimited 

   ForEach ($Mailbox in $Mailboxes) {
      $Calendar = $Mailbox.PrimarySmtpAddress.ToString() + ":\Calendar"
      $Permissions = Get-MailboxFolderPermission -Identity $Calendar

      ForEach ($Permission in $Permissions) { 
	        $permission | Add-Member -MemberType NoteProperty -Name "Calendar" -value $Mailbox.DisplayName
	        $Report = $Report + $permission

      }
   }

 $Report | Select-Object Calendar,User,@{label="AccessRights";expression={$_.AccessRights}} | Export-Csv -Path ".\CalendarPermissions$(Get-Date -f 'MMddyy').csv" -NoTypeInformation