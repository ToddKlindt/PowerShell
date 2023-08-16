<#
.SYNOPSIS
This function stores SharePoint Online credentials for a given tenant using the PnP.PowerShell module.
Blog post at https://www.toddklindt.com/blog/Lists/Posts/Post.aspx?ID=900

.DESCRIPTION
The Add-ClientCredential function securely stores credentials for various SharePoint Online URLs.
If credentials for a given URL already exist, the function will display the associated username and 
prompt the user to confirm whether they want to replace the existing credentials.

.PARAMETER TenantName
The name of the SharePoint Online tenant. It can be in various formats like 'contoso', 'contoso.sharepoint.com', 
'contoso.onmicrosoft.com', 'https://contoso.sharepoint.com', or 'http://contoso.sharepoint.com'.

.PARAMETER UserName
The username for the SharePoint Online credentials.

.PARAMETER Password
The password for the SharePoint Online credentials, as a SecureString.

.PARAMETER TestCredential
A switch parameter that, when specified, will test the credentials after they are stored.

.EXAMPLE
Add-ClientCredential -TenantName "contoso" -UserName "user@contoso.com" -Password (ConvertTo-SecureString "YourPassword" -AsPlainText -Force) -TestCredential

.EXAMPLE
Add-ClientCredential
#>

function Add-ClientCredential {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string] $TenantName,

        [Parameter(Mandatory = $false)]
        [string] $UserName,

        [Parameter(Mandatory = $false)]
        [SecureString] $Password,

        [Parameter(Mandatory = $false)]
        [switch] $TestCredential
    )

    # Check if PnP.PowerShell module is installed
    $pnpModule = Get-Module -ListAvailable -Name PnP.PowerShell -ErrorAction SilentlyContinue
    if ($null -eq $pnpModule) {
        Write-Warning "The PnP.PowerShell module is not installed."
        Write-Output "To install the PnP.PowerShell module, run the following command:"
        Write-Output "Install-Module -Name PnP.PowerShell -Scope CurrentUser -Force -SkipPublisherCheck"
        return
    }

    if (-not $TenantName) {
        $TenantName = Read-Host "Please enter the Tenant Name"
    }

    # Normalize the tenant name to extract the base tenant name
    $TenantName = $TenantName -replace 'https://|http://|\.sharepoint\.com|\.onmicrosoft\.com', ''

    if (-not $UserName) {
        $UserName = Read-Host "Please enter the User Name"
    }

    if (-not $Password) {
        $Password = Read-Host "Please enter the Password" -AsSecureString
    }

    $urls = @(
        "https://$TenantName.sharepoint.com",
        "https://$TenantName.sharepoint.com/",
        "https://$TenantName-admin.sharepoint.com"
    )

    foreach ($url in $urls) {
        $existingCredential = Get-PnPStoredCredential -Name $url -ErrorAction SilentlyContinue

        if ($null -ne $existingCredential) {
            Write-Output "Existing credential found for $url with username: $($existingCredential.UserName)"
            $replace = Read-Host "Do you want to replace it? (Y/N)"
            if ($replace -eq 'Y' -or $replace -eq 'y') {
                $replace = $true
            } else {
                $replace = $false
            }

            if (-not $replace) {
                Write-Output "Skipping credential for $url."
                continue
            }
        }

        Add-PnPStoredCredential -Name $url -Username $UserName -Password $Password
        Write-Output "Credential for $url has been added."

        if ($TestCredential) {
            Connect-PnPOnline -Url $url -Credentials (Get-PnPStoredCredential -Name $url)
            if (Get-PnPContext) {
                Write-Output "Successfully connected to $url with stored credentials."
            } else {
                Write-Warning "Failed to connect to $url with stored credentials."
            }
        }
    }
}
