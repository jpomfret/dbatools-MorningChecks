# What do we have?

# two instances
Connect-DbaInstance -SqlInstance dbatools1, dbatools2

# some databases
Get-DbaDatabase -SqlInstance dbatools1, dbatools2 -ExcludeSystem | Format-Table -AutoSize