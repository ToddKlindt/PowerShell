# Some on-prem goodies.
# Originally published at https://github.com/ToddKlindt/PowerShell
# Also check out https://www.toddklindt.com

function Get-TKSPServiceAccount {
    <#
    .Synopsis
       Gets all the accounts used for services by on-prem SharePoint Server.
    .DESCRIPTION
       Gets all the accounts used for services by on-prem SharePoint Server. Must be run on a SharePoint server by a local admin in an admin PowerShell window. Most of the functional code came from https://info.summit7.us/blog/retrieve-all-sharepoint-service-accounts-with-powershell. I prettied it up some, but all the props go to Michael Wilke. 
    .EXAMPLE
        Get-TKSPServiceAccount
    .EXAMPLE
        Get-TKSPServiceAccount | Sort-Object ServiceName
        
    Gets all of the service accounts and sorts them by service name.
    .EXAMPLE
        Get-TKSPServiceAccount | Export-Csv -Path .\output.csv -NoTypeInformation

    Gets all of the service accounts in the farm. It outputs the results into a CSV file called output.csv in the current directory.

    .EXAMPLE
        Get-TKSPServiceAccount | ConvertTo-Csv -NoTypeInformation | Tee-Object -File .\output.csv | ConvertFrom-Csv

    Gets all of the service accounts in the farm. It outputs the results into a CSV file called output.csv in the current directory and displays it on the screen at the same time.

    #>

    ##Requires -RunAsAdministrator
    [CmdletBinding()]
    [OutputType('TKSPSeviceAccount')]    
    param (
        
    )
    
    begin {

    }
    
    process {
        # Add the SharePoint snapin if it's not already here
        try {
            Add-PSSnapin Microsoft.SharePoint.PowerShell
        }
        catch {
            Write-Error "Could not add Microsoft.SharePoint.PowerShell snapin"
            return
        }

        #Get all accounts registered as managed accounts
        Write-Verbose "Getting Managed Accounts"
        $temp = Get-SPManagedAccount 
        foreach ($item in $temp) {
            write-verbose $item.Username
            $TempItem = [PSCustomObject]@{
                PSTypeName  = 'TKSPServiceAccount'
                ServiceName = 'Managed Account' 
                UserName    = $item.Username
            }
            $TempItem            
        }
        
        #Get Application Pool Accounts
        Write-Verbose "Getting SharePoint Application Pool Accounts"
        # First get web application app pool accounts
        $temp = Get-SPWebApplication -IncludeCentralAdministration | Select-Object -expand applicationpool | Select-Object name , username 
        
        # Then add the Service app app pool accounts
        $temp += $(Get-SPServiceApplicationPool | Select-Object name, @{Name = "Username"; Expression = { $_.ProcessAccountName } })
        
        foreach ($item in $temp) {
            Write-Verbose "$($item.name) - $($item.Username)"
            $TempItem = [PSCustomObject]@{
                PSTypeName  = 'TKSPServiceAccount'
                ServiceName = $item.name 
                UserName    = $item.Username
            }
            $TempItem
        }
        
        #Get all accounts running service applications
        Write-Verbose "Getting SharePoint Service Application Accounts"
        $temp = Get-SPServiceApplication | Select-Object DisplayName, applicationpool -expand applicationpool -EA 0 | Select-Object -Unique
        foreach ($item in $temp) {
            Write-Verbose "$($item.DisplayName) - $($item.ProcessAccountName)"
            $TempItem = [PSCustomObject]@{
                PSTypeName  = 'TKSPServiceAccount'
                ServiceName = $item.DisplayName 
                UserName    = $item.ProcessAccountName
            }   
            $TempItem
        }
        
        #Get User Profile sync account
        Write-Verbose "Getting SharePoint User Profile Sync Account"
        $caWebApp = [Microsoft.SharePoint.Administration.SPAdministrationWebApplication]::Local
        $configManager = New-Object Microsoft.Office.Server.UserProfiles.UserProfileConfigManager( $(Get-SPServiceContext $caWebApp.Sites[0].Url))
        $temp = $configManager | Select-Object -expand connectionmanager | Select-Object AccountUserName
        foreach ($item in $temp) {
            Write-Verbose $item.AccountUsername
            $TempItem = [PSCustomObject]@{
                PSTypeName  = 'TKSPServiceAccount'
                ServiceName = 'User Profile Sync Account'
                UserName    = $item.AccountUsername
            }
            $TempItem
        }
        
        $temp = Get-SPServiceInstance | Select-Object -expand service | ForEach-Object { if ( $_.ProcessIdentity -and $_.ProcessIdentity.GetType() -eq "String") { Select-Object -InputObject $_ -Property TypeName, @{Name = "UserName"; Expression = { $_.ProcessIdentity } } } elseif ($_.TypeName -eq "SharePoint Server Search") { Select-Object -InputObject $_ -Property TypeName, @{Name = "UserName"; Expression = { $_.ProcessIdentity } } } elseif ( $_.ProcessIdentity ) { Select-Object -InputObject $_ -Property TypeName, @{Name = "UserName"; Expression = { $_.ProcessIdentity.UserName } } } }
        
        foreach ($item in $temp) {
            Write-Verbose "$($item.TypeName) - $($item.UserName)"
            $TempItem = [PSCustomObject]@{
                PSTypeName  = 'TKSPServiceAccount'
                ServiceName = $item.TypeName 
                UserName    = $item.Username
            }
            $TempItem
        }
        
        #Get Services accounts
        Write-Verbose "Getting Accounts Running SharePoint Services"
        $temp = Get-WmiObject -Query "select * from win32_service where name LIKE 'SP%v4'" | Select-Object name, startname -Unique
        foreach ($item in $temp) {
            Write-Verbose "$($item.name) - $($item.Startname)"
            $TempItem = [PSCustomObject]@{
                PSTypeName  = 'TKSPServiceAccount'
                ServiceName = $item.name 
                UserName    = $item.Startname
            }
            $TempItem
        }
        
        $temp = Get-WmiObject -Query "select * from win32_service where name LIKE '%15'" | Select-Object name, startname -Unique
        foreach ($item in $temp) {
            Write-Verbose "$($item.name) - $($item.Startname)"
            $TempItem = [PSCustomObject]@{
                PSTypeName  = 'TKSPServiceAccount'
                ServiceName = $item.name 
                UserName    = $item.Startname
            }
            $TempItem
        }
        
        $temp = Get-WmiObject -Query "select * from win32_service where name LIKE 'FIM%'" | Select-Object name, startname
        foreach ($item in $temp) {
            Write-Verbose "$($item.name) - $($item.Startname)"
            $TempItem = [PSCustomObject]@{
                PSTypeName  = 'TKSPServiceAccount'
                ServiceName = $item.name 
                UserName    = $item.Startname
            }
            $TempItem
        }
        
        #Get Object Cache accounts
        Write-Verbose " Getting SharePoint Object Cache Accounts"
        $temp = Get-SPWebApplication | ForEach-Object { $_.Properties["portalsuperuseraccount"] }
        if (-not [string]::IsNullOrWhiteSpace($temp)) {
            foreach ($item in $temp) {
                Write-Verbose "portalsuperuseraccount - $($item)"
                $TempItem = [PSCustomObject]@{
                    PSTypeName  = 'TKSPServiceAccount'
                    ServiceName = 'portalsuperuseraccount'
                    UserName    = $item
                }
            }
        }
        
        $temp = Get-SPWebApplication | ForEach-Object { $_.Properties["portalsuperreaderaccount"] }
        if (-not [string]::IsNullOrWhiteSpace($temp)) {
            foreach ($item in $temp) {
                Write-Verbose "portalsuperreaderaccount - $($item)"
                $TempItem = [PSCustomObject]@{
                    PSTypeName  = 'TKSPServiceAccount'
                    ServiceName = 'portalsuperreaderaccount' 
                    UserName    = $item
                }
                $TempItem
            }
        }
        
        #Get default Search crawler account
        Write-Verbose "Getting SharePoint Search Crawler Account(s)"
        $temp = New-Object Microsoft.Office.Server.Search.Administration.content $(Get-SPEnterpriseSearchServiceApplication) | Select-Object DefaultGatheringAccount
        foreach ($item in $temp) {
            Write-Verbose $item.DefaultGatheringAccount
            $TempItem = [PSCustomObject]@{
                PSTypeName  = 'TKSPServiceAccount'
                ServiceName = 'Default SharePoint Search Crawler Account'
                UserName    = $item.DefaultGatheringAccount
            }
            $TempItem
        }
        #Get all search crawler accounts from crawl rules
        $rules = Get-SPEnterpriseSearchCrawlRule -SearchApplication (Get-SPEnterpriseSearchServiceApplication)
        foreach ($rule in $rules) {
            Write-Verbose $item.AccountName
            $TempItem = [PSCustomObject]@{
                PSTypeName  = 'TKSPServiceAccount'
                ServiceName = 'SharePoint Search Crawler Account'
                UserName    = $item.AccountName
            }
            $TempItem
        }
        
        #Get Unattended Accounts
        Write-Verbose "Getting Unattended Service Application ID Account(s)"
        $UnattendedAccounts = @()
        
        try {
            if (Get-SPVisioServiceApplication) {
                $svcapp = Get-SPServiceApplication | Where-Object { $_.TypeName -like "*Visio*" }
                $Visio = ($svcapp | Get-SPVisioExternalData).UnattendedServiceAccountApplicationID
                $TempItem = [PSCustomObject]@{
                    PSTypeName  = 'TKSPServiceAccount'
                    ServiceName = 'Viso Unattended ID Account'
                    UserName    = $Visio
                }
                $TempItem 
                $UnattendedAccounts += $Visio
            }
        }
        catch {
            # no action needed
        }
        
        try {
            if (Get-SPExcelServiceApplication) {
                $Excel = (Get-SPExcelServiceApplication).UnattendedAccountApplicationID
                $TempItem = [PSCustomObject]@{
                    PSTypeName  = 'TKSPServiceAccount'
                    ServiceName = 'Excel Unattended ID Account'
                    UserName    = $Excel
                }
                $TempItem 
                $UnattendedAccounts += $Excel
            }
        }
        catch {
            # no action needed
        }
        
        try {
            if (Get-SPPerformancePointServiceApplication) {
                $PerformancePoint = (Get-SPPerformancePointSecureDataValues -ServiceApplication $svcApp.Id).DataSourceUnattendedServiceAccount
                $TempItem = [PSCustomObject]@{
                    PSTypeName  = 'TKSPServiceAccount'
                    ServiceName = 'Performance Point Unattended ID Account'
                    UserName    = $PerformancePoint
                }
                $TempItem 
                $UnattendedAccounts += $PerformancePoint
            }
        }
        catch {
            # no action needed
        }
        
        try {
            if (Get-PowerPivotServiceApplication) {
                $PowerPivot = (Get-PowerPivotServiceApplication).UnattendedAccount
                $TempItem = [PSCustomObject]@{
                    PSTypeName  = 'TKSPServiceAccount'
                    ServiceName = 'Power Pivot Unattended ID Account'
                    UserName    = $PowerPivot
                }
                $TempItem 
                $UnattendedAccounts += $PowerPivot
            } 
        }
        catch {
            # no action needed
        }
        
        $serviceCntx = Get-SPServiceContext -Site (Get-SPWebApplication -includecentraladministration | Where-Object { $_.IsAdministrationWebApplication } | Select-Object -ExpandProperty Url)
        $sssProvider = New-Object Microsoft.Office.SecureStoreService.Server.SecureStoreProvider
        $sssProvider.Context = $serviceCntx
        $marshal = [System.Runtime.InteropServices.Marshal]
        
        try {
            
            $applications = $sssProvider.GetTargetApplications()
            
            foreach ($application in $applications | Where-Object { $UnattendedAccounts -contains $_.Name }) {
                $sssCreds = $sssProvider.GetCredentials($application.Name)
                foreach ($sssCred in $sssCreds | Where-Object { $_.CredentialType -eq "WindowsUserName" -or $_.CredentialType -eq "UserName" }) {
                    # Pretty sure this doesn't work. Need to create some Secure Store creds and test    
                    $ptr = $marshal::SecureStringToBSTR($sssCred.Credential)
                    $str = $marshal::PtrToStringBSTR($ptr)
                    $str + " (" + $application.Name + ")"
                    if (-not [string]::IsNullOrWhiteSpace($str)) {
                        $TempItem = [PSCustomObject]@{
                            PSTypeName  = 'TKSPServiceAccount'
                            ServiceName = 'Secure Store Account'
                            UserName    = $str
                        }
                        $TempItem 
                    } 
                    
                }
            }
            
        }
        catch {
            # no action needed
        }

        #Get All Farm administrators
        Write-Verbose "Getting Farm Administrators Group"
        $FarmAdministrators = Get-SPWebApplication -IncludeCentralAdministration | Where-Object IsAdministrationWebApplication | Select-Object -Expand Sites | Where-Object ServerRelativeUrl -eq "/" | Get-SPWeb | Select-Object -Expand SiteGroups | Where-Object Name -eq "Farm Administrators" | Select-Object -expand Users -Unique
        
        foreach ($FarmAdmin in $FarmAdministrators) {
            $TempItem = [PSCustomObject]@{
                PSTypeName  = 'TKSPServiceAccount'
                ServiceName = 'Farm Administrator'
                UserName    = $FarmAdmin.UserLogin
            }
            $TempItem 
        }        
    }
    
    end {
        
    }
}