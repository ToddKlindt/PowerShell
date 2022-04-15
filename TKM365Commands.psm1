function Get-TKPnPGraphURI {
    <#
    .Synopsis
       Get information from the Graph API
    .DESCRIPTION
       Get information from the Graph API. This function requires the PnP.PowerShell module be installed and you are already connected with Connect-PnPOnline. Find Graph endpoints with the Graph Explorer at https://developer.microsoft.com/en-us/graph/graph-explorer From a blog post at https://www.toddklindt.com/blog
       v1.0 - 4/15/22
    .EXAMPLE
       Get-TKPnPGraphURI -uri https://graph.microsoft.com/v1.0/me/
    .EXAMPLE
       Get-TKPnPGraphURI -uri https://graph.microsoft.com/beta/me/transitiveMemberOf/microsoft.graph.group?$count=true | select displayName, visibility
    #>    
        [CmdletBinding()]
        param (
            # URI of the Graph API Endpoint. Something like https://graph.microsoft.com/v1.0/me/
            [Parameter(Mandatory=$true)]
            [uri]$uri
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
    
        }
        
        process {
            if([string]::IsNullOrWhiteSpace($uri)) {
                throw "No URI was passed"
            }
            try {
                Write-Verbose "Getting Me..."
                $me = Invoke-RestMethod -Uri $uri -Headers @{"Authorization"="Bearer $($token)"} -Method Get -ContentType "application/json"
            }
            catch {
                $_
                throw "Error found"
            }
    
            if($null -eq $me.value) {
                Write-Verbose "No Value"
                $me
            } else {
                Write-Verbose "Value"
                $($me.value)
            }
        }  
        end {
            
        }
    }