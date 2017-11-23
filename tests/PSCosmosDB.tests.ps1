$here = (Split-Path -Parent $MyInvocation.MyCommand.Path) -replace '\\Tests', ''
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
$ModulePath = "$here\$sut" -replace 'ps1', 'psd1'

Import-Module -Name $ModulePath -Force -Verbose -ErrorAction Stop

$config = Get-Content "$here\tests\config.json" | ConvertFrom-Json

$mydbaccount = $config.accountName
$resourceGroupName = $config.ResourceGroupName
$keys = Invoke-AzureRmResourceAction -Action listKeys `
                                     -ResourceType "Microsoft.DocumentDb/databaseAccounts" `
                                    -ApiVersion "2015-04-08" `
                                    -ResourceGroupName $resourceGroupName `
                                    -Name $myDbAccount.toLower() `
                                    -Force -ErrorAction Stop
                                    
$primaryAccessKey = $keys.primaryMasterKey

$splat = @{
    "accountName" = $mydbaccount
    "primaryAccessKey" = $primaryAccessKey
}


Describe "CosmosDB Database Commands" {

    Context "New-CosmosDBDatabase creates a new database" {

        It "creates a database" {
            New-cosmosdbDatabase @splat -dbname 'database02'
            Get-cosmosdbDatabase @splat -dbname 'database02' | Should be $true
        }

    }

    Context "Get-CosmosDBDatabases connects to account, returns info" {
    
        It "returns databases" {
            (Get-CosmosDBDatabase @splat ).count | Should BeGreaterThan 0
            }
        
        It "returns a single database" {
            Get-CosmosDBDatabase @splat -dbname 'database02' | Should not be $False
        }
    }

    Context "Remove-CosmodDBDatabase removes a CosmosDB Database" {
        It "removes a database" {
            Remove-CosmosDBDatabase @splat -DBName 'database02'
            Get-cosmosdbDatabase @splat -dbname 'database02' | Should be $false
        }
    }
}

Describe "New-CosmosDBCollection" {
    
    $splat.add( "dbname", 'database02' )
    # need to make sure there is a db to work on
    New-cosmosdbDatabase @splat
    
    Context "creates DB Collections" {
        It "creates a new Cosmos DB Collection" {
            for ($i = 1; $i -lt 5; $i++) {
                $collectionName =  ("collection{0:N}" -f $i.ToString("000")) 
                write-host $collectionName
                New-CosmosDBCollection @splat -CollectionName $collectionName
                start-sleep -Seconds 5
                #Get-CosmosDBCollection @splat | should not be $false
            }
            
        }
    }

    Context "returns DB Collections" {
        It "returns collections" {
            (Get-CosmosDBCollection @splat).count | should BeGreaterThan 0
        }

        It "returns a single collection" {
            Get-CosmosDBCollection @splat -CollectionName "collection0" | Should Be $true
        }
    }

    Context "removes DB Collections" {
        It "removes a collection" {
            #Remove-CosmosDBCollection @splat -CollectionName "collection0" 
            #Get-CosmosDBCollection @splat -CollectionName "collection0" | Should Be $false
        }
    }

    # need to remove the db we created to work on
    Remove-cosmosdbDatabase @splat
}