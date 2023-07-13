# For blog post https://www.toddklindt.com/blog/Lists/Posts/Post.aspx?ID=899
# 7/13/2023
function Add-AttorneyFiles {
<#
.SYNOPSIS
   This function creates attorney files and case folders in a SharePoint directory in Microsoft 365.

.DESCRIPTION
   The Add-AttorneyFiles function creates a specified number of attorney files and case folders in a SharePoint directory. 
   It can create static files, and has options to create only closed cases or only client cases. 
   The name of the static file can be specified, and defaults to "readme.txt".

.PARAMETER AttorneyCount
   The number of attorney files to create. This parameter is mandatory.

.PARAMETER CaseCount
   The number of case folders to create for each attorney. This parameter is mandatory.

.PARAMETER CreateStaticFile
   If this switch is present, a static file will be created in each case folder.

.PARAMETER OnlyClosedCases
   If this switch is present, only closed case folders will be created.

.PARAMETER OnlyClientCases
   If this switch is present, only client case folders will be created.

.PARAMETER StaticFileName
   The name of the static file to create. Defaults to "readme.txt".

.EXAMPLE
   Add-AttorneyFiles -AttorneyCount 10 -CaseCount 5 -CreateStaticFile

   This will create 10 attorney files, each with 5 case folders. A static file named "readme.txt" will be created in each case folder.

.EXAMPLE
   Add-AttorneyFiles -AttorneyCount 5 -CaseCount 3 -OnlyClosedCases

   This will create 5 attorney files, each with 3 closed case folders. No static file will be created.

.EXAMPLE
   Add-AttorneyFiles -AttorneyCount 7 -CaseCount 4 -CreateStaticFile -StaticFileName "myfile.txt"

   This will create 7 attorney files, each with 4 case folders. A static file named "myfile.txt" will be created in each case folder.
#>
    Param(
        [Parameter(Mandatory=$true)]
        [int]$AttorneyCount,

        [Parameter(Mandatory=$true)]
        [int]$CaseCount,

        [Parameter(Mandatory=$false)]
        [switch]$CreateStaticFile,

        [Parameter(Mandatory=$false)]
        [switch]$OnlyClosedCases,

        [Parameter(Mandatory=$false)]
        [switch]$OnlyClientCases,

        [Parameter(Mandatory=$false)]
        [string]$StaticFileName = "readme.txt"
    )
    
    # Check if we're connected to a SharePoint site
    $connection = Get-PnPConnection
    if ($null -eq $connection) {
        Write-Error "Not connected to a SharePoint site. Use Connect-PnPOnline to connect."
        return
    }    

    $firstNames = @("John","Jane","James","Jill","Jack","Jenny","Jeff","Jasmine","Jeremy","Joan","Jacob","Julia","Joseph","Joyce","Jerry","Janet","Judith","Jose","Jean","Jocelyn", "Anna", "Brian", "Catherine", "David", "Emma", "Frank", "Grace", "Henry", "Irene", "Kyle", "Laura", "Michael", "Nina", "Oscar", "Paula", "Quincy", "Rachel", "Sam", "Tina", "Ursula", "Victor", "Wendy", "Xavier", "Yvonne", "Zach","Olivia","Ava","Sophia","Isabella","Liam","Alexander","Eric","Erik","Jakob","Mark","Marc","Gabriele","Vittoria")
    $lastNames = @("Smith", "Johnson", "Williams", "Jones", "Brown", "Davis", "Miller", "Wilson", "Moore", "Taylor", "Anderson", "Thomas", "Jackson", "White", "Harris", "Martin", "Thompson", "Garcia", "Martinez", "Robinson","Jones","Edwards","Sullivan","Rodriguez", "Johnson","Martinez","Gregory","Burke","Lopez","Campbell","Mullin","Park")

    $AttorneyList = @()
    while ($AttorneyList.Count -lt $AttorneyCount) {
        Write-Host "AttorneyList Count $($AttorneyList.Count) of $AttorneyCount"
        $potentialName = "$($lastNames | Get-Random), $($firstNames | Get-Random)"
        if ($potentialName -notin $AttorneyList) {
            write-host "Adding $potentialName"
            $AttorneyList += $potentialName
        }
    }

    $words = (New-Object Net.WebClient).DownloadString("http://svnweb.freebsd.org/csrg/share/dict/words?view=co&content-type=text/plain").Split("`n") | Where-Object { $_ -and ($_ -cne $_.ToUpper()) }

    foreach ($attorney in $AttorneyList) {
        Write-Verbose "Shared Documents/AttorneyFiles/$attorney"
        $attorneyFolderPath = Resolve-PnPFolder -SiteRelativePath "Shared Documents/AttorneyFiles/$attorney"

        $clientFilesFolderPath = $null
        if(!$OnlyClosedCases) {
            Write-Verbose "$($attorneyFolderPath.ServerRelativeUrl)/Client Files"
            $clientFilesFolderPath = Resolve-PnPFolder -SiteRelativePath "/Shared Documents/AttorneyFiles/$attorney/Client Files"
            Write-Verbose "Client Files Folder Path: $($clientFilesFolderPath.ServerRelativeUrl)"

        }

        $closedCasesFolderPath = $null
        if(!$OnlyClientCases) {
            Write-Verbose "$($attorneyFolderPath.ServerRelativeUrl)/Closed Cases"
            $closedCasesFolderPath = Resolve-PnPFolder -SiteRelativePath "/Shared Documents/AttorneyFiles/$attorney/Closed Cases"
            Write-Verbose "Closed Cases Folder Path: $($closedCasesFolderPath.ServerRelativeUrl)"

        }

        for ($i=0; $i -lt $CaseCount; $i++) {
            write-host "Case Count: $i of $CaseCount to $($attorney)"
            $randomWords = for ($j=0; $j -lt 200; $j++) {
                $words | Get-Random
            }

            if($CreateStaticFile) {
                $randomWords -join ' ' | Set-Content -Path $StaticFileName
            }

            $caseName = "$($lastNames | Get-Random), $($firstNames | Get-Random) - $(Get-Random -Minimum 100000 -Maximum 999999)"

            if ((Get-Random -Minimum 0 -Maximum 2) -eq 0 -and !$OnlyClientCases) {
                Write-Verbose "Closed Case"
                Add-PnPFolder -Folder $closedCasesFolderPath -Name $caseName
                if($CreateStaticFile) {
                    Add-PnPFile -Path $StaticFileName -Folder "Shared Documents/AttorneyFiles/$($attorney)/Closed Cases/$($caseName)"
                }
            } elseif(!$OnlyClosedCases) {
                Write-Verbose "Client File"
                Add-PnPFolder -Folder $clientFilesFolderPath -Name $caseName
                if($CreateStaticFile) {
                    Add-PnPFile -Path $StaticFileName -Folder "Shared Documents/AttorneyFiles/$($attorney)/Client Files/$($caseName)"
                }
            }
        }
    }
}
