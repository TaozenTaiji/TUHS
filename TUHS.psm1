
function Find-ADGroup{

[CmdletBinding()]
param (
    [Parameter()]
    [String]
    $Search
)
    get-adgroup -filter {Name -like "*$Search*"}
}
