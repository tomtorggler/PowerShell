function Get-SMSCommandLog {
	[CmdletBinding()]
	param (
        [string]$Server,
        [string]$Instance,
        [string]$Database = "Master"
    )

   	$SqlCommand = New-Object System.Data.SqlClient.SqlCommand
	$SqlCommand.CommandText = "select * from dbo.CommandLog"

	$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
	$SqlConnection.ConnectionString = "server=$server\$instance;database=$database;trusted_connection=true;"
    try {
        Write-Verbose "Trying to connect to $database on $server\$(if($Instance){$instance}else{"Default"})"
        $SqlConnection.Open()
    }
    catch {
        Write-Verbose "Could not connect to $database on $server\$(if($Instance){$instance}else{"Default"})"
        return
    }

	$SqlCommand.Connection = $SqlConnection
	$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
	$SqlAdapter.SelectCommand = $SqlCommand

	$results = New-Object System.Data.Dataset

	$SqlAdapter.Fill($results) | Out-Null
    $SqlConnection.Close()

	return $Results.Tables[0]
}

#DBCC SQLPERF (LOGSPACE) 

function Get-SQLDBCC {
	[CmdletBinding()]
	param (
        [string]$Server,
        [string]$Instance,
        [string]$Name
    )

   	$SqlCommand = New-Object System.Data.SqlClient.SqlCommand
	
    switch ($Name)
          {
              'Logspace' {$SqlCommand.CommandText = "DBCC SQLPERF (LOGSPACE)"}
              'UserOptions' {$SqlCommand.CommandText = "DBCC USEROPTIONS"}
              'Stats' {$SqlCommand.CommandText = "DBCC SHOW_STATISTICS"}
          }

	$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
	$SqlConnection.ConnectionString = "server=$server\$instance;trusted_connection=true;"
    try {
        Write-Verbose "Trying to connect to $server\$(if($Instance){$instance}else{"Default"})"
        $SqlConnection.Open()
    }
    catch {
        Write-Verbose "Could not connect to $server\$(if($Instance){$instance}else{"Default"})"
        return
    }

	$SqlCommand.Connection = $SqlConnection
	$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
	$SqlAdapter.SelectCommand = $SqlCommand

	$results = New-Object System.Data.Dataset

	$SqlAdapter.Fill($results) | Out-Null
    $SqlConnection.Close()

	return $Results.Tables[0] | Sort-Object -Property "Log Space Used (%)" -Descending
}
