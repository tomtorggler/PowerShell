# Compare-Directory.ps1
# Compare files in one or more directories and return file difference results
# Victor Vogelpoel <victor.vogelpoel@macaw.nl>
# Sept 2013
# adapted by @torggler - 2017
  
# Compare-Directory -ReferenceDirectory "C:\Compare-Directory\FrontEnd1-Site"   -DifferenceDirectory "C:\Compare-Directory\FrontEnd2-Site"

function Get-Files {
        [CmdletBinding(SupportsShouldProcess=$false)]
        param (
                [string]$DirectoryPath,
                [String[]]$ExcludeFile,
                [String[]]$ExcludeDirectory,
                [switch]$Recurse
        )   
        $relativeBasenameIndex = $DirectoryPath.ToString().Length
        # Get the files from the first deploypath
        # and ADD the hash for the file as a property
        # and ADD a filepath relative to the deploypath as a property
        $childs = Get-ChildItem -Path $DirectoryPath -Exclude $ExcludeFile -Recurse:$Recurse
    $childs.foreach{
        $hash = ""
        if (!$_.PSIsContainer) { 
            $hash = Get-FileHash $_ | Select-Object -ExpandProperty Hash       
        }
        # Added two new properties to the DirectoryInfo/FileInfo objects
        $item = $_ |
                Add-Member -Name "FileHash" -MemberType NoteProperty -Value $hash -PassThru |
                Add-Member -Name "RelativeBaseName" -MemberType NoteProperty -Value ($_.FullName.Substring($relativeBasenameIndex)) -PassThru
        # Test for directories and files that need to be excluded because of ExcludeDirectory
        if ($item.PSIsContainer) { $item.RelativeBaseName += "\" }
        if ($ExcludeDirectory.where{ $item.RelativeBaseName -like "\$_\*" }) {
                Write-Verbose "Ignore item `"$($item.Fullname)`""
        } else {
                Write-Verbose "Adding `"$($item.Fullname)`" to result set"
                Write-Output $item
        }
        }
}
  
function Compare-Directory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,position=0, ValueFromPipelineByPropertyName=$true, HelpMessage="The reference directory to compare one or more difference directories to.")]
        [System.IO.DirectoryInfo]$ReferenceDirectory,
        [Parameter(Mandatory=$true, position=1, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, HelpMessage="One or more directories to compare to the reference directory.")]
        [System.IO.DirectoryInfo[]]$DifferenceDirectory,
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, HelpMessage="Recurse the directories")]
        [switch]$Recurse,
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, HelpMessage="Files to exclude from the comparison")]
        [String[]]$ExcludeFile,
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, HelpMessage="Directories to exclude from the comparison")]
        [String[]]$ExcludeDirectory,
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, HelpMessage="Displays only the characteristics of compared objects that are equal.")]
        [switch]$ExcludeDifferent,
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, HelpMessage="Displays characteristics of files that are equal. By default, only characteristics that differ between the reference and difference files are displayed.")]
        [switch]$IncludeEqual,
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, HelpMessage="Passes the objects that differed to the pipeline.")]
        [switch]$PassThru
    )
    begin {
        $referenceDirectoryFiles = Get-Files -DirectoryPath $referenceDirectory -ExcludeFile $ExcludeFile -ExcludeDirectory $ExcludeDirectory -Recurse:$Recurse
    }
    process {
        if ($DifferenceDirectory -and $referenceDirectoryFiles)  {
        foreach($nextPath in $DifferenceDirectory) {
            $nextDifferenceFiles = Get-Files -DirectoryPath $nextpath -ExcludeFile $ExcludeFile -ExcludeDirectory $ExcludeDirectory -Recurse:$Recurse
                               
    $CompareObjectParams = @{
            ReferenceObject = $referenceDirectoryFiles;
            DifferenceObject = $nextDifferenceFiles;
            ExcludeDifferent = $ExcludeDifferent;
            IncludeEqual = $IncludeEqual;
            PassThru = $PassThru;
            Property = 'RelativeBaseName', 'FileHash';
    }
                $results = @(Compare-Object @CompareObjectParams)
  
                                if (!$PassThru) {
                                        foreach ($result in $results) {
                                                $path                 = $ReferenceDirectory
                                                $pathFiles       = $referenceDirectoryFiles
                                                if ($result.SideIndicator -eq "=>") {
                                                        $path                 = $nextPath
                                                        $pathFiles       = $nextDifferenceFiles
                                                }
  
                                                # Find the original item in the files array
                                                $itemPath = (Join-Path $path $result.RelativeBaseName).ToString().TrimEnd('\')
                                                $item = $pathFiles.where{ $_.fullName -eq $itemPath }
  
                                                $result | Add-Member -Name "Item" -MemberType NoteProperty -Value $item
                                        }
                                }
                                Write-Output $results
                        }
                }
        }
    end { 
        # End
    }
}


