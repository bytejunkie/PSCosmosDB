
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
    
        #Write-Host "Verb - " $verb
        #Write-Host "resource type - " $resourceType
        #Write-Host "resource ID - " $resourceID
        #Write-Host "Date - " $date
        #Write-host "Access key - " $primaryAccessKey
        
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
 
    function Get-UTDate() {
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
   
    
    function Get-CosmosDBDatabases{
        [CmdletBinding()]
        Param(
        
        # the account name to connect to
        [Parameter(Mandatory=$true)]
        [string]$accountName, 

        # primary Access Key for the doc DB instance
        [Parameter(Mandatory=$true)]
        [string]$primaryAccessKey
        ),

        # the URI string for the Cosmos DB instance
        [Parameter()]
        [string]$rootUri =  'https://' + $accountName + '.documents.azure.com'

        # build the URI
        $uri = $rootUri + "/dbs"
 
        # build the headers
        $headers = Get-Headers -resourceType dbs -primaryAccessKey $primaryAccessKey
 
        write-host $uri
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers 
        $response.Databases
 
        Write-Host ("Found " + $Response.Databases.Count + " Database(s)")
    }

    function New-CosmosDBDatabase {
        [CmdletBinding()]
        Param(
        
            # the dbName to add
            [Parameter(Mandatory=$true)]
            [string]$newDBName,

            # the account name to connect to
            [Parameter(Mandatory=$true)]
            [string]$accountName, 

            # primary Access Key for the doc DB instance
            [Parameter(Mandatory=$true)]
            [string]$primaryAccessKey,

            # the URI string for the Cosmos DB instance
            [Parameter()]
            [string]$rootUri =  'https://' + $accountName + '.documents.azure.com'

        )

        # build the URI
        $uri = $rootUri + '/dbs'

        # build the headers
        $headers = Get-Headers -action Post -resourceType dbs -primaryAccessKey $primaryAccessKey

        # when creating a db need to put the id into a document body. 
        $body = @{id=$newDBName} | ConvertTo-Json

        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
    }


    function Get-CosmosDBCollections {
        [CmdletBinding()]
        Param(
        
            # the dbName to be querying for collections
            [Parameter(Mandatory=$true)]
            [string]$dbName,

            # the account name to connect to
            [Parameter(Mandatory=$true)]
            [string]$accountName, 

            # primary Access Key for the doc DB instance
            [Parameter(Mandatory=$true)]
            [string]$primaryAccessKey,

            # the URI string for the Cosmos DB instance
            [Parameter()]
            [string]$rootUri =  'https://' + $accountName + '.documents.azure.com'

        ) 

        # build the URI
        $uri = $rootUri + '/dbs/' + $dbname + '/colls'
        $resourceID = 'dbs/' + $dbname

        # build the headers
        $headers = Get-Headers -resourceType colls -resourceID $resourceID -primaryAccessKey $primaryAccessKey
        write-host $uri
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
        $response.Documentcollections
 
        Write-Host ("Found " + $Response.DocumentCollections.Count + " Document collection(s)")
    }

    function New-CosmosDBCollection {
        [CmdletBinding()]
        Param(
            # the dbName to add a collection to
            [Parameter(Mandatory=$true)]
            [string]$DBName,

            # the collection to add the db to
            [Parameter(Mandatory=$true)]
            [string]$newCollectionName,

            # the account name to connect to
            [Parameter(Mandatory=$true)]
            [string]$accountName, 

            # primary Access Key for the doc DB instance
            [Parameter(Mandatory=$true)]
            [string]$primaryAccessKey,

            # x-ms-offer-throughput needed to size the new collection
            $xmsofferthroughput = '10000',

            # the URI string for the Cosmos DB instance
            [Parameter()]
            [string]$rootUri =  'https://' + $accountName + '.documents.azure.com'

    
        )
    
    
        # build the URI that we are sending the request to
        $uri = $rootUri + '/dbs/' + $DBName + '/colls'
        $resourceID = 'dbs/' +  $DBName
        # build the headers
        $headers = Get-Headers -action Post -resourceType colls -resourceID $resourceID -primaryAccessKey $primaryAccessKey
        # add in the sizing variable
        $headers.Add("x-ms-offer-throughput",$xmsofferthroughput)

        # when creating a db need to put the id into a document body. 
        $body = @{id=$newCollectionName} | ConvertTo-Json
               
        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
    }

    function Get-CosmosDBDocuments {
        [CmdletBinding()]
        Param(    

            # the dbName to add a collection to
            [Parameter(Mandatory=$true)]
            [string]$DBName,

            # the collection to add the db to
            [Parameter(Mandatory=$true)]
            [string]$collectionName,

            # the account name to connect to
            [Parameter(Mandatory=$true)]
            [string]$accountName, 

            # primary Access Key for the doc DB instance
            [Parameter(Mandatory=$true)]
            [string]$primaryAccessKey,

            # maximum number of items to return
            [int]$xmsmaxitemcount = 50,

            # the URI string for the Cosmos DB instance
            [Parameter()]
            [string]$rootUri =  'https://' + $accountName + '.documents.azure.com'

        )

        # build the URI
        $uri = $rootUri + '/dbs/' + $dbname + '/colls/' + $collectionName + '/docs/'
        $resourceID = 'dbs/' + $dbName + '/colls/' + $collectionName

        # build the headers
        $headers = Get-Headers -resourceType docs -resourceID $resourceID -primaryAccessKey $primaryAccessKey
        $headers.Add("x-ms-max-item-count",$xmsmaxitemcount)

        write-host $uri
        write-host $resourceID
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
        $response.Documents
 
        #write-host $response
        Write-Host ("Found " + $Response.Documents.Count + " Document(s)")
    
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
            [Parameter(Mandatory=$true)]
            [string]$accountName, 

            # primary Access Key for the doc DB instance
            [Parameter(Mandatory=$true)]
            [string]$primaryAccessKey,

            # the JSON document to upload
            [string]$document,

            # the URI string for the Cosmos DB instance
            [Parameter()]
            [string]$rootUri =  'https://' + $accountName + '.documents.azure.com'

        )

        # build the URI that we are sending the request to
        $uri = $rootUri + '/dbs/' + $DBName + '/colls/' + $collectionName + '/docs'
        $collection = 'dbs/' + $DBName + '/colls/' + $collectionName

        # build the headers
        $headers = Get-Headers -action 'post' -resourceType 'docs' -resourceID $collection -primaryAccessKey $primaryAccessKey
        # add in the upsert header.
        $headers.Add("x-ms-documentdb-is-upsert", "true")

        write-host "uri - " $uri
        write-host "collection - " $collection
        write-host $collectionName

        write-host $document
        #foreach ($header in $headers.GetEnumerator()) { write-host $header}

        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $document -ContentType 'application/json'

    }


