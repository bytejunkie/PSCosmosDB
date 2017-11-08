$here = (Split-Path -Parent $MyInvocation.MyCommand.Path) -replace '\\Tests', ''
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
$ModulePath = "$here\$sut" -replace 'ps1', 'psd1'
$ModulePath

Import-Module -Name $ModulePath -Force -Verbose -ErrorAction Stop

$config = Get-Content .\config.json | ConvertFrom-Json

$mydbaccount = $config.accountName
$resourceGroupName = $config.ResourceGroupName
$keys = Invoke-AzureRmResourceAction -Action listKeys `
                                     -ResourceType "Microsoft.DocumentDb/databaseAccounts" `
                                    -ApiVersion "2015-04-08" `
                                    -ResourceGroupName $resourceGroupName `
                                    -Name $myDbAccount.toLower() `
                                    -Force -ErrorAction Stop
                                    
$primaryMasterKey = $keys.primaryMasterKey

$splat = @{
    "accountName" = $mydbaccount
    "primaryMasterKey" = $primaryMasterKey
}


Describe "Get-CosmosDBDatabase" {

    Context "Get-CosmosDBDatabases connects to account, returns info" {

        #New-cosmosdbDatabase -accountName $mydbaccount -primaryAccessKey $primaryMasterKey -dbname 'database01'
        #New-cosmosdbDatabase @splat -dbname 'database02'
    
        It "returns databases" {
            Get-CosmosDBDatabase -accountName $mydbaccount -primaryAccessKey $primaryMasterKey | Should not be null
            }
        
        It "returns a single database" {
            Get-CosmosDBDatabase -accountName $mydbaccount -primaryAccessKey $primaryMasterKey -dbname 'database01' | Should not be $False
        }
    }
}

Describe "New-CosmosDBDatabase" {

    Context "New-CosmosDBDatabase creates a database" {

        #New-cosmosdbDatabase -accountName $mydbaccount -primaryAccessKey $primaryMasterKey -dbname 'database03'

        It "created a database" {
            Get-CosmosDBDatabase -accountName $mydbaccount -primaryAccessKey $primaryMasterKey -DBName 'database03' | Should not be $False
        }


    }
}