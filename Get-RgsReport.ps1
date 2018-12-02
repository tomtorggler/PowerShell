function Get-RgsReport {
    <#
    .SYNOPSIS
        Gather information about Skype for Business Response Groups, Queues, Agent Groups.
    .DESCRIPTION
        
    .EXAMPLE
        PS C:\> <example usage>
        Explanation of what the example does
    .INPUTS
        None.
    .OUTPUTS
        None.
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
        $Html
    )
    $data = Get-CsRgsWorkflow | Where-Object Name -Match $Filter | Select-Object -Property Name,LineUri, @{
        Name = "Queue";
        Expression = { 
            Get-CsRgsQueue -Identity $($_.DefaultAction.QueueId) | 
            Select-Object -ExpandProperty Name }
    }, @{
        Name = "Group";
        Expression = { (Get-CsRgsQueue -Identity $($_.DefaultAction.QueueId) | 
            Select-Object -ExpandProperty AgentGroupIDList | 
            ForEach-Object {Get-CsRgsAgentGroup -Identity $_.toString()} | 
            Select-Object -ExpandProperty Name) -join ", " }
    }, @{
        Name = "RoutingMethod";
        Expression = { (Get-CsRgsQueue -Identity $($_.DefaultAction.QueueId) | 
            Select-Object -ExpandProperty AgentGroupIDList | 
            ForEach-Object {Get-CsRgsAgentGroup -Identity $_.toString()} | 
            Select-Object -ExpandProperty RoutingMethod) -join ", " }
    }, @{
        Name = "Participation";
        Expression = { (Get-CsRgsQueue -Identity $($_.DefaultAction.QueueId) | 
            Select-Object -ExpandProperty AgentGroupIDList |
            ForEach-Object {Get-CsRgsAgentGroup -Identity $_.toString()} | 
            Select-Object -ExpandProperty ParticipationPolicy) -join ", " }
    }, @{
        Name = "Agents";
        Expression = { (Get-CsRgsQueue -Identity $($_.DefaultAction.QueueId) | 
            Select-Object -ExpandProperty AgentGroupIDList |
            ForEach-Object {Get-CsRgsAgentGroup -Identity $_.toString()} | 
            Select-Object -ExpandProperty AgentsByUri) -replace "sip:","" -replace "@.*$" -join ", " }
    }
    if($Html){
        $Head = "<style>
            table,th {font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif}
            th {text-align: left}
            table {margin-left: auto; margin-right: auto; display:block; width: 85%}
            tr:nth-child(even) {background: #CCC}
            tr:nth-child(odd) {background: #FFF}
        </style>"
        $data | ConvertTo-Html -Title "RGS Report" -Head $Head | Set-Content -Path $Path
    } else {
        $data | Export-Csv -Path $Path -NoTypeInformation -Delimiter ","
    }
}
