#Add a new owner to a locked security or distro group
#The command below will remove the current owners and only add the owner you specified
Set-DistributionGroup distroyouwanttoaddanewownerto@yourcompany.com -ManagedBy "newowneremail@yourcompany.com" -BypassSecurityGroupManagerCheck