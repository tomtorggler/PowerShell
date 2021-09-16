

$queue = Import-Clixml "C:\Users\Skype for Business\rgsq.xml"
$agent = Import-Clixml "C:\Users\Skype for Business\rgsagent.xml"
$rgsw = Import-Clixml "C:\Users\Skype for Business\RGSWorkflow.xml"


function New-RgsReport {
    <#
    .SYNOPSIS
        Gather information about Skype for Business Response Groups, Queues, Agent Groups.
    .DESCRIPTION
        This function uses varios cmdlets of the Lync module (or an appropriate remote session) to 
        gather information about Response Groups.          
    .EXAMPLE
        PS C:\> Get-RgsReport -Filter Office -Path .\Desktop\report.csv 
        
        This example creates a CSV report for all RGS workflows matching Office. 
    .EXAMPLE
        PS C:\> Get-RgsReport -Filter Office -Path .\Desktop\report.html -Html
        
        This example creates a HTML report for all RGS workflows matching Office. 
    .EXAMPLE
        PS C:\> Get-RgsReport -Filter Office -Path .\Desktop\report.html -Html -PassThru | Out-GridView
        
        This example creates a HTML report for all RGS workflows matching Office, because the PassThru switch is present,
        the collected data will also be written to the pipeline. From there we can use it and pipe it to Out-GridView or do whatever.  
    .INPUTS
        None.
    .OUTPUTS
        [psobject]
    .NOTES
        Author: @torggler
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Filter,
        [Parameter()]
        [System.IO.FileInfo]
        $Path,
        [Parameter()]
        [switch]
        $Html,
        [Parameter()]
        [switch]
        $PassThru
    )
    foreach ($wf in $rgsw) {

        $wf | Select-Object -Property Name, LineUri, PrimaryUri, @{
            Name = "Queue";
            Expression = { 
                $queue | ? {$_.Identity.InstanceID -like $wf.DefaultAction.QueueId.InstanceID } | 
                Select-Object -ExpandProperty Name }
        }, @{
            Name = "Group";
            Expression = { 
                $aglist = $queue | ? {$_.Identity.InstanceId -like $wf.DefaultAction.QueueId.InstanceId} | Select-Object -ExpandProperty AgentGroupIDList 
                $temp = foreach($ag in $aglist) {
                    $agent.where{$_.Identity.InstanceId -like $ag.InstanceId}.Name
                }; $temp -join ", "
            }
        }, @{
            Name = "RoutingMethod";
            Expression = { 
                $aglist = $queue | ? {$_.Identity.InstanceId -like $wf.DefaultAction.QueueId.InstanceId} | Select-Object -ExpandProperty AgentGroupIDList 
                $temp=foreach($ag in $aglist) {
                    $agent.where{$_.Identity.InstanceId -like $ag.InstanceId}.RoutingMethod
                }; $temp -join ", "
            }
        }, @{
            Name = "Participation";
            Expression = { 
                $aglist = $queue | ? {$_.Identity.InstanceId -like $wf.DefaultAction.QueueId.InstanceId} | Select-Object -ExpandProperty AgentGroupIDList 
                $temp=foreach($ag in $aglist) {
                    $agent.where{$_.Identity.InstanceId -like $ag.InstanceId}.ParticipationPolicy 
                }; $temp -join ", "
            }
        }, @{
            Name = "Agents";
            Expression = { 
                $aglist = $queue | ? {$_.Identity.InstanceId -like $wf.DefaultAction.QueueId.InstanceId} | Select-Object -ExpandProperty AgentGroupIDList 
                $temp=foreach($ag in $aglist) {
                    $agent.where{$_.Identity.InstanceId -like $ag.InstanceId}.AgentsByUri
                }; $temp -join ", "
            }
            
        }, Active, Anonymous, EnabledForFederation
        
    }
}
