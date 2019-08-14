function Get-SMSCommandLog {
    <#
    .SYNOPSIS
        Read SQL Server Maintenance Solution Logs.
    .DESCRIPTION
        Read SQL Server Maintenance Solution Logs from the CommandLog table in the database set by the Database parameter.
        https://ola.hallengren.com/sql-server-backup.html
    .EXAMPLE
        PS C:\> <example usage>
        Explanation of what the example does
    .INPUTS
        Inputs (if any)
    .OUTPUTS
        Output (if any)
    .NOTES
        General notes
    #>
	[CmdletBinding()]
	param (
        [string]$ComputerName = "localhost",
        [string]$Instance,
        [string]$Database = "Master"
    )

   	$SqlCommand = New-Object System.Data.SqlClient.SqlCommand
	$SqlCommand.CommandText = "select * from dbo.CommandLog"

	$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
	$SqlConnection.ConnectionString = "server=$ComputerName\$instance;database=$database;trusted_connection=true;"
    try {
        Write-Verbose "Trying to connect to $database on $ComputerName\$(if($Instance){$instance}else{"Default"})"
        $SqlConnection.Open()
    }
    catch {
        Write-Verbose "Could not connect to $database on $ComputerName\$(if($Instance){$instance}else{"Default"})"
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

function Get-SqlDBCC {
	[CmdletBinding()]
	param (
        [Parameter()]
        [string]$ComputerName = "localhost",
        [Parameter()]
        [string]$Instance,
        [Parameter()]
        [ValidateSet("Logspace","UserOptions","Stats")]
        [string]$Name = "Logspace"
    )
   	$SqlCommand = New-Object System.Data.SqlClient.SqlCommand
    # set the command according to name parameter
    switch ($Name)
          {
              'Logspace' {$SqlCommand.CommandText = "DBCC SQLPERF (LOGSPACE)"}
              'UserOptions' {$SqlCommand.CommandText = "DBCC USEROPTIONS"}
              'Stats' {$SqlCommand.CommandText = "DBCC SHOW_STATISTICS"}
          }
	$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
	$SqlConnection.ConnectionString = "server=$ComputerName\$instance;trusted_connection=true;"
    try {
        Write-Verbose "Trying to connect to $ComputerName\$(if($Instance){$instance}else{"Default"})"
        $SqlConnection.Open()
    }
    catch {
        Write-Verbose "Could not connect to $ComputerName\$(if($Instance){$instance}else{"Default"})"
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

function Get-SqlLastBackup {
    [CmdletBinding()]
	param (
        [Parameter()]
        [string]$ComputerName = "localhost",
        [string]$Instance
    )
    $SqlCommand = New-Object System.Data.SqlClient.SqlCommand
    $SqlCommand.CommandText = "-- D = Full, I = Differential and L = Log.
    -- There are other types of backups too but those are the primary ones.
    SELECT backupset.database_name, 
        MAX(CASE WHEN backupset.type = 'D' THEN backupset.backup_finish_date ELSE NULL END) AS LastFullBackup,
        MAX(CASE WHEN backupset.type = 'I' THEN backupset.backup_finish_date ELSE NULL END) AS LastDiffBackup,
        MAX(CASE WHEN backupset.type = 'L' THEN backupset.backup_finish_date ELSE NULL END) AS LastLogBackup
    FROM backupset
    GROUP BY backupset.database_name
    ORDER BY backupset.database_name DESC"
        
	$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
	$SqlConnection.ConnectionString = "server=$ComputerName\$instance;trusted_connection=true;"
    try {
        Write-Verbose "Trying to connect to $ComputerName\$(if($Instance){$instance}else{"Default"})"
        $SqlConnection.Open()
        $SqlConnection.ChangeDatabase("msdb")
    }
    catch {
        Write-Verbose "Could not connect to $ComputerName\$(if($Instance){$instance}else{"Default"})"
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

