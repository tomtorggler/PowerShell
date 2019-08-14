

function Update-DashboardInfo {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [System.IO.FileInfo]
        $Path,
        [Parameter(Mandatory)]
        $Subscription,
        [Parameter(Mandatory)]
        $ResourceGroup,
        [Parameter(Mandatory)]
        $Name
    )
    
    $content = Get-Content -Path $Path -Raw
    $contentJson = $content | ConvertFrom-Json 
    $outPath = $path -replace ".json","-new.json"
    $oldSubscription = $contentJson.properties.lenses.0.0.parts.0.0.metadata.inputs.where{$_.Name -eq "ComponentId"}.Value.SubscriptionId
    $oldName = $contentJson.properties.lenses.0.0.parts.0.0.metadata.inputs.where{$_.Name -eq "ComponentId"}.Value.Name
    $oldResourceGroup = $contentJson.properties.lenses.0.0.parts.0.0.metadata.inputs.where{$_.Name -eq "ComponentId"}.Value.ResourceGroup


    Write-Verbose "Replacing Subscription [$oldSubscription] with [$Subscription]"
    Write-Verbose "Replacing Name [$oldName] with [$Name]"
    Write-Verbose "Replacing ResourceGroup [$oldResourceGroup] with [$ResourceGroup]"


    if($PSCmdlet.ShouldProcess($outPath, "Update info and write")){
        $content = $content -replace $oldSubscription,$Subscription
        $content = $content -replace "`"ResourceGroup`": `"$oldResourceGroup`"","`"ResourceGroup`": `"$ResourceGroup`""
        $content = $content -replace "resourcegroups/$oldResourceGroup","resourcegroups/$ResourceGroup"
        $content = $content -replace "`"Name`": `"$oldName`"","`"Name`": `"$Name`""
        $content = $content -replace "`"PartSubTitle`": `"$oldName`"","`"PartSubTitle`": `"$Name`""   
        $content = $content -replace "`"value`": `"$oldName`"","`"value`": `"$Name`""   
        $content = $content -replace "workspaces/$oldName","workspaces/$Name"
                   
        Write-Verbose "Writing file $outPath"

        $content | Set-Content $outPath
    }    
}


#Update-DashboardInfo -Path 'C:\Users\thomas.torggler\Downloads\Exchange Online.json' -Name "na-unistgallen" -ResourceGroup "rg_unistgallen" -Subscription "001e6d27-4a75-4812-8a38-a83d71942523" -Verbose

