# pester tests to make sure the environment is ready to go
$instances = 'dbatools1', 'dbatools2'

describe "SQL Instances are alive" -ForEach $instances {
    it "Instance $instance is alive" {
        $inst = Connect-DbaInstance $psitem 
        $inst | Should -Not -BeNullOrEmpty
        $inst | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Server'
    }
}

