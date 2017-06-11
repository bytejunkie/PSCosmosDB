    function Get-DocumentDBDocuments {
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
            [int]$xmsmaxitemcount = 50

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

    function New-DocumentDBDocument {
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
            [string]$document
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
        #write-host $collectionName

        #write-host $document
        #foreach ($header in $headers.GetEnumerator()) { write-host $header}

        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $document -ContentType 'application/json'

    }


