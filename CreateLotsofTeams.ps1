<#
break
# for blog post https://www.toddklindt.com/blog/Lists/Posts/Post.aspx?ID=884
# Install the PowerShell module. Do this from an Admin PowerShell shell
# PnP.PowerShell version 1.6.0 has a bug that prevents the Teams from getting created. Use an older or newer version.
Install-Module PnP.PowerShell -MaximumVersion 1.5.0
Import-Module PnP.PowerShell -MaximumVersion 1.5.0
or 
Install-Module PnP.PowerShell -MinimumVersion 1.6.17-nightly -AllowClobber -AllowPrerelease -SkipPublisherCheck
Import-Module PnP.PowerShell -MinimumVersion 1.6.17

# Register the Azure App it needs. You can delete this after you're finished creating the Teams
Register-PnPManagementShellAccess
#>
# Connect to the Admin site. Put in your real tenant name
Connect-PnPOnline -Url https://CONTOSO-admin.sharepoint.com -Interactive

# import the files with nouns and adjectives
$Nouns = Get-Content .\nouns.txt
$Adjectives = Get-Content .\adjectives.txt

# Number of Teams to create
$NumberOfTeams = 3
$Index = 1

while ($Index -le $NumberOfTeams) {
    # Generate Random stuff
    $TeamNoun = $Nouns | Get-Random
    $TeamAdjective = $Adjectives | Get-Random
    $TeamNumber = Get-Random -Maximum 100
    $TeamDisplayName = "$TeamAdjective $TeamNoun $TeamNumber"
    Write-Host "$Index - $TeamDisplayName"
    New-PnPTeamsTeam -DisplayName $TeamDisplayName -MailNickName $($TeamDisplayName.Replace(" ","")) -Description $TeamDisplayName -Visibility Public -AllowGiphy $true 
    $Index++
}



