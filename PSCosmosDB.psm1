$ErrorActionPreference = 'stop'

function New-AuthToken {

[CmdletBinding()]
Param(
    # The Verb portion of the string is the HTTP verb, such as GET, POST or PUT.
	[Parameter(Mandatory=$true)]
	[string]$verb,

    #The ResourceLink portion of the string is the identity property of the resource 
    # that the request is directed at. ResourceLink must maintain its case for the 
    # id of the resource. Example, for a collection it will look 
    # like: "dbs/MyDatabase/colls/MyCollection"
	[string]$resourceID,
    
    # The resourceType portion of the string identifies the type of resource that 
    # the request is for, Eg. "dbs", "colls", "docs"	
	[Parameter(Mandatory=$true)]
	[string]$resourceType = '',
    
    # The Date portion of the string is the UTC date and time the message was 
    # sent (in "HTTP-date" format as defined by RFC 7231 Date/Time Formats) e.g. 
    # Tue, 01 Nov 1994 08:12:31 GMT. In C#, this can be obtained by using the "R" 
    # format specifier on the DateTime.UtcNow value. This same date(in same format) 
    # also needs to be passed as x-ms-date header in the request.
	[Parameter(Mandatory=$true)]
	[string]$date,
    
    # The access key is obtained from the Docume DB resource in the azure portal.
    # https://portal.azure.com
	[Parameter(Mandatory=$true)]
	[string]$primaryAccessKey

) 
        
        $keyBytes = [System.Convert]::FromBase64String($primaryAccessKey) 

        # build resource body, convert to UTF8       
        $requestText = @($Verb.ToLowerInvariant() + `
            "`n" + $resourceType.ToLowerInvariant() + `
            "`n" + $resourceID + `
            "`n" + $Date.ToLowerInvariant() + `
            "`n" + "`n")
        $requestBody =[Text.Encoding]::UTF8.GetBytes($requestText)

        # hash the body
        $hmacsha = new-object -TypeName System.Security.Cryptography.HMACSHA256 -ArgumentList (,$keyBytes) 
        $hash = $hmacsha.ComputeHash($requestBody)

        # create and return the signature in base64        
        $signature = [System.Convert]::ToBase64String($hash)
        [System.Web.HttpUtility]::UrlEncode($('type=master&ver=1.0&sig=' + $signature))
    }
 
    function Get-UTDate {
        $date = get-date
        $date = $date.ToUniversalTime()
        return $date.ToString("ddd, dd MMM yyyy HH:mm:ss \G\M\T")
    }
 
     function Get-Headers {
        [CmdletBinding()]
        Param(
            [string]$action = "get",
            [string]$resourceType, 
            [string]$resourceID,
            [string]$primaryAccessKey,
            [string]$date = (Get-UTDate)

        )

        # call the function to generate the authToken
        $authToken = New-AuthToken -Verb $action -resourceType $resourceType -resourceID $resourceId -Date $date -primaryAccessKey $primaryAccessKey
        
        # create the headers, add the fields.
        $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $headers.Add("Authorization", $authToken)
        $headers.Add("x-ms-version", '2016-07-11')
        $headers.Add("x-ms-date", $date) 

        # how to output the headers to check they're building correctly
        # foreach ($header in $headers.GetEnumerator()) { write-host $header}

        return $headers
    }
   
    function Get-RootURI {
        [CmdletBinding()]
        Param(
        
            # the emulatorAddress to connect to
            [Parameter(ParameterSetName="emulatorAddress")]
            [string]$emulatorAddress, 
        
            # the account name to connect to
            [Parameter(ParameterSetName="accountName")]
            [string]$accountName
        )

        # the URI string for the Cosmos DB instance
        # we need to work out if we're working against the emulator or the cloud
        if ($emulatorAddress) { 
            $rootUri = $emulatorAddress
            } else {
                $rootUri =  'https://' + $accountName + '.documents.azure.com'
            }
        return $rootUri
    }
    
    function Get-CosmosDBDatabase{
        [CmdletBinding()]
        Param(
        
        # the account name to connect to
        [Parameter(ParameterSetName="accountName")]
        [string]$accountName, 

        # the emulatorAddress to connect to
        [Parameter(ParameterSetName="emulatorAddress")]
        [string]$emulatorAddress, 
             
        # primary Access Key for the doc DB instance
        [Parameter(Mandatory=$true)]
        [string]$primaryAccessKey,
        
        # are we looking for a specific database or a list of them?
        [string]$DBName,

        # have we been asked for more info
        [switch]$moreinfo = $false
        )

        # the URI string for the Cosmos DB instance
        # we need to work out if we're working against the emulator or the cloud
        if ($emulatorAddress) { 
            $rootUri = Get-RootURI -emulatorAddress $emulatorAddress
            } else {
                $rootUri = Get-RootURI -accountName $accountName
            }

        # build the URI
        $uri = $rootUri + "/dbs"

        # build the headers
        $headers = Get-Headers -resourceType dbs -primaryAccessKey $primaryAccessKey

        # issue the command
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
        
        # get the databases found to use later
        $databasesFound = $response.Databases.GetEnumerator() | sort-object id
        if ($DBName) {
            # we are looking for a specific database name
            if ($databasesFound.id -like $DBName) {
                write-host "$DBName found."
                return $true
                } else {
                    write-host "$DBName not Found"
                    return $false
                }
        } else {
            # we're not looking for a specific database
            Write-Host "Found $($Response._count) Database(s)"
            if ($moreinfo) {
                return $databasesFound
                }else{
                return $databasesFound.id
            }
        }
    }

    function New-CosmosDBDatabase {
        [CmdletBinding()]
        Param(
        
            # the dbName to add
            [Parameter(Mandatory=$true)]
            [string]$DBName,

            # the account name to connect to
            [Parameter(ParameterSetName="accountName")]
            [string]$accountName, 

            # the emulatorAddress to connect to
            [Parameter(ParameterSetName="emulatorAddress")]
            [string]$emulatorAddress, 

            # primary Access Key for the doc DB instance
            [Parameter(Mandatory=$true)]
            [string]$primaryAccessKey

        )

        # the URI string for the Cosmos DB instance
        # we need to work out if we're working against the emulator or the cloud
        if ($emulatorAddress) { 
            $rootUri = Get-RootURI -emulatorAddress $emulatorAddress
            } else {
                $rootUri = Get-RootURI -accountName $accountName
            }


        # build the URI
        $uri = $rootUri + '/dbs'

        # build the headers
        $headers = Get-Headers -action Post -resourceType dbs -primaryAccessKey $primaryAccessKey

        # when creating a db need to put the id into a document body. 
        $body = @{id=$DBName} | ConvertTo-Json

        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
        #write-host "$response.id created with rid $response._rid"
        if ($response.id -like $DBName) {
            Write-Host "Database created with id $($response.id)"
        }
        return $response
    }

    function Remove-CosmosDBDatabase {
        [CmdletBinding()]
        Param(
        
            # the dbName to be querying for collections
            [Parameter(Mandatory=$true)]
            [string]$DBName,

            # the account name to connect to
            [Parameter(ParameterSetName="accountName")]
            [string]$accountName, 

            # the emulatorAddress to connect to
            [Parameter(ParameterSetName="emulatorAddress")]
            [string]$emulatorAddress, 

            # primary Access Key for the doc DB instance
            [Parameter(Mandatory=$true)]
            [string]$primaryAccessKey
        )

        if ($emulatorAddress) { 
            $rootUri = Get-RootURI -emulatorAddress $emulatorAddress
            } else {
                $rootUri = Get-RootURI -accountName $accountName
            }

        # build the URI
        $uri = $rootUri + '/dbs/' + $dbName
        $resourceID = 'dbs/' + $dbname

        # build the headers
        $headers = Get-Headers -action Delete -resourceType dbs -resourceId $resourceID -primaryAccessKey $primaryAccessKey

        $response = Invoke-RestMethod -Uri $uri -Method Delete -Headers $headers
        write-host $response
    }

    function Get-CosmosDBCollection {
        [CmdletBinding()]
        Param(
        
            # the dbName to be querying for collections
            [Parameter(Mandatory=$true)]
            [string]$DBName,

            # the account name to connect to
            [Parameter(ParameterSetName="accountName")]
            [string]$accountName, 

            # the emulatorAddress to connect to
            [Parameter(ParameterSetName="emulatorAddress")]
            [string]$emulatorAddress, 

            # primary Access Key for the doc DB instance
            [Parameter(Mandatory=$true)]
            [string]$primaryAccessKey,

            # are we looking for a specific database or a list of them?
            [string]$collectionName,

            # have we been asked for more info
            [switch]$moreinfo = $false
    
        )

        # the URI string for the Cosmos DB instance
        # we need to work out if we're working against the emulator or the cloud
        if ($emulatorAddress) { 
            $rootUri = $emulatorAddress
            } else {
                $rootUri =  'https://' + $accountName + '.documents.azure.com'
            }

        # build the URI
        $uri = $rootUri + '/dbs/' + $dbname + '/colls'
        $resourceID = 'dbs/' + $dbname

        # build the headers
        $headers = Get-Headers -resourceType colls -resourceID $resourceID -primaryAccessKey $primaryAccessKey
        #write-host $uri
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
 
        # get the databases found to use later
        $collectionsFound = $response.DocumentCollections.GetEnumerator() | sort-object id
        if ($collectionName) {
            # we are looking for a specific database name
            if ($collectionsFound.id -like $collectionName) {
                if ($moreinfo) {
                    write-host "$collectionName found."
                    return $collectionsFound | Where-Object { $_.id -like $collectionName }
                } else {
                    return $true
                }
            } else {
                write-host "$collectionName not Found"
                return $false
            }
        } else {
            # we're not looking for a specific database
            Write-Host "Found $($Response._count) Collection(s)"
            return $collectionsFound.id
        }

    }

    function New-CosmosDBCollection {
        [CmdletBinding()]
        Param(
            # the dbName to add a collection to
            [Parameter(Mandatory=$true)]
            [string]$DBName,

            # the collection to add the db to
            [Parameter(Mandatory=$true)]
            [string]$CollectionName,

            # the account name to connect to
            [Parameter(ParameterSetName="accountName")]
            [string]$accountName, 

            # the emulatorAddress to connect to
            [Parameter(ParameterSetName="emulatorAddress")]
            [string]$emulatorAddress, 

            # primary Access Key for the doc DB instance
            [Parameter(Mandatory=$true)]
            [string]$primaryAccessKey,

            # x-ms-offer-throughput needed to size the new collection
            [Parameter()]
            $xmsofferthroughput = '400',

            [Parameter()]
            [int]$defaultCollectionTTL,

            [Parameter()]
            [string]$partitionKey

        )

        # the URI string for the Cosmos DB instance
        # we need to work out if we're working against the emulator or the cloud
        if ($emulatorAddress) { 
            $rootUri = $emulatorAddress
            } else {
                $rootUri =  'https://' + $accountName + '.documents.azure.com'
            }

        # build the URI that we are sending the request to
        $uri = $rootUri + '/dbs/' + $DBName + '/colls'
        $resourceID = 'dbs/' +  $DBName

        # build the headers
        $headers = Get-Headers -action Post -resourceType colls -resourceID $resourceID -primaryAccessKey $primaryAccessKey
        # add in the sizing variable
        $headers.Add("x-ms-offer-throughput",$xmsofferthroughput)

        # create a default indexing pattern
        $indexObject = @{
            indexingMode = 'Consistent';
            automatic = $true;
            includedPaths = @( @{
                path = "/*";
                indexes = @(
                    @{
                        kind = "Range";
                        dataType = "Number";
                        precision = -1
                    },
                    @{
                        kind = "Range";
                        dataType = "String";
                        precision = -1
                    },
                    @{
                        kind = "Spatial";
                        dataType = "Point"
                    }
                )
            });
        }


        # when creating a db need to put the id into a document body. 
        $body = @{
            id=$CollectionName;
            indexingPolicy=$indexObject
        }
        
        foreach ($key in $partitionKey) {
            $partitionKeys = @()
            $partitionKeys += $key
        }


        if ($defaultCollectionTTL) { $body.Add('defaultTtl', $defaultCollectionTTL) }
        if ($partitionKey) {
            $partitionKeyObject = @{
                "paths" = $partitionKeys;
                "kind" = 'hash';
            }
            $body.Add('partitionKey', $partitionKeyObject)
        } 

        $JsonBody = $body | ConvertTo-Json -Depth 10

        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $JsonBody
        $response.id
    }

    function Remove-CosmosDBCollection {
        [CmdletBinding()]
        Param(
        
            # the dbName to be querying for collections
            [Parameter(Mandatory=$true)]
            [string]$DBName,

            # the account name to connect to
            [Parameter(ParameterSetName="accountName")]
            [string]$accountName, 

            # the emulatorAddress to connect to
            [Parameter(ParameterSetName="emulatorAddress")]
            [string]$emulatorAddress, 

            # primary Access Key for the doc DB instance
            [Parameter(Mandatory=$true)]
            [string]$primaryAccessKey,

            # the collection name we are looking to remove
            [string]$collectionName

        )

        # the URI string for the Cosmos DB instance
        # we need to work out if we're working against the emulator or the cloud
        if ($emulatorAddress) { 
            $rootUri = $emulatorAddress
            } else {
                $rootUri =  'https://' + $accountName + '.documents.azure.com'
            }

        # build the URI
        $uri = $rootUri + '/dbs/' + $dbname + '/colls/' + $collectionName
        $resourceID = 'dbs/' + $dbname + '/colls/' + $collectionName

        # build the headers
        $headers = Get-Headers -action Delete -resourceType colls -resourceID $resourceID -primaryAccessKey $primaryAccessKey
        #write-host $uri
        $response = Invoke-RestMethod -Uri $uri -Method Delete -Headers $headers
        $response


    }

    function Get-CosmosDBDocument {
        [CmdletBinding()]
        Param(    

            # the dbName to add a collection to
            [Parameter(Mandatory=$true)]
            [string]$DBName,

            # the collection to add the db to
            [Parameter(Mandatory=$true)]
            [string]$collectionName,

            # the account name to connect to
            [Parameter(ParameterSetName="accountName")]
            [string]$accountName, 

            # the emulatorAddress to connect to
            [Parameter(ParameterSetName="emulatorAddress")]
            [string]$emulatorAddress, 

            # primary Access Key for the doc DB instance
            [Parameter(Mandatory=$true)]
            [string]$primaryAccessKey,

            # maximum number of items to return
            [int]$xmsmaxitemcount = 50,

            # document id if looking for a single document
            [string]$documentID
        )

        # the URI string for the Cosmos DB instance
        # we need to work out if we're working against the emulator or the cloud
        if ($emulatorAddress) { 
            $rootUri = $emulatorAddress
            } else {
                $rootUri =  'https://' + $accountName + '.documents.azure.com'
            }

        # build the URI
        $uri = $rootUri + '/dbs/' + $dbname + '/colls/' + $collectionName + '/docs/'
        $resourceID = 'dbs/' + $dbName + '/colls/' + $collectionName

        # build the headers
        $headers = Get-Headers -resourceType docs -resourceID $resourceID -primaryAccessKey $primaryAccessKey
        $headers.Add("x-ms-max-item-count",$xmsmaxitemcount)

        #write-host $uri
        #write-host $resourceID
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
 
        # get the databases found to use later
        $documentsFound = $response.Documents.GetEnumerator() | sort-object id
        if ($documentId) {
            # we are looking for a specific database name
            if ($documentsFound.id -like $documentId) {
                write-host "$documentId found."
                return $true
                } else {
                    write-host "$documentId not Found"
                    return $false
                }
            } else {
            # we're not looking for a specific database
            Write-Host "Found $($Response._count) Document(s)"
            return $documentsFound.id
        }    
    }

    function New-CosmosDBDocument {
        [CmdletBinding()]
        Param(

            # the dbName to add a collection to
            [Parameter(Mandatory=$true)]
            [string]$DBName,

            # the collection to add the db to
            [Parameter(Mandatory=$true)]
            [string]$collectionName,

            # the account name to connect to
            [Parameter(ParameterSetName="accountName")]
            [string]$accountName, 

            # the emulatorAddress to connect to
            [Parameter(ParameterSetName="emulatorAddress")]
            [string]$emulatorAddress, 

            # primary Access Key for the doc DB instance
            [Parameter(Mandatory=$true)]
            [string]$primaryAccessKey,

            # the JSON document to upload
            [string]$document

        )

        # the URI string for the Cosmos DB instance
        # we need to work out if we're working against the emulator or the cloud
        if ($emulatorAddress) { 
            $rootUri = $emulatorAddress
            } else {
                $rootUri =  'https://' + $accountName + '.documents.azure.com'
            }

        # build the URI that we are sending the request to
        $uri = $rootUri + '/dbs/' + $DBName + '/colls/' + $collectionName + '/docs'
        $collection = 'dbs/' + $DBName + '/colls/' + $collectionName

        # build the headers
        $headers = Get-Headers -action 'post' -resourceType 'docs' -resourceID $collection -primaryAccessKey $primaryAccessKey
        # add in the upsert header.
        $headers.Add("x-ms-documentdb-is-upsert", "true")

        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $document -ContentType 'application/json'
        write-host "Upserted document with id $($response.id)"
    }

    function Get-CosmosDBDatabaseUser {
        
                [CmdletBinding()]
                Param(
        
                    # the dbName to add a collection to
                    [Parameter(Mandatory=$true)]
                    [string]$DBName,
        
                    # the account name to connect to
                    [Parameter(ParameterSetName="accountName")]
                    [string]$accountName, 
        
                    # the emulatorAddress to connect to
                    [Parameter(ParameterSetName="emulatorAddress")]
                    [string]$emulatorAddress, 
        
                    # primary Access Key for the doc DB instance
                    [Parameter(Mandatory=$true)]
                    [string]$primaryAccessKey
        
                )

                <#
                .TODO 
                - this function needs to take a specific user and check for that user.
                - should also output more into on the user.

                #>

        
                # the URI string for the Cosmos DB instance
                # we need to work out if we're working against the emulator or the cloud
                if ($emulatorAddress) { 
                    $rootUri = $emulatorAddress
                    } else {
                        $rootUri =  'https://' + $accountName + '.documents.azure.com'
                    }
                
                # build the URI that we are sending the request to
                $uri = $rootUri + '/dbs/' + $DBName + '/users'
                $resourceID = 'dbs/' + $DBName
        
                # build the headers
                $headers = Get-Headers -action 'Get' -resourceType 'users' -resourceID $resourceID -primaryAccessKey $primaryAccessKey
        
                $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
                return $response
                
            }

    function New-CosmosDBDatabaseUser {

        [CmdletBinding()]
        Param(

            # the dbName to add a collection to
            [Parameter(Mandatory=$true)]
            [string]$DBName,

            # the account name to connect to
            [Parameter(ParameterSetName="accountName")]
            [string]$accountName, 

            # the emulatorAddress to connect to
            [Parameter(ParameterSetName="emulatorAddress")]
            [string]$emulatorAddress, 

            # primary Access Key for the doc DB instance
            [Parameter(Mandatory=$true)]
            [string]$primaryAccessKey,

            # the user to create
            [Parameter(Mandatory=$true)]
            [string]$user

        )

        # the URI string for the Cosmos DB instance
        # we need to work out if we're working against the emulator or the cloud
        if ($emulatorAddress) { 
            $rootUri = $emulatorAddress
            } else {
                $rootUri =  'https://' + $accountName + '.documents.azure.com'
            }
        
        $body = @{"id"=$user;} | ConvertTo-Json

        # build the URI that we are sending the request to
        $uri = $rootUri + '/dbs/' + $DBName + '/users'
        $resourceID = 'dbs/' + $DBName

        # build the headers
        $headers = Get-Headers -action 'Post' -resourceType 'users' -resourceID $resourceID -primaryAccessKey $primaryAccessKey

        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
        
    }

    function Remove-CosmosDBDatabaseUser {
        
        [CmdletBinding()]
        Param(

            # the dbName to add a collection to
            [Parameter(Mandatory=$true)]
            [string]$DBName,

            # the account name to connect to
            [Parameter(ParameterSetName="accountName")]
            [string]$accountName, 

            # the emulatorAddress to connect to
            [Parameter(ParameterSetName="emulatorAddress")]
            [string]$emulatorAddress, 

            # primary Access Key for the doc DB instance
            [Parameter(Mandatory=$true)]
            [string]$primaryAccessKey,

            # the user to remove
            [Parameter(Mandatory=$true)]
            [string]$user

        )

        # the URI string for the Cosmos DB instance
        # we need to work out if we're working against the emulator or the cloud
        if ($emulatorAddress) { 
            $rootUri = $emulatorAddress
            } else {
                $rootUri =  'https://' + $accountName + '.documents.azure.com'
            }
        
        # build the URI that we are sending the request to
        $uri = $rootUri + '/dbs/' + $DBName + '/users/' + $user
        $resourceID = 'dbs/' + $DBName+ '/users/' + $user

        # build the headers
        $headers = Get-Headers -action 'Delete' -resourceType 'users' -resourceID $resourceID -primaryAccessKey $primaryAccessKey

        $response = Invoke-RestMethod -Uri $uri -Method Delete -Headers $headers
        return $response
    }


    function Get-CosmosDBUserPermission {
                
        [CmdletBinding()]
        Param(

            # the account name to connect to
            [Parameter(ParameterSetName="accountName")]
            [string]$accountName, 

            # primary Access Key for the doc DB instance
            [Parameter(Mandatory=$true)]
            [string]$primaryAccessKey,

            # the emulatorAddress to connect to
            [Parameter(ParameterSetName="emulatorAddress")]
            [string]$emulatorAddress, 

            # the dbName to add a collection to
            [Parameter(Mandatory=$true)]
            [string]$DBName,

            # the user that we are adding the permission for 
            [Parameter(Mandatory=$true)]
            [string]$user

            )

        # the URI string for the Cosmos DB instance
        # we need to work out if we're working against the emulator or the cloud
        if ($emulatorAddress) { 
            $rootUri = $emulatorAddress
            } else {
                $rootUri =  'https://' + $accountName + '.documents.azure.com'
            }
        

    
        # build the URI that we are sending the request to
        $uri = $rootUri + '/dbs/' + $DBName + '/users/' + $user + '/permissions'
        $resourceID = 'dbs/' + $DBName + '/users/' + $user

        # build the headers
        $headers = Get-Headers -action 'Get' -resourceType 'permissions' -resourceID $resourceID -primaryAccessKey $primaryAccessKey

        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
        $response
    }

    function New-CosmosDBUserPermission {
        
                [CmdletBinding()]
                Param(
        
                    # the account name to connect to
                    [Parameter(ParameterSetName="accountName")]
                    [string]$accountName, 
        
                    # primary Access Key for the doc DB instance
                    [Parameter(Mandatory=$true)]
                    [string]$primaryAccessKey,

                    # the emulatorAddress to connect to
                    [Parameter(ParameterSetName="emulatorAddress")]
                    [string]$emulatorAddress, 
        
                    # the dbName to add a collection to
                    [Parameter(Mandatory=$true)]
                    [string]$DBName,
      
                    # the user that we are adding the permission for 
                    [Parameter(Mandatory=$true)]
                    [string]$user,

                    # the id to give the permission we are creating
                    [Parameter(Mandatory=$true)]
                    [string]$PermissionId,

                    # the permission mode to set on the resource
                    [Parameter()][ValidateSet("All","Read")]
                    [string]$PermissionMode = "read",

                    # the resource type that we are setting the permission against
                    [Parameter(Mandatory=$true)]
                    [string]$PermissionResourceName

                    )
        
                # the URI string for the Cosmos DB instance
                # we need to work out if we're working against the emulator or the cloud
                if ($emulatorAddress) { 
                    $rootUri = $emulatorAddress
                    } else {
                        $rootUri =  'https://' + $accountName + '.documents.azure.com'
                    }
                
                $body = @{"id"=$PermissionId;"permissionMode"=$PermissionMode;"resource"=$PermissionResourceName} | ConvertTo-Json
        
            
                # build the URI that we are sending the request to
                $uri = $rootUri + '/dbs/' + $DBName + '/users/' + $user + '/permissions'
                $resourceID = 'dbs/' + $DBName + '/users/' + $user
        
                # build the headers
                $headers = Get-Headers -action 'Post' -resourceType 'permissions' -resourceID $resourceID -primaryAccessKey $primaryAccessKey
        
                $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
                $response
            }
        