function Get-TKAzureApplicationRegistration {
<#
.Synopsis
   Lists the Application Registrations in the tenant.
.DESCRIPTION
   Lists the Application Registrations in the tenant. This function requires the PnP.PowerShell module. It also requires you to connect to your tenant with Connect-PnPOnline before you run it. It uses the https://graph.microsoft.com/v1.0/applications Graph Endpoint.
.EXAMPLE
   Get-TKAzureApplicationRegistration

   Lists all the Application Registrations

.EXAMPLE
    Get-TKAzureApplicationRegistration | Format-List

    Lists the Application Registrations and shows their id and appId properties.
#>
    [CmdletBinding()]
    param (
        
    )
    
    begin {
        
    }
    
    process {
        $AppRegList = (Invoke-PnPGraphMethod -Url https://graph.microsoft.com/v1.0/applications).value
        Write-Verbose "Getting App Reg List"
        foreach ($AppReg in $AppRegList) {
            Write-Verbose "Getting $($AppReg.displayName) "
            [PSCustomObject]@{
                PSTypeName  = 'TKAzureApplicationRegistration'
                displayName = $AppReg.displayName
                id = $AppReg.id
                appId =$AppReg.appId
            }
        }
    }
    
    end {
        
    }
}

function Get-TKAzureApplicationRegistrationExtensionProperty {
<#
.Synopsis
   Lists the Extended Properties for a given Azure App Reg
.DESCRIPTION
   Lists the Extended Properties for a given Azure App Reg. This function requires the PnP.PowerShell module. It also requires you to connect to your tenant with Connect-PnPOnline before you run it. It uses the https://graph.microsoft.com/v1.0/applications Graph Endpoint.
.EXAMPLE
   Get-TKAzureApplicationRegistration | Format-List

    displayName : ToddsExtensionAttributes
    id          : 058e677c-ff88-439f-9f7f-0bf864af90bf
    appId       : f930f377-6804-4868-b4d9-9e74b4a3031c

    Get-TKAzureApplicationRegistrationExtensionProperty -id 058e677c-ff88-439f-9f7f-0bf864af90bf

    name                                                      appDisplayName dataType targetObjects
    ----                                                      -------------- -------- -------------
    extension_f930f37768044868b4d99e74b4a3031c_Test02withOBJs                String   {User}
    extension_f930f37768044868b4d99e74b4a3031c_Test01                        String   {User}

    Lists all the Extension Properties for the App Reg called ToddsExtensionAttributes

#>    
    [CmdletBinding()]
    param (
        # id Property of the Application Registration
        [Parameter(Mandatory=$true)]$id # The id of the App Registration
    )
    
    begin {
        
    }
    
    process {
        $ExtensionPropertyList = (Invoke-PnPGraphMethod -Url https://graph.microsoft.com/v1.0/applications/$id/extensionProperties).value 

        foreach ($ExtensionProperty in $ExtensionPropertyList) {
            [PSCustomObject]@{
                PSTypeName  = 'TKAzureApplicationRegistrationExtensionProperty'
                name = $ExtensionProperty.name
                appDisplayName = $ExtensionProperty.appDisplayName
                dataType = $ExtensionProperty.dataType
                targetObjects = $ExtensionProperty.targetObjects
            }
        }


    }
    
    end {
        
    }
}

function Add-TKAzureApplicationRegistrationExtensionProperty {
<#
.Synopsis
   Adds an Extension Property to an Application Registration.
.DESCRIPTION
   Adds an Extension Property to an Application Registration. This function requires the PnP.PowerShell module. It also requires you to connect to your tenant with Connect-PnPOnline before you run it. It uses the https://graph.microsoft.com/v1.0/applications/$id/extensionProperties Graph Endpoint.
.EXAMPLE
   $id = (Get-TKAzureApplicationRegistration | Where-Object -Property displayName -EQ -Value "ToddsExtensionAttributes").id
   Add-TKAzureApplicationRegistrationExtensionProperty -Name "TestExtensionProperty" -DataType String -TargetObjects User -id $id

   Adds an Extension Property called "TestExtionsionProperty" with the data type of String to the App Reg whose name is "ToddsExtensionAttributes"

#>        
    [CmdletBinding()]
    param (
        # The name of the Extension Property you want to create
        [Parameter(Mandatory,Position=0)][string]$Name, 
        # The type of content you want to store in the property
        [Parameter(Mandatory,Position=1)][ValidateSet("Binary", "Boolean", "DateTime","Integer","LargeInteger","String")][string]$DataType, 
        # The class of Azure AD Object want to be able to assign this property to
        [Parameter(Mandatory,Position=2)][ValidateSet("User", "group", "device","Integer","LargeInteger","String")][string]$TargetObjects, 
        # The id (not appId) of the Azure Application Registration you want to use to store this property
        [Parameter(Mandatory,Position=2)][string]$id
    )
    
    begin {
        
    }
    
    process {
        # DataTypes are Binary, Boolean, DateTime,Integer, LargeInteger, and String, https://learn.microsoft.com/en-us/previous-versions/azure/ad/graph/howto/azure-ad-graph-api-directory-schema-extensions
        # TargetObject types, https://learn.microsoft.com/en-us/graph/api/resources/directoryobject?view=graph-rest-1.0 
        $ContentObject = [pscustomobject]@{
            name = $Name
            dataType = $DataType
            targetObjects = $TargetObjects
        }
        $Content = $ContentObject | ConvertTo-Json

        Invoke-PnPGraphMethod -Url https://graph.microsoft.com/v1.0/applications/$id/extensionProperties -Method Post -Content $Content

    }
    
    end {
        
    }
}

function Set-TKAzureADUserExtenstionProperty {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=0)][string]$UPN, 
        [Parameter(Mandatory,Position=1)][string]$ExtensionProperty, 
        [Parameter(Mandatory,Position=2)]$Value 
    )
    
    begin {
        
    }
    
    process {
        $UserList = (Invoke-PnPGraphMethod -Url https://graph.microsoft.com/v1.0/users).value
        
        $User = $UserList | Where-Object -Property UserPrincipalName -EQ -Value $UPN
        # Check to see if User was found

        $UserID = $User.id

        $ContentObject = [pscustomobject]@{
            $ExtensionProperty = $Value
        }
        [string]$Content = $ContentObject | ConvertTo-Json 
        #$Content = '{"extension_f930f37768044868b4d99e74b4a3031c_Attorney": "true"}'
        Invoke-PnPGraphMethod -Url https://graph.microsoft.com/v1.0/users/$UserID -Method Patch -Content $Content

    }
    
    end {
        
    }
}

function Remove-TKAzureADUserExtenstionProperty {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=0)][string]$UPN, 
        [Parameter(Mandatory,Position=1)][string]$ExtensionProperty         
    )
    
    begin {
        
    }
    
    process {
        $UserList = (Invoke-PnPGraphMethod -Url https://graph.microsoft.com/v1.0/users).value
        
        $User = $UserList | Where-Object -Property UserPrincipalName -EQ -Value $UPN
        # Check to see if User was found

        $UserID = $User.id

        $ContentObject = [pscustomobject]@{
            $ExtensionProperty = $null
        }
        [string]$Content = $ContentObject | ConvertTo-Json 
        Invoke-PnPGraphMethod -Url https://graph.microsoft.com/v1.0/users/$UserID -Method Patch -Content $Content
        
    }
    
    end {
        
    }
}

function Get-TKAzureADUserExtenstionProperty {
<#
.Synopsis
   Returns all of the Extension Properties defined for a user.
.DESCRIPTION
   Returns all of the Extension Properties defined for a user. This function requires the PnP.PowerShell module. It also requires you to connect to your tenant with Connect-PnPOnline before you run it. It uses the https://graph.microsoft.com/beta/users/ Graph Endpoint.
.EXAMPLE
   Get-TKAzureADUserExtenstionProperty -UPN GradyA@1kgvf.onmicrosoft.com

Name                                                      Value
----                                                      -----
extension_f930f37768044868b4d99e74b4a3031c_Affirmation    Please work
extension_f930f37768044868b4d99e74b4a3031c_HireDate       2022-10-06T00:00:00Z

#>       
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,Position=0)][string]$UPN        
    )
    
    begin {
        
    }
    
    process {
        $UserList = (Invoke-PnPGraphMethod -Url https://graph.microsoft.com/v1.0/users).value
        
        $User = $UserList | Where-Object -Property UserPrincipalName -EQ -Value $UPN
        # Check to see if User was found

        $UserID = $User.id

        $UserProperties = Invoke-PnPGraphMethod -Url https://graph.microsoft.com/beta/users/$UserID 
        $ExtensionPropertyList = $UserProperties.psobject.Properties.Where({$_.Name -like "extension*"})

        foreach ($ExtensionProperty in $ExtensionPropertyList) {
            [PSCustomObject]@{
                PSTypeName = 'TKAzureADUserExtenstionProperty'
                Name = $ExtensionProperty.Name 
                Value = $ExtensionProperty.Value
            }
        }
    }
    
    end {
        
    }
}