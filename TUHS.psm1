
function Find-ADGroup{

[CmdletBinding()]
param (
    [Parameter()]
    [String]
    $Search
)
    get-adgroup -filter {Name -like "*$Search*"}
}

function Install-SCCM
{
    Set-Location 'C:\Program Files (x86)\Microsoft Endpoint Manager\AdminConsole\bin'
    Import-Module .\ConfigurationManager.psd1
    new-PSDrive -Name "TUH" -PSProvider "CMSite" -root "tssccmmgtprd01.tuhs.prv" -Description "Primary Site"
    Update-Help -Module ConfigurationManager
}

function Get-SCCMPackage
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [String]
        $PackageID
    )
    If (Get-PSDrive "TUH" -ErrorAction SilentlyContinue)
    {
        set-location TUH:
    }
    else {
        Install-SCCM
        Set-location TUH:
    }


    Get-CMPackage -packageID $PackageID -FAST
  #  Get-CMDeploymentPackage -packageID $PackageID
    Get-CMSoftwareUpdateDeploymentPackage -packageID $PackageID
    Get-CMDriverPackage -packageID $PackageID -fast
}
    
    