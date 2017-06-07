

function Compare-FileHash {
    [CmdletBinding()]
    param (
        [ValidateScript({Test-Path $_ -PathType Container})]
        $Source,
        [ValidateScript({Test-Path $_ -PathType Container})]
        $Destination    
    )
    
    try {    
        $sourceFiles = Get-ChildItem -Path $Source -Recurse -File -ErrorAction Stop
        $destinationFiles = Get-ChildItem -Path $Destination -Recurse -File -ErrorAction Stop
    } catch {
        Write-Warning "Could not get files: $_"
        break
    }
    $outArr = @()
    foreach($file in $sourceFiles) {
        $h1 = Get-FileHash -Path $file.FullName
        
        if ($destinationFiles.Where{$_.Name -eq $file.Name}) {
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
        } else {
            Write-Verbose "Could not fild file $($file.Name) in $Destination"
            
        }
    }
}

