#Reset the Office 365 user password for a single user

Set-MsolUserPassword –UserPrincipalName useremail@yourcompany.com –NewPassword newpassword -ForceChangePassword $False