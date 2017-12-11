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

## *NEW* Using the Tests
You should use a config file if you want the tests to run. 
Create a file called config.json in the tests folder.
The config file will take on of two formats.

### if you're running against the emulator
```
{
    "emulatorAddress": "https://192.168.1.1:8080/",
    "primaryAccessKey": "CX2lwneflwenfwelnflweknfls .adma.skdad=="
}
```
These details are given out by the emulator when it starts up. Dont forget to import the cert.
More info on the emulator [Cosmos DB Emulator](https://docs.microsoft.com/en-us/azure/cosmos-db/local-emulator)

### if you're running against an instance of Cosmos DB
```
{
    "accountName": "cosmosdb001",
    "resourceGroupName": "CosmosDBRGR001"
}
```

query away...

### list databases
```powershell
Get-CosmosDatabases -AccountName $accountName -PrimaryAccessKey $primaryAccessKey
```

### *NEW* check for a specific database
```powershell
Get-CosmosDatabases -AccountName $accountName -PrimaryAccessKey $primaryAccessKey -dbName $dbName
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

### *NEW* check for a specific collection
```powershell
Get-CosmosDBCollections -AccountName $accountName -PrimaryAccessKey $primaryAccessKey `
                            -DBName <insert_db_name_here> `
                            -collectionName <insert_collection_name_here> 
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

### *New* check for a specific document
```powershell
Get-CosmosDBDocuments -AccountName $accountName -PrimaryAccessKey $primaryAccessKey `
                            -DBName <insert_db_name_here> `
                            -CollectionName <insert_collection_name_here> `
                            -documentId <insert_documentId_here>
```

### add a document
```powershell
New-CosmosDBDocument -AccountName $accountName -PrimaryAccessKey $primaryAccessKey `
                            -DBName <insert_db_name_here> `
                            -CollectionName <insert_collection_name_here> `
                            -xmsmaxitemcount <insert_max_item_count_here> `
                            -Document <insert_JSON_document_here>
```

### List one or all Database Users
```powershell
# List all users
Get-CosmosDBDatabaseUser -AccountName $accountName -PrimaryAccessKey $primaryAccessKey `
                            -DBName <insert_db_name_here> `

#List single user with more info
Get-CosmosDBDatabaseUser -AccountName $accountName -PrimaryAccessKey $primaryAccessKey `
                            -DBName <insert_db_name_here> `
                            -User <insert_username> -moreinfo
```

### create a new Database User
```powershell
New-CosmosDBDatabaseUser -AccountName $accountName -PrimaryAccessKey $primaryAccessKey `
                            -DBName <insert_db_name_here> `
                            -User <insert_username> -moreinfo
```

### remove a Database User
```powershell
Remove-CosmosDBDatabaseUser -AccountName $accountName -PrimaryAccessKey $primaryAccessKey `
                            -DBName <insert_db_name_here> `
                            -User <insert_username> -moreinfo
```

### List one or all permissions for a certain user
```powershell
# List all permissions, with more info
Get-CosmosDBUserPermission -AccountName $accountName -PrimaryAccessKey $primaryAccessKey `
                            -DBName <insert_db_name_here> `
                            -User <insert_username> -moreinfo

# List a specific permission against a specific user, or return $false
Get-CosmosDBUserPermission -AccountName $accountName -PrimaryAccessKey $primaryAccessKey `
                            -DBName <insert_db_name_here> `
                            -User <insert_username> `
                            -PermissionId <insert_permission_id>
```

### create a new User Permission on a database
```powershell
New-CosmosDBUserPermission -AccountName $accountName -PrimaryAccessKey $primaryAccessKey `
                            -DBName <insert_db_name_here> `
                            -User <insert_username> `
                            -PermissionId <insert_permission_id> `
                            -PermissionMode <insert_permission_id> `
                            -PermissionResourceName <insert_permission_id>
```

### remove a User Permission on a database
```powershell
Remove-CosmosDBUserPermission -AccountName $accountName -PrimaryAccessKey $primaryAccessKey `
                            -DBName <insert_db_name_here> `
                            -User <insert_username> `
                            -PermissionId <insert_permission_id>
```
