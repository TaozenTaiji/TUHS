
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
    new-PSDrive -Name "SCCM" -PSProvider "CMSite" -root "tssccmmgtprd01.tuhs.prv" -Description "Primary Site"
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
    Set-location SCCM:

    try
     {
        Get-CMPackage $PackageID
    }
    catch 
    {
        try 
        {
            Get-CMDeploymentPackage $PackageID
        }
        catch 
        {
            try 
            {
                Get-CMSoftwareUpdateDeploymentPackage $PackageID
            }
            catch 
            {
                Get-CMDriverPackage $PackageID
            }
        }
    }
}
    
    