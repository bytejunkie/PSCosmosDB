#
# This is a PowerShell Unit Test file.
# You need a unit test framework such as Pester to run PowerShell Unit tests.
# You can download Pester from http://go.microsoft.com/fwlink/?LinkID=534084
#

Describe "Get-DocumentDBDatabases" {
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
            {Get-DocumentDBDatabases @splat } | Should Not Be $null
        }
    }
}
