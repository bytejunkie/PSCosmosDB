#
# This is a PowerShell Unit Test file.
# You need a unit test framework such as Pester to run PowerShell Unit tests.
# You can download Pester from http://go.microsoft.com/fwlink/?LinkID=534084
#


Describe "Get-CosmosDBDatabases" {
    Context "Function Works" {

        $returns = @{
            "id" = "database01";
            "_rid" = '2bkRAA==';
            "_self" = "dbs/2bkRAA==";
            "_etag" = "0000fd00-0000-0000-0000-58f9f907000";
            "_colls" = "colls/";
            "_users" = "users/";
            "_ts" = "1492777222";
        }

        Mock Invoke-RestMethod {
            param($uri, $method)
            return $returns

        } -Verifiable

        $splat = @{
            "uri" = "database01";
            "method" = 'get';
            }

        It "Returns a result" {
            {Get-CosmosDBDatabases @splat } | Should Not Be $null
        }
    }
    Context "Call to Emulator works" {
        
                $splat = @{
                    "emulatorAddress" = "https://172.18.168.172:8081/";
                    "primaryAccessKey" = "C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw==";
                    }
        
                It "Returns a result" {
                    {Get-CosmosDBDatabases @splat } | Should Not Be $null
                }
            }
}



Describe "Get-CosmosDBCollections" {
    Context "The Function Works" {
        $returns = @{
            "id" = "mattshortCollection3";
            "_rid" = "OIFDAPmD0QA=";
            "_ts" = "1503868413";
            "_self" = "dbs/OIFDAA==/colls/OIFDAPmD0QA=/";
            "_etag" = "00001500-0000-0000-0000-59a335fd0000";
            "_docs" = "docs/";
            "_sprocs" = "sprocs/";
            "_triggers" = "triggers/";
            "_udfs" = "udfs/";
            "_conflicts" = "conflicts/";
        }

        Mock Invoke-RestMethod {
            param($uri, $method)
            return $returns

        } -Verifiable

        $splat = @{
            "uri" = "database01";
            "method" = 'get';
            }

        It "Returns a result" {
            {Get-CosmosDBCollections @splat } | Should Not Be $null
        }
    }
}