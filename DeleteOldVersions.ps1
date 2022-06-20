# Uncomment to see Verbose statements, set to "SilentyContinue" to hide them
# $VerbosePreference = "Continue" 

# Replace with your own Connect-PnPOnline statement
$SiteUrl = "https://m365x995492.sharepoint.com/sites/blah"
Connect-PnPOnline -Url $SiteUrl -Credentials AlexW

# Replace with the path to your own CSV file
$FileList = Import-Csv .\VersionDelete.csv
Write-Verbose "Found $($FileList.count) files in CSV file"

# Replace with the number of versions you want to keep
$VersionsToKeep = 5
Write-Verbose "Keeping $VersionsToKeep of each file"

foreach($File in $FileList) {
    # Remove site from Filename if it's there
    $Filename = $File.FileName.Replace($SiteUrl,"")
    Write-Verbose "Getting version for file $Filename"

    # Get the versions of each file
    $FileVersions = Get-PnPFileVersion -Url $Filename
    Write-Verbose "Found $($FileVersions.Count) versions"
    if ($FileVersions.Count -gt $VersionsToKeep) { # See if there are more than we want to keep

        # Pick the ones we want to remove
        $DeleteVersionList = ($FileVersions[0..$($FileVersions.Count - $VersionsToKeep)])
        Write-Verbose "More than $VersionsToKeep versions. Deleting $($DeleteVersionList.count)"

        foreach($VersionToDelete in $DeleteVersionList) {
            Write-Verbose "Removing $($VersionToDelete.VersionLabel)"
            # Remove the versions
            #Remove-PnPFileVersion -Url $Filename -Identity $VersionToDelete.Id -Force
            $Output = [PSCustomObject]@{
                PSTypeName = 'TKDeletedFileVersion'
                Filename     = $Filename 
                DeletedVersion     = $($VersionToDelete.VersionLabel) 
            }
            # Output the output
            $Output
        }
    } else {
        Write-Verbose "$Filename only had $($FileVersions.Count). Skipping..."
    }
}
