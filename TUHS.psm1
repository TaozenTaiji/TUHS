
function Invoke-SqlCommand{
    [OutputType([System.Data.DataTable])]
    Param(
        [Parameter(Mandatory)]
        [string]$Query,
        [string]$ServerInstance,
        [string]$Database
    )
    
    Try{
      $SqlConnection = New-Object System.Data.SqlClient.SqlConnection  
      #  $SqlConnection.ConnectionString = "Data Source=tcp:rmxprod.database.windows.net,1433;Initial Catalog=rhythmedix;Authentication=Active Directory Integrated;"
        $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
        $sqlconnection.Open()
        $sqlcmd = $sqlconnection.CreateCommand()
        $sqlcmd.CommandText = $query
        $rdr = $sqlcmd.ExecuteReader()
        $dt = [System.Data.DataTable]::New()
        $dt.Load($rdr)
        $sqlconnection.Close()
    }
    Catch{
        Throw $_
    }
    @(,$dt)
}