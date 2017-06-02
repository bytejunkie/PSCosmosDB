## PSCosmosDB

### This is a library of Powershell commands which can be used to interact with Cosmos DB.

### Feel free to create issues if you find any. Or request which command you need me to add next, as this library will be filled out sporadically. 


#### Notes on Usage

Clone the codebase
```
git clone https://github.com/bytejunkie/pscosmosdb
```

Import the module
```powershell
import-module .\PSCosmosDB.psm1 -force -verbose
```

setup some variables
```powershell
# the accountName used for the Cosmos DB account. 
$accountName = "bytejunkie"
# The ReadWrite access key if you need to make changes or add to. 
$primaryAccessKey = "weflnweflwef/.wecwef./wfwef/=="

```

query away...

### list databases
```powershell
Get-CosmosDatabases -AccountName $accountName -PrimaryAccessKey $primaryAccessKey
```

### add a database
```powershell
New-CosmosDBDatabase -AccountName $accountName -PrimaryAccessKey $primaryAccessKey `
                        -NewDBName <insert_db_name_here>
```

### list collections
```powershell
Get-CosmosDBCollections -AccountName $accountName -PrimaryAccessKey $primaryAccessKey `
                            -DBName <insert_db_name_here>
```
### add a collection
```powershell
New-CosmosDBCollection -AccountName $accountName -PrimaryAccessKey $primaryAccessKey `
                            -DBName <insert_db_name_here> `
                            -newCollectionName <insert_collection_name_here> `
                            -xmsofferthroughput <insert_offer_throughput_here>
```

### list documents
```powershell
Get-CosmosDBDocuments -AccountName $accountName -PrimaryAccessKey $primaryAccessKey `
                            -DBName <insert_db_name_here> `
                            -CollectionName <insert_collection_name_here> `
                            -xmsmaxitemcount <insert_max_item_count_here>
```

### add a document
```powershell
New-CosmosDBDocument -AccountName $accountName -PrimaryAccessKey $primaryAccessKey `
                            -DBName <insert_db_name_here> `
                            -CollectionName <insert_collection_name_here> `
                            -xmsmaxitemcount <insert_max_item_count_here> `
                            -Document <insert_JSON_document_here>
```

