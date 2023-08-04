
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
    Set-location TUH:

    try
     {
        Get-CMPackage -packageID $PackageID -FAST
    }
    catch 
    {
        try 
        {
            Get-CMDeploymentPackage -packageID $PackageID
        }
        catch 
        {
            try 
            {
                Get-CMSoftwareUpdateDeploymentPackage -packageID $PackageID
            }
            catch 
            {
                Get-CMDriverPackage -packageID $PackageID
            }
        }
    }
}
    
    