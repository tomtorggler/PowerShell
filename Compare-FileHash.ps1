

function Compare-FileHash {
    [CmdletBinding()]
    param (
        $source,
        $destination    
    )
    
    $sourceFiles = Get-ChildItem -Path $source -Recurse -File
    $destinationFiles = Get-ChildItem -Path $destination -Recurse -File

    foreach($file in $sourceFiles) {
        $h1 = Get-FileHash -Path $file.FullName
        $h2 = Get-FileHash -Path $destinationFiles.Where{$_.Name -eq $file.Name}.FullName
        if($h1.Hash -eq $h2.Hash) {
            Write-Verbose "$($file.FullName) matches $($h2.path)"
        } else {
            $out = @{
                SourceFile = $h1.Path;
                SourceFileHash = $h1.Hash;
                DestinationFile = $h2.Path;
                DestinationFileHash = $h2.Hash;
            }
            Write-Output (New-Object -TypeName psobject -Property $out)
        }
    }
}

