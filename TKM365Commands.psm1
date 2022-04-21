function Get-TKPnPGraphURI {
    <#
    .Synopsis
       Get information from the Graph API
    .DESCRIPTION
       Get information from the Graph API. This function requires the PnP.PowerShell module be installed and you are already connected with Connect-PnPOnline. Find Graph endpoints with the Graph Explorer at https://developer.microsoft.com/en-us/graph/graph-explorer From a blog post at https://www.toddklindt.com/blog Code based on the sample at https://pnp.github.io/script-samples/graph-call-graph/README.html 
       v1.0 - 4/15/22
    .EXAMPLE
       Get-TKPnPGraphURI -uri https://graph.microsoft.com/v1.0/me/
    .EXAMPLE
       Get-TKPnPGraphURI -uri https://graph.microsoft.com/beta/me/transitiveMemberOf/microsoft.graph.group?$count=true | select displayName, visibility
    .EXAMPLE
        Get-TKPnPGraphURI -uri https://graph.microsoft.com/beta/users/$count
        The command will automatically set ConsistencyLevel = Eventual in the headers if it sees $count or $search in the URI. Alternately you can use the -ConsistencyLevel parameter to set it manually.
    #>    
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true,HelpMessage = "URI of the Graph API Endpoint, e.g. https://graph.microsoft.com/v1.0/me/")]
            [ValidateNotNullOrEmpty()]
            [ValidatePattern("^http")]
            [uri]$uri,
            [ValidateSet("BoundedStaleness", "ConsistentPrefix", "Eventual","Session","Strong")]$ConsistencyLevel
            )
        
        begin {
            try {
                # Make sure we're connected
                Write-Verbose "Checking for PnP Connection..."
                Get-PnPConnection | Out-Null
            }
            catch {
                throw "No Connection Found. Please connect with Connect-PnPOnline"
            }
    
            try {
                Write-Verbose "Getting PnP Access Token..."
                $token = Get-PnPGraphAccessToken
            }
            catch {
                $_
                throw "Was unable to get a Graph Access Token"
            }
            # Terms that require ConsistencyLevel = eventual
            $TermsList = @('$count','$search')
        }
        
        process {
            try {
                Write-Verbose "Getting Me..."
                # Set the default headers
                $headers = @{"Authorization"="Bearer $($token)"}

                if ($ConsistencyLevel) {
                    # If the user passed a ConsistencyLevel parameter, use that
                    Write-Verbose "Setting ConsistencyLevel to $ConsistencyLevel"
                    $headers = @{'ConsistencyLevel' = $ConsistencyLevel;"Authorization"="Bearer $($token)"}
                } else {
                    # If not, see if we see one in the URI
                foreach ($term in $TermsList) {
                    Write-Verbose $term 
                    if ($uri -like "*$($term)*") {
                        Write-Verbose "Found term $($term) in URI. Adding ConsistencyLevel to Header"
                        $headers = @{'ConsistencyLevel' = "eventual";"Authorization"="Bearer $($token)"}
                    }
                    
                }
            }

                $me = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get -ContentType "application/json"
            }
            catch {
                $_
                throw "Error found"
            }
    
            if($null -eq $me.value) {
                Write-Verbose "Collection Returned"
                $me
            } else {
                Write-Verbose "Single Object returned"
                $($me.value)
            }
        }  
        end {
            
        }
    }

    function Get-TKPnPCurrentUser {
        [CmdletBinding()]
        param (
            [Parameter(HelpMessage = "Use the Graph API Endpoint https://graph.microsoft.com/v1.0/me/ to get the Current User's information instead of the SharePoint context")]
            [switch]$UseGraph,
            [Parameter(HelpMessage = "Use the Beat /beta/ Graph Endpoint instead of the /v1.0/ Endpoint. Used with -UseGraph parameter")]
            [switch]$UseBetaEndpoint
        )
        
        begin {
            
        }
        
        process {
            if ($UseGraph) {
                Write-Verbose "Using Graph endpoint"
                if ($UseBetaEndPoint) {
                    Write-Verbose "Using Beta Endpoit"
                    Get-TKPnPGraphURI -uri https://graph.microsoft.com/beta/me/
                } else {
                    Write-Verbose "Using v1.0 Endpoit"
                    Get-TKPnPGraphURI -uri https://graph.microsoft.com/v1.0/me/
                }
                
            } else {
                Write-Verbose "Using SharePoint Context"
                try {
                    $ctx = Get-PnPContext -ErrorAction Stop
                }
                catch {
                    $_
                    return
                }
                
                $ctx.Load($ctx.Web.CurrentUser)
                $ctx.ExecuteQuery()
                $CurrentUser = $ctx.Web.CurrentUser
        
                [PSCustomObject]@{
                    PSTypeName  = 'TKPnPCurrentUser'
                    ID = $CurrentUser.Id
                    Title = $CurrentUser.Title
                    LoginName = $CurrentUser.LoginName
                    Email = $CurrentUser.Email
                }
            }

        }
        
        end {
            
        }
    }