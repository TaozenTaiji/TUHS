# Instead of:
#"${env:HOMEDRIVE}${env:HOMEPATH}"

# Use the following to reference the user's home/profile directory:
#[Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)
function Find-ADGroup{

[CmdletBinding()]
param (
    [Parameter()]
    [String]
    $Search
)
    $filter = '*' + $search + '*'
    get-adgroup -filter {name -like $filter}
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
    Get-CMTaskSequence -TaskSequencePackageId $PackageID -Fast
}
function Add-DeviceToCollection
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [String]
        $CollectionName,
        [Parameter()]
        [String]
        $DeviceName
    )
    set-location TUH:
    $collectionID = (Get-CMCollection -name $CollectionName).collectionID
    $resourceID = (Get-CMDevice -name $DeviceName).resourceid
    add-cmdevicecollectiondirectmembershiprule -collectionid $collectionID -resourceid $resourceID
}

Function Get-SCCMDeviceLogs
{[CmdletBinding()]
    param (
        [Parameter()]
        [String]
        $DeviceName
    )
        Copy-Item -Path \\$DeviceName\C$\Windows\CCM\logs -Destination C:\Temp\$DeviceName\ -recurse
}