$here = (Split-Path -Parent $MyInvocation.MyCommand.Path) -replace '\\Tests', ''
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
$ModulePath = "$here\$sut" -replace 'ps1', 'psd1'
$ModulePath

Import-Module -Name $ModulePath -Force -Verbose -ErrorAction Stop

$mydbaccount = 'euablddvcdb001'
$primaryAccessKey = 'NTLl8NWZEkE4VKgGStrWKupysFEyJlxWnFDf9nGOpQt3xEYnEeOrWJfe3JpY4kL8GfJx7WcNRYN5GGjqYWvRzA=='

Describe "Get-CosmosDBDatabase" {

    Context "Get-CosmosDBDatabases connects to account, returns info" {
        $splat = @{
            "accountName" = "euablddvcdb001"
            "primaryAccessKey" = "NTLl8NWZEkE4VKgGStrWKupysFEyJlxWnFDf9nGOpQt3xEYnEeOrWJfe3JpY4kL8GfJx7WcNRYN5GGjqYWvRzA=="
        }

        #New-cosmosdbDatabase -accountName $mydbaccount -primaryAccessKey $primaryAccessKey -dbname 'database01'
        #New-cosmosdbDatabase @splat -dbname 'database02'
    
        It "returns databases" {
            Get-CosmosDBDatabase -accountName $mydbaccount -primaryAccessKey $primaryAccessKey | Should not be null
            }
        
        It "returns a single database" {
            Get-CosmosDBDatabase -accountName $mydbaccount -primaryAccessKey $primaryAccessKey -dbname 'database01' | Should not be $False
        }
    }
}

Describe "New-CosmosDBDatabase" {

    Context "New-CosmosDBDatabase creates a database" {

        #New-cosmosdbDatabase -accountName $mydbaccount -primaryAccessKey $primaryAccessKey -dbname 'database03'

        It "created a database" {
            Get-CosmosDBDatabase -accountName $mydbaccount -primaryAccessKey $primaryAccessKey -DBName 'database03' | Should not be $False
        }


    }
}