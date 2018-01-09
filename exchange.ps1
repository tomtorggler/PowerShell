# a quick & drity backup check that can be run as scheduled task
. 'C:\Program Files\Microsoft\Exchange Server\V15\bin\RemoteExchange.ps1'; Connect-ExchangeServer -auto -ClientApplication:ManagementShell
(Get-MailboxDatabase -Status).ForEach({ $data += "Database: " + $_.Name + " Last Backup: " + $_.lastFullBackup + "`n" })
Send-MailMessage -From check@ntsystems.it -To tom@ntsystems.it -Subject "Exchange Check" -Body $data -SmtpServer localhost

# check protocol logs for unique remote-endpoints in SmtpReceive
$logPath = 'C:\Program Files\Microsoft\Exchange Server\V15\TransportRoles\Logs\FrontEnd\ProtocolLog\SmtpReceive'
$files = (Get-ChildItem $logPath).Where{$_.LastWriteTime -GT (get-date).AddDays(-30)}
$data = $null
foreach ($f in $files) {
    $data = (Import-Csv -Path $f.FullName -Delimiter ',' -Header date-time,connector-id,session-id,sequence-number,local-endpoint,remote-endpoint,event,data,context).Where{$_.'remote-endpoint'}
}
$data.'remote-endpoint' -replace "\:\d+","" | Select-Object -Unique
# check protocol logs for unique remote-endpoints in SmtpSend
$logPath = 'C:\Program Files\Microsoft\Exchange Server\V15\TransportRoles\Logs\FrontEnd\ProtocolLog\SmtpSend'
$files = (Get-ChildItem $logPath).Where{$_.LastWriteTime -GT (get-date).AddDays(-30)}
$data = $null
foreach ($f in $files) {
    $data = (Import-Csv -Path $f.FullName -Delimiter ',' -Header date-time,connector-id,session-id,sequence-number,local-endpoint,remote-endpoint,event,data,context).Where{$_.'remote-endpoint'}
}
$data.'remote-endpoint' -replace "\:\d+","" | Select-Object -Unique