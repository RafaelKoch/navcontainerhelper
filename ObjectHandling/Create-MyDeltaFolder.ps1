﻿<# 
 .Synopsis
  Create folder with delta files for my objects
 .Description
  Compare my objects with my base objects and create a folder with delta files.
  Modified objects will be stored as .delta files, new objects will be .txt files.
 .Parameter containerName
  Name of the container in which the Nav Development Cmdlets are to be executed
 .Parameter modifiedFolder
  Folder containing your modified objects
 .Parameter $myoriginalFolder
  Folder containing the original objects for your modified objects
 .Parameter myDeltaFolder
  Folder in which the delta files are created
 .Example
  Create-MyDeltaFolder -containerName test -modifiedFolder c:\programdata\navcontainerhelper\myobjects -myoriginalFolder c:\programdata\navcontainerhelper\myoriginalobjects -mydeltaFolder c:\programdata\navcontainerhelper\mydeltafiles
#>
function Create-MyDeltaFolder {
    Param(
        [Parameter(Mandatory=$true)]
        [string]$containerName, 
        [Parameter(Mandatory=$true)]
        [string]$modifiedFolder, 
        [Parameter(Mandatory=$true)]
        [string]$myOriginalFolder, 
        [Parameter(Mandatory=$true)]
        [string]$myDeltaFolder
    )

    $containerModifiedFolder = Get-NavContainerPath -containerName $containerName -path $modifiedFolder -throw
    $containerMyOriginalFolder = Get-NavContainerPath -containerName $containerName -path $myOriginalFolder -throw
    $containerMyDeltaFolder = Get-NavContainerPath -containerName $containerName -path $myDeltaFolder -throw

    $session = Get-NavContainerSession -containerName $containerName
    Invoke-Command -Session $session -ScriptBlock { Param($modifiedFolder, $myOriginalFolder, $myDeltaFolder)

        Write-Host "Compare modified objects with original objects in $myOriginalFolder and create Deltas in $myDeltaFolder"
        Remove-Item -Path $myDeltaFolder -Recurse -Force -ErrorAction Ignore
        New-Item -Path $myDeltaFolder -ItemType Directory | Out-Null
        Compare-NAVApplicationObject -OriginalPath $myOriginalFolder -ModifiedPath $modifiedFolder -DeltaPath $myDeltaFolder | Out-Null

        Write-Host "Rename new objects to .TXT"
        Get-ChildItem $myDeltaFolder | % {
            $Name = $_.Name
            if ($Name.ToLowerInvariant().EndsWith(".delta")) {
                $BaseName = $_.BaseName
                $OrgName = Join-Path $myOriginalFolder "${BaseName}.TXT"
                if (!(Test-Path -Path $OrgName)) {
                    Rename-Item -Path $_.FullName -NewName "${BaseName}.TXT"
                }
            }
        }
    } -ArgumentList $containerModifiedFolder, $containerMyOriginalFolder, $containerMyDeltaFolder
}
Export-ModuleMember -function Create-MyDeltaFolder
