# Remove member from security group
Set-DistributionGroup "security group name" -ManagedBy @{remove="username"} -BypassSecurityGroupManagerCheck