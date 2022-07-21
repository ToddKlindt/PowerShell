# Re-index SPO user profiles script
# Author: Mikael Svenson - @mikaelsvenson
# Blog: http://techmikael.com

function Request-PnPReindexUserProfile {
<#
.SYNOPSIS
Script to trigger re-indexing of all user profiles

.Description
If you perform search schema mappings after profiles exist you have to update the last modified time on a profile for it to be re-indexed.
This script ensures all profiles are updated with a new time stamp. Once the import job completes allow 4-24h for profiles to be updated in search.

If used in automation replace Connect-PnPOnline with somethine which works for you.

A temp file will be created on the file system where you execute the command. That temp file will also be uploaded to the "Shared Documents" library in the site you pass in the -url parameter.

.Parameter url
The site you will use to host the import file. Can be any site you have write access to. DO NOT use the admin site.

.Example 
Request-PnPReindexUserProfile -url https://contoso.sharepoint.com

#>    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)][string]$url
    )
    
    begin {
        
    }
    
    process {
        # In case they didn't heed our warning and tried to use the Admin site
        $url = $url.Replace("-admin.",".")

        # Need the current location so we know where to save the temp file
        $tempPath = Get-Location

        # Make sure they have the PnP.PowerShell module installed
        $hasPnP = (Get-Module PnP.PowerShell -ListAvailable).Length
        if ($hasPnP -eq 0) {
            Write-Output "This script requires PnP PowerShell, please install it"
            Write-Output "Install-Module PnP.PowerShell"
            return
        }

        # Replace connection method as needed
        try {
            Connect-PnPOnline -Url $url -Interactive
        }
        catch {
            Write-Error "Could not connect to $url"
            Write-Error $_
            return
        }
        
        Write-Output "Retrieving all user profiles"
        try {
            $ProfileList = Submit-PnPSearchQuery -Query '-AccountName:spofrm -AccountName:spoapp -AccountName:app@sharepoint -AccountName:spocrawler -AccountName:spocrwl -PreferredName:"Foreign Principal"' -SourceId "b09a7990-05ea-4af9-81ef-edfab16c4e31" -SelectProperties "aadobjectid", "department", "write" -All -TrimDuplicates:$false -RelevantResults -ErrorAction Stop
        }
        catch {
            Write-Error "Error with Submit-PnPSearchQuery"
            Write-Error "Please check connection and permissions to $url and try again"
            Write-Error $_
            return
        }

        # Put the template file together
        $fragmentTemplate = "{{""IdName"": ""{0}"",""Department"": ""{1}""}}";
        $accountFragments = @();
        
        foreach ($Profile in $ProfileList) {
            $aadId =  $Profile.aadobjectid + ""
            $dept = $Profile.department + ""
            if(-not [string]::IsNullOrWhiteSpace($aadId) -and $aadId -ne "00000000-0000-0000-0000-000000000000") {
                $accountFragments += [string]::Format($fragmentTemplate,$aadId,$dept)
            }
        }

        Write-Output "Found $($accountFragments.Count) profiles"
        $json = "{""value"":[" + ($accountFragments -join ',') + "]}"
        
        $propertyMap = @{}
        $propertyMap.Add("Department", "Department")
        
        $filename = "upa-batch-trigger";
        $web = Get-PnPWeb
        $RootFolder = $web.GetFolderByServerRelativeUrl("/");
        
        # Cleanup
        $FileList = $RootFolder.Files
        $FolderList = $RootFolder.Folders
        Get-PnPProperty -ClientObject $RootFolder -Property Files,Folders
        
        foreach ($File in $FileList) {
            if($File.Name -like "*$filename*") {
                Write-Output "Remove old import file"
                $File.DeleteObject()
            }
        }
        
        foreach ($Folder in $FolderList) {
            if($Folder.Name -like "*$filename*") {
                Write-Output "Remove old import status folder"
                $Folder.DeleteObject()
            }
        }

        Invoke-PnPQuery
        # End cleanup

        Set-Content -Path "$tempPath\$filename.txt" -value $json

        Write-Output "Kicking off import job - Please be patient and allow for 4-24h before profiles are updates in search.`n`nDo NOT re-run because you are impatient!"
        try {
            $job = New-PnPUPABulkImportJob -UserProfilePropertyMapping $propertyMap -IdType CloudId -IdProperty "IdName" -Folder "Shared Documents" -Path "$tempPath\$filename.txt"
        }
        catch {
            Write-Error "Could not upload $tempPath\$($filename.txt) to $url"
            Write-Error $_
            return
        }
        
        Remove-Item -Path "$tempPath\$filename.txt"
        
        if(-not [string]::IsNullOrWhiteSpace($job)) {
            Write-Output "You can check the status of your job with: Get-PnPUPABulkImportStatus -JobId $($job.JobId)"
            $job
        }
                
    }
    
    end {
        
    }
}



