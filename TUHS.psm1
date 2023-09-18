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
    If (Test-path TUH:)
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
    If (Test-path TUH:)
    {
        set-location TUH:
    }
    else {
        Install-SCCM
        Set-location TUH:
    }
    
    $collectionID = (Get-CMCollection -name $CollectionName).collectionID
     $resourceID = (Get-CMDevice -name $DeviceName).resourceid
    add-cmdevicecollectiondirectmembershiprule -collectionid $collectionID -resourceid $resourceID
    Invoke-CMCollectionUpdate -collectionid (Get-CMCollectionDependency -Id $collectionID).CollectionID #updates limiting collection
    Invoke-CMCollectionUpdate -CollectionId $collectionID #updates collection
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
    if(test-path C:\github\tuhs)
    {
    Publish-Module -path "C:\github\tuhs" -Repository TUHSRepo -verbose 
    }
    else {
        Publish-Module -path "C:\tuhs" -Repository TUHSRepo -verbose
    }
}

function New-Shortcut {
    [CmdletBinding()]  
    Param (   
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$TargetPath,                # the path to the executable
        # the rest is all optional
        [string]$ShortcutPath = (Join-Path -Path ([Environment]::GetFolderPath("Desktop")) -ChildPath 'New Shortcut.lnk'),
        [string[]]$Arguments = $null,       # a string or string array holding the optional arguments.
        [string[]]$HotKey = $null,          # a string like "CTRL+SHIFT+F" or an array like 'CTRL','SHIFT','F'
        [string]$WorkingDirectory = $null,
        [string]$Description = $null,
        [string]$IconLocation = $null,      # a string like "notepad.exe, 0"
        [ValidateSet('Default','Maximized','Minimized')]
        [string]$WindowStyle = 'Default',
        [switch]$RunAsAdmin
    ) 
    switch ($WindowStyle) {
        'Default'   { $style = 1; break }
        'Maximized' { $style = 3; break }
        'Minimized' { $style = 7 }
    }
    $WshShell = New-Object -ComObject WScript.Shell

    # create a new shortcut
    $shortcut             = $WshShell.CreateShortcut($ShortcutPath)
    $shortcut.TargetPath  = $TargetPath
    $shortcut.WindowStyle = $style
    if ($Arguments)        { $shortcut.Arguments = $Arguments -join ' ' }
    if ($HotKey)           { $shortcut.Hotkey = ($HotKey -join '+').ToUpperInvariant() }
    if ($IconLocation)     { $shortcut.IconLocation = $IconLocation }
    if ($Description)      { $shortcut.Description = $Description }
    if ($WorkingDirectory) { $shortcut.WorkingDirectory = $WorkingDirectory }

    # save the link file
    $shortcut.Save()

    if ($RunAsAdmin) {
        # read the shortcut file we have just created as [byte[]]
        [byte[]]$bytes = [System.IO.File]::ReadAllBytes($ShortcutPath)
        $bytes[21] = 0x22      # set byte no. 21 to ASCII value 34
        [System.IO.File]::WriteAllBytes($ShortcutPath, $bytes)
    }

    # clean up the COM objects
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shortcut) | Out-Null
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($WshShell) | Out-Null
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
}

Function Update-GPOPermissions{
    [CmdletBinding()]
    param (
        [Parameter()]
        [String]
        $PolicyName 
        )
        if($policyname)
        {
            Set-GPPermission -Name $policyname -TargetName "tuh\Group Policy Admins" -TargetType Group -PermissionLevel "GpoEditDeleteModifySecurity"
            Set-GPPermission -Name $policyname -TargetName "tuh\Group Policy Creator Owners" -TargetType Group -PermissionLevel "GpoEditDeleteModifySecurity"
            Set-GPPermission -Name $policyname -TargetName "tuhs\Group Policy Creator Owners" -TargetType Group -PermissionLevel "GpoEditDeleteModifySecurity"
            Set-GPPermission -Name $policyname -TargetName "tuh\$env:username" -TargetType User -PermissionLevel "none"
        }
        else 
        {
            get-gpo -all | where-object{$_.Owner -like "tuh\$env:username"} | foreach-object{
                $policyname = $_.DisplayName
                Set-GPPermission -Name $policyname -TargetName "tuh\Group Policy Admins" -TargetType Group -PermissionLevel "GpoEditDeleteModifySecurity"
                Set-GPPermission -Name $policyname -TargetName "tuh\Group Policy Creator Owners" -TargetType Group -PermissionLevel "GpoEditDeleteModifySecurity"
                Set-GPPermission -Name $policyname -TargetName "tuhs\Group Policy Creator Owners" -TargetType Group -PermissionLevel "GpoEditDeleteModifySecurity"
                Set-GPPermission -Name $policyname -TargetName "tuh\$env:username" -TargetType User -PermissionLevel "none"
            }
        }
}

Function Set-ScriptSignature {
    [CmdletBinding()]
    param (
        [Parameter()]
        [String]
        $path 
        )
        $cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert
        Set-AuthenticodeSignature -FilePath $path-Certificate $cert
}