$here = (Split-Path -Parent $MyInvocation.MyCommand.Path) -replace '\\Tests', ''
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
$ModulePath = "$here\$sut" -replace 'ps1', 'psd1'

Import-Module -Name $ModulePath -Force -Verbose -ErrorAction Stop

$config = Get-Content "$here\tests\config.json" | ConvertFrom-Json

$environmentVariables = @{}

$config.psobject.properties | foreach {$environmentVariables[$_.Name] = $_.Value}


if ($environmentVariables.AccountName) {
    if ((get-azurermcontext).subscription.Id -like "") {write-host "Run Login-AzureRMAccount to login to Azure";break}
    $keys = Invoke-AzureRmResourceAction -Action listKeys `
        -ResourceType "Microsoft.DocumentDb/databaseAccounts" `
        -ApiVersion "2015-04-08" `
        -ResourceGroupName $environmentVariables.ResourceGroupName `
        -Name $environmentVariables.AccountName.toLower() `
        -Force -ErrorAction Stop
    $environmentVariables.Add("primaryAccessKey", $keys.primaryMasterKey)
    $environmentVariables.Remove('ResourceGroupName')
}

Describe "CosmosDB Database Commands" {

    Context "New-CosmosDBDatabase creates a new database" {

        It "creates a database" {
            New-cosmosdbDatabase @environmentVariables -dbname 'database02'
            Get-cosmosdbDatabase @environmentVariables -dbname 'database02' | Should be $true
        }

    }

    Context "Get-CosmosDBDatabases connects to account, returns info" {
    
        It "returns databases" {
            (Get-CosmosDBDatabase @environmentVariables ).count | Should BeGreaterThan 0
            }
        
        It "returns a single database" {
            Get-CosmosDBDatabase @environmentVariables -dbname 'database02' | Should not be $False
        }
    }

    Context "Remove-CosmodDBDatabase removes a CosmosDB Database" {
        It "removes a database" {
            Remove-CosmosDBDatabase @environmentVariables -DBName 'database02'
            Get-cosmosdbDatabase @environmentVariables -dbname 'database02' | Should be $false
        }
    }
}

Describe "New-CosmosDBCollection" {
    
    $environmentVariables.add( "dbname", 'database02' )
    # need to make sure there is a db to work on
    New-cosmosdbDatabase @environmentVariables
    
    Context "creates DB Collections" {
        It "creates a new Cosmos DB Collection" {
            for ($i = 1; $i -lt 5; $i++) {
                $collectionName =  ("collection{0:N}" -f $i.ToString("000")) 
                New-CosmosDBCollection @environmentVariables -CollectionName $collectionName
                
            }
            for ($i = 1; $i -lt 5; $i++) {
                $collectionName =  ("collection{0:N}" -f $i.ToString("000")) 
                Get-CosmosDBCollection @environmentVariables -CollectionName $collectionName | should not be $false
            }
        }

        It "creates a collection with ttl" {
            New-CosmosDBCollection @environmentVariables -CollectionName 'collection06' -defaultCollectionTTL '19080'
            (Get-CosmosDBCollection @environmentVariables -CollectionName 'collection06' -moreinfo).defaultTTL | Should Not benullorempty
        }
        It "creates a collection with partition key" {
            New-CosmosDBCollection @environmentVariables -CollectionName 'collection07' -partitionKey '/pkey'
            (Get-CosmosDBCollection @environmentVariables -CollectionName 'collection07' -moreinfo).partitionKey | Should Not benullorempty
        }

    }

    Context "Get-CosmosDBCollection" {
        It "returns collections" {
            (Get-CosmosDBCollection @environmentVariables).count | should BeGreaterThan 0
        }

        It "returns a single collection" {
            Get-CosmosDBCollection @environmentVariables -CollectionName "collection004" | Should Be $true
        }
    }

    Context "Remove-CosmosDBCollection" {
        It "removes a collection" {
            Remove-CosmosDBCollection @environmentVariables -CollectionName "collection002" 
            Get-CosmosDBCollection @environmentVariables -CollectionName "collection002" | Should Be $false
        }
    }
}

Describe "CosmosDBDatabaseUser commands" {

    It "creates a user" {
        New-CosmosDBDatabaseUser @environmentVariables -user "mattshort@callcredit" | Should Not Be $false
    }

    It "gets users" {
        Get-CosmosDBDatabaseUser @environmentVariables | should Not Be $False
    } # it needs work to be able to get specific users.

    It "removes a user" {
        Remove-CosmosDBDatabaseUser @environmentVariables -user "mattshort@callcredit" | should Not Be $False
    }
}


Describe "CosmosDBPermission commands" {
    # going to need to recreate a user.
    New-CosmosDBDatabaseUser @environmentVariables -user "mattshort@callcredit"

    It "creates a permission" {
    New-CosmosDBUserPermission @environmentVariables -user "mattshort@callcredit" -permissionId 'brand-new-permission' -permissionResourceName 'dbs/database02/colls/collection001'
    }
    
    It "Retrieves permissions" {
        Get-CosmosDBUserPermission @environmentVariables -user "mattshort@callcredit" | Should Not BeNullOrEmpty
    }

    It "Removes permissions" {
        Import-Module -Name $ModulePath -Force -Verbose -ErrorAction Stop
        Remove-CosmosDBUserPermission @environmentVariables -user "mattshort@callcredit" -permissionId 'brand-new-permission' | Should Not BeNullOrEmpty
    }
        }
    
# need to remove the db we created to work on
 Remove-cosmosdbDatabase @environmentVariables