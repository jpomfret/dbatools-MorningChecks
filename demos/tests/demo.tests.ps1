# pester tests to make sure the environment is ready to go
$instances = 'dbatools1', 'dbatools2'

describe "SQL Instances are alive" -ForEach $instances {
    it "Instance $instance is alive" {
        $inst = Connect-DbaInstance $psitem 
        $inst | Should -Not -BeNullOrEmpty
        $inst | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Server'
    }
}

describe "Web folder is empty" {
    it "Web folder should not have any files" {
        $webFiles = Get-ChildItem -Path ./web/* -ErrorAction SilentlyContinue
        $webFiles | Should -BeNullOrEmpty
    }
}

describe "Fabric Workspaces" {
    it "Should have at least one Fabric Workspace" {
        $workspaces = Get-FabricWorkspace
        $workspaces | Should -Not -BeNullOrEmpty
    }
}

