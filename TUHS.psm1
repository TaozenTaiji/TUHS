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
 <#   if (!(test-path \\$DeviceName\C$\Windows\CCM\logs)) ::::Commented out until fully confident local admin works on all remote ssytems
    {
        if!(Get-PSSession -Name LocalAdmin)
        {
        New-pssession -Name LocalAdmin -Credential (Get-StoredCredential -target Admin)
        Remove-PSSession -Name LocalAdmin
        }
        invoke-command -Session LocalAdmin -ScriptBlock {Copy-Item -Path \\$DeviceName\C$\Windows\CCM\logs -Destination C:\Temp\$DeviceName\ -recurse} 
    }
    else {#>
        Copy-Item -Path \\$DeviceName\C$\Windows\CCM\logs -Destination C:\Temp\$DeviceName\ -recurse -Force
#    }
    
}

Function New-AdminSession
{[CmdletBinding()]
    param (
        [Parameter()]
        [String]
        $DeviceName
    )
 
        if(!(Get-PSSession -Name LocalAdmin -ErrorAction SilentlyContinue))
        {
        New-pssession -Name LocalAdmin -Credential (Get-StoredCredential -target Admin)
        Enter-PSSession -Name LocalAdmin
        }
      
}

Function Publish-TUHS
{
    Publish-Module -path "C:\github\tuhs" -Repository TUHSRepo -verbose 
}