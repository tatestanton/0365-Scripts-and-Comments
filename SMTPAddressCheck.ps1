#This is a third party script that'll retrieve multiple environment errors and then extract the errors out in a csv



	.DESCRIPTION
		A description of the file.
#>
<#
.EXTERNALHELP CheckInvalidRecipients-help.xml
#>

# Copyright (c) Microsoft Corporation. All rights reserved.
#
# THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE RISK
# OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.

# Synopsis: This script is designed to return information on invalid recipient objects and possible attemtpt to fix them.
#
# The script will attempt to fix two classes of errors:
# 1. Primary SMTP Address Problems:	If a recipient has multiple SMTP addresses listed as primary or the primary SMTP is invalid, the script
#					will try to set the WindowsEmailAddress as the primary SMTP address, since that is the address Exchange
#					2003 would have recognized as the primary (although E12 does not).
# 2. Distribution Group Hidden Membership:	If a distribution group has HideDLMembershipEnabled set to true, but ReportToManagerEnabled,
#					ReportToOriginatorEnabled and/or SendOofMessageToOriginatorEnabled are set to true, then the membership
#					is not actually securely hidden. The script will set ReportToManagerEnabled, ReportToOriginatorEnabled and
#					SendOofMessageToOriginatorEnabled to false to fix the distribution group.
#
# Usage:
#
#    .\CheckInvalidRecipients -help
#
#       Gets help for the script
#
#    .\CheckInvalidRecipients
#
#       Returns all the invalid Recipients in the Org.
#
#    .\CheckInvalidRecipients -OrganizationalUnit 'Users' -FixErrors
#
#       Fixes all the invalid recipients in the Users container of the local domain.
#

Param (
	[string] $OrganizationalUnit,
	[string] $ResultSize = "Unlimited",
	[string] $Filter,
	[string] $DomainController,
	[switch] $FixErrors,
	[switch] $RemoveInvalidProxies,
	[switch] $ShowInvalidProxies,
	[switch] $OutputObjects,
	[switch] $CSV
)

#load hashtable of localized string
Import-LocalizedData -BindingVariable CheckInvalidRecipients_LocalizedStrings -FileName CheckInvalidRecipients.strings.psd1

# Catch any random input and output the help text
if ($args)
{
	exit
}

############################################################ Function Declarations ################################################################

function HasValidWindowsEmailAddress($obj)
{
	return $obj.WindowsEmailAddress.IsValidAddress
}

function HasInvalidPrimarySmtp($obj)
{
	return !$obj.PrimarySmtpAddress.IsValidAddress
}

function IsValid($obj)
{
	if (!$obj.IsValid)
	{ return $false }
	
	foreach ($address in $obj.EmailAddresses)
	{
		if ($address -is [Microsoft.Exchange.Data.InvalidProxyAddress])
		{ return $false }
	}
	
	return $true
}

function WriteErrorMessage($str)
{
	Write-host $str -ForegroundColor Red
}

function WriteInformation($str)
{
	Write-host $str -ForegroundColor Yellow
}

function WriteSuccess($str)
{
	Write-host $str -ForegroundColor Green
}

function WriteWarning($str)
{
	$WarningPreference = $Global:WarningPreference
	write-warning $str
}

function PrintValidationError($obj)
{
	foreach ($err in $obj.Validate())
	{
		WriteErrorMessage('{0},{1},{2}' -f $obj.Id, $err.PropertyDefinition.Name, $err.Description)
	}
}

function EvaluateErrors($Recipient)
{
	PrintValidationError($Recipient)
	
	$tasknoun = $null
	
	# We're comparing the RecipientType to the enum value instead of strings, because the strings may be localized and then this comparison would fail
	switch ($Recipient.RecipientType)
	{
		{ $_ -eq [Microsoft.Exchange.Data.Directory.Recipient.RecipientType]::UserMailbox }				{ $tasknoun = "Mailbox" }
		{ $_ -eq [Microsoft.Exchange.Data.Directory.Recipient.RecipientType]::MailUser }				{ $tasknoun = "Mailuser" }
		{ $_ -eq [Microsoft.Exchange.Data.Directory.Recipient.RecipientType]::MailContact }			{ $tasknoun = "Mailcontact" }
		{ $_ -eq [Microsoft.Exchange.Data.Directory.Recipient.RecipientType]::MailUniversalDistributionGroup }	{ $tasknoun = "DistributionGroup" }
		{ $_ -eq [Microsoft.Exchange.Data.Directory.Recipient.RecipientType]::MailUniversalSecurityGroup }		{ $tasknoun = "DistributionGroup" }
		{ $_ -eq [Microsoft.Exchange.Data.Directory.Recipient.RecipientType]::MailNonUniversalGroup }		{ $tasknoun = "DistributionGroup" }
		{ $_ -eq [Microsoft.Exchange.Data.Directory.Recipient.RecipientType]::DynamicDistributionGroup }					{ $tasknoun = "DynamicDistributionGroup" }
	}
	
	if (($tasknoun -ne $null) -AND ($FixErrors -OR $ShowInvalidProxies))
	{
		# Prepare the appropriate get/set tasks that need to run
		$GetRecipientCommand = "get-$tasknoun"
		if (![String]::IsNullOrEmpty($DomainController))
		{ $GetRecipientCommand += " -DomainController $DomainController" }
		
		$SetRecipientCommand = "set-$tasknoun"
		if (![String]::IsNullOrEmpty($DomainController))
		{ $SetRecipientCommand += " -DomainController $DomainController" }
		
		# Read the object using the correct Get-Task, so we get all the email properties
		$Recipient = &$GetRecipientCommand $Recipient.Identity
		
		# Nothing to do if the recipient is completely valid except output it to the pipeline
		if (IsValid($Recipient))
		{
			# Output the object to the pipeline
			if ($OutputObjects)
			{ Write-Output $Recipient }
			
			return;
		}
		
		# Collect all the invalid proxy addresses in case we need them later
		$InvalidProxies = @()
		foreach ($Address in $Recipient.EmailAddresses)
		{
			if ($Address -is [Microsoft.Exchange.Data.InvalidProxyAddress])
			{
				$InvalidProxies += $Address
			}
		}
		
		if ($ShowInvalidProxies -AND ($InvalidProxies.Length -gt 0))
		{
			foreach ($Address in $InvalidProxies)
			{
				WriteErrorMessage('{0},{1},{2}' -f $Recipient.Id, "EmailAddresses", $Address.ParseException.ToString())
			}
		}
		
		if ($FixErrors)
		{
			$RecipientModified = $false
			
			# Fix the major PrimarySmtpAddress problems
			# If the WindowsEmailAddress is valid, we'll set that as the Primary since Exchange 2003 used that as the Primary
			if ((HasValidWindowsEmailAddress($Recipient)) -AND
			(HasInvalidPrimarySmtp($Recipient)))
			{
				$Recipient.PrimarySmtpAddress = $Recipient.WindowsEmailAddress
				WriteInformation($CheckInvalidRecipients_LocalizedStrings.res_0001 -f $Recipient.Identity, $Recipient.WindowsEmailAddress)
				$RecipientModified = $true
			}
			
			# If the ExternalEmailAddress is missing from the EmailAddresses collection, we should add it back
			if (($null -ne $Recipient.ExternalEmailAddress) -AND
			!($Recipient.EmailAddresses.Contains($Recipient.ExternalEmailAddress)))
			{
				$Recipient.EmailAddresses.Add($Recipient.ExternalEmailAddress)
				$RecipientModified = $true
			}
			
			# Remove all the invalid proxy addresses if the user specified the RemoveInvalidProxies flag
			if ($RemoveInvalidProxies -AND ($InvalidProxies.Length -gt 0))
			{
				foreach ($Address in $InvalidProxies)
				{
					# Using this DummyVariable so the script doesn't output the result of the Remove operation
					$DummyVariable = $Recipient.EmailAddresses.Remove($Address)
					WriteInformation($CheckInvalidRecipients_LocalizedStrings.res_0002 -f $Recipient.Identity, $Address)
				}
				$RecipientModified = $true
			}
			
			# Let's try to save the object back to AD
			if ($RecipientModified)
			{
				$numErrors = $error.Count
				&$SetRecipientCommand -Instance $Recipient
				if ($error.Count -eq $numErrors)
				{
					WriteSuccess($CheckInvalidRecipients_LocalizedStrings.res_0003 -f $Recipient.Identity)
				}
				else
				{
					WriteErrorMessage($CheckInvalidRecipients_LocalizedStrings.res_0004 -f $Recipient.Identity)
				}
			}
			
			# Re-read the recipient if we modified it in any way and we want to output it to the pipeline
			if ($OutputObjects)
			{ $Recipient = &$GetRecipientCommand $Recipient.Identity }
			
		} # if ($FixErrors)
	} # if (($tasknoun -ne $null) -AND ($FixErrors -OR $ShowInvalidProxies))
	
	# Output the object to the pipeline
	if ($OutputObjects)
	{ Write-Output $Recipient }
	
	# Output the object to CSV
	if ($CSV)
	{ $Recipient Export-Csv }
	
} # EvaluateErrors

############################################################ Function Declarations End ############################################################

############################################################ Main Script Block ####################################################################

#Ignore Warnings output by the task
$WarningPreference = 'SilentlyContinue'

if ($RemoveInvalidProxies -AND !$FixErrors)
{ WriteWarning($CheckInvalidRecipients_LocalizedStrings.res_0005) }

# Check if we have any pipeline input
# If yes, MoveNext will return true and we won't run our get tasks
if ($input.MoveNext())
{
	# Reset the enumerator so we can look at the first object again
	$input.Reset()
	
	if ($ResultSize -NE "Unlimited")
	{ WriteWarning($CheckInvalidRecipients_LocalizedStrings.res_0006) }
	if (![String]::IsNullOrEmpty($OrganizationalUnit))
	{ WriteWarning($CheckInvalidRecipients_LocalizedStrings.res_0007) }
	if (![String]::IsNullOrEmpty($Filter))
	{ WriteWarning($CheckInvalidRecipients_LocalizedStrings.res_0008) }
	
	foreach ($Recipient in $input)
	{
		# skip over inputs that we can't handle
		if ($Recipient -eq $null -OR
		$Recipient.RecipientType -eq $null -OR
		$Recipient -isnot [Microsoft.Exchange.Data.Directory.ADObject])
		{ continue; }
		
		EvaluateErrors($Recipient)
	}
}
else
{
	$cmdlets =
	@("get-User",
	"get-Contact",
	"get-Group",
	"get-DynamicDistributionGroup")
	
	foreach ($task in $cmdlets)
	{
		$command = "$task -ResultSize $ResultSize"
		if (![String]::IsNullOrEmpty($OrganizationalUnit))
		{ $command += " -OrganizationalUnit $OrganizationalUnit" }
		if (![String]::IsNullOrEmpty($DomainController))
		{ $command += " -DomainController $DomainController" }
		if (![String]::IsNullOrEmpty($Filter))
		{ $command += " -Filter $Filter" }
		
		invoke-expression $command | foreach { EvaluateErrors($_) }
	}
}

############################################################ Main Script Block END ################################################################

# SIG # Begin signature block
# MIIazQYJKoZIhvcNAQcCoIIavjCCGroCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUdLu/uLnYGkP9ikFUeohJAUv5
# m7GgghWCMIIEwzCCA6ugAwIBAgITMwAAAEyh6E3MtHR7OwAAAAAATDANBgkqhkiG
# 9w0BAQUFADB3MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEw
# HwYDVQQDExhNaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EwHhcNMTMxMTExMjIxMTMx
# WhcNMTUwMjExMjIxMTMxWjCBszELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjENMAsGA1UECxMETU9QUjEnMCUGA1UECxMebkNpcGhlciBEU0UgRVNO
# OkMwRjQtMzA4Ni1ERUY4MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBT
# ZXJ2aWNlMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsdj6GwYrd6jk
# lF18D+Z6ppLuilQdpPmEdYWXzMtcltDXdS3ZCPtb0u4tJcY3PvWrfhpT5Ve+a+i/
# ypYK3EbxWh4+AtKy4CaOAGR7vjyT+FgyeYfSGl0jvJxRxA8Q+gRYtRZ2buy8xuW+
# /K2swUHbqs559RyymUGneiUr/6t4DVg6sV5Q3mRM4MoVKt+m6f6kZi9bEAkJJiHU
# Pw0vbdL4d5ADbN4UEqWM5zYf9IelsEEXb+NNdGbC/aJxRjVRzGsXUWP6FZSSml9L
# KLrmFkVJ6Sy1/ouHr/ylbUPcpjD6KSjvmw0sXIPeEo1qtNtx71wUWiojKP+BcFfx
# jAeaE9gqUwIDAQABo4IBCTCCAQUwHQYDVR0OBBYEFLkNrbNN9NqfGrInJlUNIETY
# mOL0MB8GA1UdIwQYMBaAFCM0+NlSRnAK7UD7dvuzK7DDNbMPMFQGA1UdHwRNMEsw
# SaBHoEWGQ2h0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3Rz
# L01pY3Jvc29mdFRpbWVTdGFtcFBDQS5jcmwwWAYIKwYBBQUHAQEETDBKMEgGCCsG
# AQUFBzAChjxodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY3Jv
# c29mdFRpbWVTdGFtcFBDQS5jcnQwEwYDVR0lBAwwCgYIKwYBBQUHAwgwDQYJKoZI
# hvcNAQEFBQADggEBAAmKTgav6O2Czx0HftcqpyQLLa+aWyR/lHEMVYgkGlIVY+KQ
# TQVKmEqc++GnbWhVgrkp6mmpstXjDNrR1nolN3hnHAz72ylaGpc4KjlWRvs1gbnk
# PUZajuT8dTdYWUmLTts8FZ1zUkvreww6wi3Bs5tSLeA1xbnBV7PoPaE8RPIjFh4K
# qlk3J9CVUl6ofz9U8IHh3Jq9ZdV49vdMObvd4NY3DpGah4xz53FkUvc+A9jGzXK4
# NDSYW4zT9Qim63jGUaANDm/0azxAGmAWLKkGUp0cE5DObwIe6nucs/b4l2DyZdHR
# H4c6wXXwQo167Yxysnv7LIq0kUdU4i5pzBZUGlkwggTsMIID1KADAgECAhMzAAAA
# sBGvCovQO5/dAAEAAACwMA0GCSqGSIb3DQEBBQUAMHkxCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xIzAhBgNVBAMTGk1pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBMB4XDTEzMDEyNDIyMzMzOVoXDTE0MDQyNDIyMzMzOVowgYMxCzAJ
# BgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25k
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xDTALBgNVBAsTBE1PUFIx
# HjAcBgNVBAMTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjCCASIwDQYJKoZIhvcNAQEB
# BQADggEPADCCAQoCggEBAOivXKIgDfgofLwFe3+t7ut2rChTPzrbQH2zjjPmVz+l
# URU0VKXPtIupP6g34S1Q7TUWTu9NetsTdoiwLPBZXKnr4dcpdeQbhSeb8/gtnkE2
# KwtA+747urlcdZMWUkvKM8U3sPPrfqj1QRVcCGUdITfwLLoiCxCxEJ13IoWEfE+5
# G5Cw9aP+i/QMmk6g9ckKIeKq4wE2R/0vgmqBA/WpNdyUV537S9QOgts4jxL+49Z6
# dIhk4WLEJS4qrp0YHw4etsKvJLQOULzeHJNcSaZ5tbbbzvlweygBhLgqKc+/qQUF
# 4eAPcU39rVwjgynrx8VKyOgnhNN+xkMLlQAFsU9lccUCAwEAAaOCAWAwggFcMBMG
# A1UdJQQMMAoGCCsGAQUFBwMDMB0GA1UdDgQWBBRZcaZaM03amAeA/4Qevof5cjJB
# 8jBRBgNVHREESjBIpEYwRDENMAsGA1UECxMETU9QUjEzMDEGA1UEBRMqMzE1OTUr
# NGZhZjBiNzEtYWQzNy00YWEzLWE2NzEtNzZiYzA1MjM0NGFkMB8GA1UdIwQYMBaA
# FMsR6MrStBZYAck3LjMWFrlMmgofMFYGA1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9j
# cmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY0NvZFNpZ1BDQV8w
# OC0zMS0yMDEwLmNybDBaBggrBgEFBQcBAQROMEwwSgYIKwYBBQUHMAKGPmh0dHA6
# Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljQ29kU2lnUENBXzA4LTMx
# LTIwMTAuY3J0MA0GCSqGSIb3DQEBBQUAA4IBAQAx124qElczgdWdxuv5OtRETQie
# 7l7falu3ec8CnLx2aJ6QoZwLw3+ijPFNupU5+w3g4Zv0XSQPG42IFTp8263Os8ls
# ujksRX0kEVQmMA0N/0fqAwfl5GZdLHudHakQ+hywdPJPaWueqSSE2u2WoN9zpO9q
# GqxLYp7xfMAUf0jNTbJE+fA8k21C2Oh85hegm2hoCSj5ApfvEQO6Z1Ktwemzc6bS
# Y81K4j7k8079/6HguwITO10g3lU/o66QQDE4dSheBKlGbeb1enlAvR/N6EXVruJd
# PvV1x+ZmY2DM1ZqEh40kMPfvNNBjHbFCZ0oOS786Du+2lTqnOOQlkgimiGaCMIIF
# vDCCA6SgAwIBAgIKYTMmGgAAAAAAMTANBgkqhkiG9w0BAQUFADBfMRMwEQYKCZIm
# iZPyLGQBGRYDY29tMRkwFwYKCZImiZPyLGQBGRYJbWljcm9zb2Z0MS0wKwYDVQQD
# EyRNaWNyb3NvZnQgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkwHhcNMTAwODMx
# MjIxOTMyWhcNMjAwODMxMjIyOTMyWjB5MQswCQYDVQQGEwJVUzETMBEGA1UECBMK
# V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0
# IENvcnBvcmF0aW9uMSMwIQYDVQQDExpNaWNyb3NvZnQgQ29kZSBTaWduaW5nIFBD
# QTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALJyWVwZMGS/HZpgICBC
# mXZTbD4b1m/My/Hqa/6XFhDg3zp0gxq3L6Ay7P/ewkJOI9VyANs1VwqJyq4gSfTw
# aKxNS42lvXlLcZtHB9r9Jd+ddYjPqnNEf9eB2/O98jakyVxF3K+tPeAoaJcap6Vy
# c1bxF5Tk/TWUcqDWdl8ed0WDhTgW0HNbBbpnUo2lsmkv2hkL/pJ0KeJ2L1TdFDBZ
# +NKNYv3LyV9GMVC5JxPkQDDPcikQKCLHN049oDI9kM2hOAaFXE5WgigqBTK3S9dP
# Y+fSLWLxRT3nrAgA9kahntFbjCZT6HqqSvJGzzc8OJ60d1ylF56NyxGPVjzBrAlf
# A9MCAwEAAaOCAV4wggFaMA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFMsR6MrS
# tBZYAck3LjMWFrlMmgofMAsGA1UdDwQEAwIBhjASBgkrBgEEAYI3FQEEBQIDAQAB
# MCMGCSsGAQQBgjcVAgQWBBT90TFO0yaKleGYYDuoMW+mPLzYLTAZBgkrBgEEAYI3
# FAIEDB4KAFMAdQBiAEMAQTAfBgNVHSMEGDAWgBQOrIJgQFYnl+UlE/wq4QpTlVnk
# pDBQBgNVHR8ESTBHMEWgQ6BBhj9odHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtp
# L2NybC9wcm9kdWN0cy9taWNyb3NvZnRyb290Y2VydC5jcmwwVAYIKwYBBQUHAQEE
# SDBGMEQGCCsGAQUFBzAChjhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2Nl
# cnRzL01pY3Jvc29mdFJvb3RDZXJ0LmNydDANBgkqhkiG9w0BAQUFAAOCAgEAWTk+
# fyZGr+tvQLEytWrrDi9uqEn361917Uw7LddDrQv+y+ktMaMjzHxQmIAhXaw9L0y6
# oqhWnONwu7i0+Hm1SXL3PupBf8rhDBdpy6WcIC36C1DEVs0t40rSvHDnqA2iA6VW
# 4LiKS1fylUKc8fPv7uOGHzQ8uFaa8FMjhSqkghyT4pQHHfLiTviMocroE6WRTsgb
# 0o9ylSpxbZsa+BzwU9ZnzCL/XB3Nooy9J7J5Y1ZEolHN+emjWFbdmwJFRC9f9Nqu
# 1IIybvyklRPk62nnqaIsvsgrEA5ljpnb9aL6EiYJZTiU8XofSrvR4Vbo0HiWGFzJ
# NRZf3ZMdSY4tvq00RBzuEBUaAF3dNVshzpjHCe6FDoxPbQ4TTj18KUicctHzbMrB
# 7HCjV5JXfZSNoBtIA1r3z6NnCnSlNu0tLxfI5nI3EvRvsTxngvlSso0zFmUeDord
# EN5k9G/ORtTTF+l5xAS00/ss3x+KnqwK+xMnQK3k+eGpf0a7B2BHZWBATrBC7E7t
# s3Z52Ao0CW0cgDEf4g5U3eWh++VHEK1kmP9QFi58vwUheuKVQSdpw5OPlcmN2Jsh
# rg1cnPCiroZogwxqLbt2awAdlq3yFnv2FoMkuYjPaqhHMS+a3ONxPdcAfmJH0c6I
# ybgY+g5yjcGjPa8CQGr/aZuW4hCoELQ3UAjWwz0wggYHMIID76ADAgECAgphFmg0
# AAAAAAAcMA0GCSqGSIb3DQEBBQUAMF8xEzARBgoJkiaJk/IsZAEZFgNjb20xGTAX
# BgoJkiaJk/IsZAEZFgltaWNyb3NvZnQxLTArBgNVBAMTJE1pY3Jvc29mdCBSb290
# IENlcnRpZmljYXRlIEF1dGhvcml0eTAeFw0wNzA0MDMxMjUzMDlaFw0yMTA0MDMx
# MzAzMDlaMHcxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYD
# VQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xITAf
# BgNVBAMTGE1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQTCCASIwDQYJKoZIhvcNAQEB
# BQADggEPADCCAQoCggEBAJ+hbLHf20iSKnxrLhnhveLjxZlRI1Ctzt0YTiQP7tGn
# 0UytdDAgEesH1VSVFUmUG0KSrphcMCbaAGvoe73siQcP9w4EmPCJzB/LMySHnfL0
# Zxws/HvniB3q506jocEjU8qN+kXPCdBer9CwQgSi+aZsk2fXKNxGU7CG0OUoRi4n
# rIZPVVIM5AMs+2qQkDBuh/NZMJ36ftaXs+ghl3740hPzCLdTbVK0RZCfSABKR2YR
# JylmqJfk0waBSqL5hKcRRxQJgp+E7VV4/gGaHVAIhQAQMEbtt94jRrvELVSfrx54
# QTF3zJvfO4OToWECtR0Nsfz3m7IBziJLVP/5BcPCIAsCAwEAAaOCAaswggGnMA8G
# A1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFCM0+NlSRnAK7UD7dvuzK7DDNbMPMAsG
# A1UdDwQEAwIBhjAQBgkrBgEEAYI3FQEEAwIBADCBmAYDVR0jBIGQMIGNgBQOrIJg
# QFYnl+UlE/wq4QpTlVnkpKFjpGEwXzETMBEGCgmSJomT8ixkARkWA2NvbTEZMBcG
# CgmSJomT8ixkARkWCW1pY3Jvc29mdDEtMCsGA1UEAxMkTWljcm9zb2Z0IFJvb3Qg
# Q2VydGlmaWNhdGUgQXV0aG9yaXR5ghB5rRahSqClrUxzWPQHEy5lMFAGA1UdHwRJ
# MEcwRaBDoEGGP2h0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1
# Y3RzL21pY3Jvc29mdHJvb3RjZXJ0LmNybDBUBggrBgEFBQcBAQRIMEYwRAYIKwYB
# BQUHMAKGOGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljcm9z
# b2Z0Um9vdENlcnQuY3J0MBMGA1UdJQQMMAoGCCsGAQUFBwMIMA0GCSqGSIb3DQEB
# BQUAA4ICAQAQl4rDXANENt3ptK132855UU0BsS50cVttDBOrzr57j7gu1BKijG1i
# uFcCy04gE1CZ3XpA4le7r1iaHOEdAYasu3jyi9DsOwHu4r6PCgXIjUji8FMV3U+r
# kuTnjWrVgMHmlPIGL4UD6ZEqJCJw+/b85HiZLg33B+JwvBhOnY5rCnKVuKE5nGct
# xVEO6mJcPxaYiyA/4gcaMvnMMUp2MT0rcgvI6nA9/4UKE9/CCmGO8Ne4F+tOi3/F
# NSteo7/rvH0LQnvUU3Ih7jDKu3hlXFsBFwoUDtLaFJj1PLlmWLMtL+f5hYbMUVbo
# nXCUbKw5TNT2eb+qGHpiKe+imyk0BncaYsk9Hm0fgvALxyy7z0Oz5fnsfbXjpKh0
# NbhOxXEjEiZ2CzxSjHFaRkMUvLOzsE1nyJ9C/4B5IYCeFTBm6EISXhrIniIh0EPp
# K+m79EjMLNTYMoBMJipIJF9a6lbvpt6Znco6b72BJ3QGEe52Ib+bgsEnVLaxaj2J
# oXZhtG6hE6a/qkfwEm/9ijJssv7fUciMI8lmvZ0dhxJkAj0tr1mPuOQh5bWwymO0
# eFQF1EEuUKyUsKV4q7OglnUa2ZKHE3UiLzKoCG6gW4wlv6DvhMoh1useT8ma7kng
# 9wFlb4kLfchpyOZu6qeXzjEp/w7FW1zYTRuh2Povnj8uVRZryROj/TGCBLUwggSx
# AgEBMIGQMHkxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYD
# VQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xIzAh
# BgNVBAMTGk1pY3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBAhMzAAAAsBGvCovQO5/d
# AAEAAACwMAkGBSsOAwIaBQCggc4wGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFHnN
# pi9m0Mke+SHYQ6nOycDauhNVMG4GCisGAQQBgjcCAQwxYDBeoDaANABDAGgAZQBj
# AGsASQBuAHYAYQBsAGkAZABSAGUAYwBpAHAAaQBlAG4AdABzAC4AcABzADGhJIAi
# aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL2V4Y2hhbmdlIDANBgkqhkiG9w0BAQEF
# AASCAQCZH5HFeZbvrjsYybJjSFDW1IJW9XbUuxoOlhvPiTF/wJgnP4m1iIHOZTJW
# sOY3FxM3G2DwdbYhjWpdpMTuHkRs2HFVk1Qa387escJT1lJIzbpEARR0rFIlPiS/
# /XOr+hCvbLU4GKKt5aZdzc4+fpFgQfE0Q+CiGAGu+MbEW0GLVm7zRNJeYmTSbKLG
# r+I0KM+PlSdsWiKOCDxcmxS7HEbJpI4raMVQBS2vIDe4duhZL2Y1655kbESV/WJI
# oJURlbah8T6wYvgFfvTLEfwPlnkRK7MLwZWde/SAJ93amsQ6L7KdISyNUq/tYGQt
# eqP3vddas98N+SDICKRdVi4Od1oLoYICKDCCAiQGCSqGSIb3DQEJBjGCAhUwggIR
# AgEBMIGOMHcxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYD
# VQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xITAf
# BgNVBAMTGE1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQQITMwAAAEyh6E3MtHR7OwAA
# AAAATDAJBgUrDgMCGgUAoF0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkq
# hkiG9w0BCQUxDxcNMTMxMTI3MTUxMDUwWjAjBgkqhkiG9w0BCQQxFgQUWxigefTT
# XdoK/8cnaho41S8KvccwDQYJKoZIhvcNAQEFBQAEggEAUtsCjnNPCA1RscUCqHCE
# kKqMZKD0SaWNirLKtB06+Hyx9zok2MR5vo+yNI++2XgKmgPfV7SLTCQWS3n+4HTY
# JhAcOx41l3MZ0R89KWuF1ebCKK7QmXfk9h/QK7q+8sX0jagj0Zj0gAzLW7pZKFd2
# vXnGxE6tVayses2sZA9aqkQMlzotR9nyk5tm32GrTwnSVtJZBX6phxmSqwUXRnmz
# K5RiRUKA3c+nxAum0q5KhzXmCisLQf6k4YMfy3S/em+G3tRJ+fUvMcO3hSY9k28U
# Jao0DP8cWBLqCoqnQgWCMa3pDdnZwjT8qPny5nhpQNF3LG8wn7QZrVHiwYdY7HZ5
# eQ==
# SIG # End signature block
