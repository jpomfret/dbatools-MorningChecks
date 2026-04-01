# pester tests to make sure the environment is ready to go
$cred = New-Object System.Management.Automation.PSCredential ("sqladmin", (ConvertTo-SecureString "dbatools.IO" -AsPlainText -Force))
$instances = 'localhost,2500', 'localhost,2600'

describe "SQL Instances are alive" -ForEach $instances {
    it "Instance $psitem is alive" {
        $inst = Connect-DbaInstance -SqlInstance $psitem -SqlCredential $cred
        $inst | Should -Not -BeNullOrEmpty
        $inst | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Server'
    }
}

describe "Web folder is empty" {
    it "Web folder should not have any files" {
        $webFiles = Get-ChildItem -Path ./web/* -File -ErrorAction SilentlyContinue
        $webFiles | Should -BeNullOrEmpty
    }
}

# describe "testing the FPL token" {
#     BeforeAll{
#         #test using the token
#         $response = Invoke-WebRequest -Uri "https://fantasy.premierleague.com/api/my-team/4156860/" `
#             -Method GET `
#             -Headers @{ "Authorization" = "Bearer $FPLToken" }
#     }
#     it "FPL token should be set" {
#         $FPLToken | Should -Not -BeNullOrEmpty
#     }
#     it "FPL token should return a 200 status code" {
#         $response.StatusCode | Should -Be 200
#     }
#     it "FPL token should return picks" {
#         $picks = $response.Content | ConvertFrom-Json | select -ExpandProperty picks
#         $picks | Should -Not -BeNullOrEmpty
#     }
# }

# fabric not needed
# describe "Fabric Workspaces" {
#     it "Should have at least one Fabric Workspace" {
#         $workspaces = Get-FabricWorkspace
#         $workspaces | Should -Not -BeNullOrEmpty
#     }
# }

