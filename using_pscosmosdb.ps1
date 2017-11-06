$emulatorAddress = 'https://172.18.171.78:8081'
$PrimaryAccessKey = 'C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw=='

push-location C:\Source\PSCosmosDB

Remove-Module PSCosmosDB
import-module .\PSCosmosDB.psd1 -force -Verbose

Get-CosmosDBDatabases -emulatorAddress $emulatorAddress -primaryAccessKey $PrimaryAccessKey
Get-CosmosDBDatabases -emulatorAddress $emulatorAddress -primaryAccessKey $PrimaryAccessKey -databaseName 'mattshort04'
Get-CosmosDBDatabases -emulatorAddress $emulatorAddress -primaryAccessKey $PrimaryAccessKey -databaseName 'mattshort08'
New-CosmosDBDatabase -emulatorAddress $emulatorAddress -primaryAccessKey $PrimaryAccessKey -newdbName 'mattshort04'

Get-CosmosDBCollections -DBName 'mattshort04' -emulatorAddress $emulatorAddress -primaryAccessKey $primaryAccessKey
# needs to handle the 404 when the DB isn't there?
Get-CosmosDBDocuments -DBName 'mattshort04' -emulatorAddress $emulatorAddress -primaryAccessKey $primaryAccessKey -collectionName 'mattshortCollection3'
New-CosmosDBCollection -DBName 'mattshort04' -emulatorAddress $emulatorAddress -primaryAccessKey $primaryAccessKey -newCollectionName 'mattshortCollection3'

Get-CosmosDBDocuments -DBName 'mattshort04' -emulatorAddress $emulatorAddress -primaryAccessKey $primaryAccessKey -CollectionName 'mattshortCollection3'



$document = @{
    "id" = [guid]::NewGuid();
    "mum" = "Anne-Marie";
    "dad" = "Matt";
} | ConvertTo-Json

Import-Module .\PSCosmosDB.psd1 -force -Verbose
Get-CosmosDBDocuments -DBName 'mattshort04' -emulatorAddress $emulatorAddress -primaryAccessKey $primaryAccessKey -collectionName 'mattshortCollection3'
New-CosmosDBDocument -DBName 'mattshort04' -emulatorAddress $emulatorAddress -primaryAccessKey $primaryAccessKey -collectionName 'mattshortCollection3' -document $document

###############################################
$databaseSeed = @("DB_A", "DB_B", "DB_C")
$CollectionSeed = @("Coll_1","Coll_2","Coll_3")

foreach ($dbSeed in $databaseSeed) {
    try {
            write-host $dbSeed
            Get-CosmosDBDatabases -emulatorAddress $emulatorAddress -primaryAccessKey $PrimaryAccessKey -databaseName $dbSeed
        } catch {
                   New-CosmosDBDatabase -emulatorAddress $emulatorAddress -primaryAccessKey $PrimaryAccessKey -newDBName $dbSeed
        }
    }













