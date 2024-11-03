<#
  .SYNOPSIS
  Name: Zadatak 1
  Author: Boris Tomka
  Created: 2024-11-01
  Modified: 2024-11-03
  Version: 1.0
  Copyright: (c) KnowIt d.o.o. 2024

  .DESCRIPTION
  This script generate complete daily statement (KDI) which is a ZIP archive containing unpacked all daily statements for a specific date.
  KDI contains all of the organization's own parties as well as "other parties" that the organization has insight into, and that were active that day.

  The script performs the following steps:
  1. **Extract Organization Files** - Extracts zip files from subfolders and organizes them in target directories.
  2. **Extract Associated Organization Files** - Processes JSON files to find associations between organizations and extracts relevant files accordingly.
  3. **Delete *_sve-partije.zip Files** - Removes zip files with a specific naming pattern (`*_sve-partije.zip`) if they exist.
  4. **Compress *_sve-partije Folders** - Compresses specific folders (`*_sve-partije`) into zip files.
  5. **Delete *_sve-partije Folders** - Deletes the `_sve-partije` folders after they have been compressed.

  .EXAMPLE
  To run script:
  ~] pwsh kdi.ps1
#>

class ZipFileManager {
    # Declare the base path
    [string]$BasePath
    # Store all organization folders under the base path
    [System.IO.DirectoryInfo[]]$OrgIdFolders
    # Define the log file path
    [string]$LogFilePath

    # Constructor to initialize the base path and log file path, and retrieve organization folders
    ZipFileManager([string]$basePath, [string]$logFilePath) {
        $this.BasePath = $basePath
        $this.OrgIdFolders = Get-ChildItem -Path $basePath -Directory
        $this.LogFilePath = $logFilePath
    }
    
    # Method to log messages with timestamps to a log file
    [void] LogMessage([string]$message) {
        $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        "$timestamp - $message" | Out-File -FilePath $this.LogFilePath -Append
    }

    # Step 1: Extract ZIP files in organization directories
    [void] ExtractZipFiles() {
        $this.LogMessage(">>> STEP_01 <<< [EXTRACT ORGANIZATION FILES]")
        foreach ($orgIdFolder in $this.OrgIdFolders) {
            $currentOrgID = $orgIdFolder.Name
            $orgIdFolderPath = $orgIdFolder.FullName

            # Iterate over date subfolders to extract ZIP files
            $dateFolders = Get-ChildItem -Path $orgIdFolderPath -Directory
            foreach ($dateFolder in $dateFolders) {
                
                # Define extraction folder path and create if it doesn't exist
                $extractionFolder = Join-Path -Path $dateFolder.FullName -ChildPath "${currentOrgID}_sve-partije"
                if (!(Test-Path -Path $extractionFolder)) {
                    New-Item -Path $extractionFolder -ItemType Directory | Out-Null
                    $this.LogMessage("Created extraction folder: $extractionFolder")
                }

                # Extract each ZIP file with a specific naming pattern
                $zipFiles = Get-ChildItem -Path $dateFolder.FullName -Filter "*.zip" -File | Where-Object { $_.Name -match '^\d{13}\.' }
                foreach ($zipFile in $zipFiles) {
                    try {
                        Expand-Archive -Path $zipFile.FullName -DestinationPath $extractionFolder -Force
                        $this.LogMessage("Extracted file: $($zipFile.FullName) to $extractionFolder")
                    }
                    catch {
                        $this.LogMessage("Failed to extract $($zipFile.FullName): $_")
                    }
                }
            }
        }
    }

    # Step 2: Extract associated organization ZIP files based on JSON content
    [void] ExtractZipFilesFromSeparateOrgID() {
        $this.LogMessage(">>> STEP_02 <<<  [EXTRACT ASSOCIATED ORGANIZATION FILES ]")
        foreach ($orgIdFolder in $this.OrgIdFolders) {
            $currentOrgID = $orgIdFolder.Name
            $orgIdFolderPath = $orgIdFolder.FullName
            $jsonFilePath = Join-Path -Path $orgIdFolder.FullName -ChildPath "${currentOrgID}_partije.json"

            if (Test-Path -Path $jsonFilePath) {
                try {
                    # Read JSON data to map associated organization files
                    $jsonData = Get-Content -Path $jsonFilePath -Raw | ConvertFrom-Json
                    $this.LogMessage("Processing ${currentOrgID}_partije.json file for OrgID: $currentOrgID at path: $jsonFilePath")

                    foreach ($property in $jsonData.PSObject.Properties) {
                        $associatedOrgID = $property.Name
                        $value = $property.Value

                        if ($this.OrgIdFolders.Name -notcontains $associatedOrgID){
                            $this.LogMessage("This associatedOrgID [$associatedOrgID] does not exist in izvodi folder and it will not be processed!")
                        }

                        if ($associatedOrgID -ne $currentOrgID -and ($this.OrgIdFolders.Name -contains $associatedOrgID)) {
                            $dateFolders = Get-ChildItem -Path $orgIdFolderPath -Directory
                            $newFolderPaths = Join-Path -Path $orgIdFolder.Parent.FullName -ChildPath $associatedOrgID
                            
                            # Check for matching date folders in the associated OrgID folder
                            $associatedOrgIDs = Get-ChildItem -Path $newFolderPaths -Directory | ForEach-Object { $_.Name }

                            foreach ($dateFolder in $dateFolders) {
                                if ($associatedOrgIDs -contains $dateFolder.Name) {
                                    $checkThisFolders = Join-Path -Path $newFolderPaths -ChildPath $dateFolder.Name
                                    $this.LogMessage("Checking associatedOrgID and found common date folder: [$checkThisFolders]")

                                    # Retrieve unique file IDs from ZIP files for extraction
                                    $getFiles = Get-ChildItem -Path $checkThisFolders -Filter "*.zip" -File | Where-Object { $_.Name -match '^\d{13}\.' }
                                    $getFileIds = foreach ($file in $getFiles) { ($file.Name -split '\.')[0] }
                                    $uniqueIds = $getFileIds | Select-Object -Unique

                                    foreach ($fileId in $uniqueIds) {
                                        foreach ($file in $fileId) {
                                            if ($value -ccontains $file) {
                                                $extractionFolder = Join-Path -Path $dateFolder.FullName -ChildPath "${currentOrgID}_sve-partije"
                                                $extractionFiles = Get-ChildItem -Path $checkThisFolders -Filter "*.zip" -File | Where-Object { $_.Name -match $file }
                                                $this.LogMessage("Organization [$currentOrgID] has access to OrgID [$associatedOrgID] and they share the following:")
                                                $this.LogMessage(">>> Date folder: [$($dateFolder.Name)]")
                                                $this.LogMessage(">>> Found FileID in JSON file for this date: [$file]")
                                                foreach ($extractedFile in $extractionFiles) {
                                                    try {
                                                        Expand-Archive -Path $extractedFile.FullName -DestinationPath $extractionFolder -Force
                                                        $this.LogMessage("Extracted associated file $($extractedFile.FullName) to $extractionFolder")
                                                    }
                                                    catch {
                                                        $this.LogMessage("Failed to extract shared file $($extractedFile.FullName): $_")
                                                    }
                                                }
                                                break
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                catch {
                    $this.LogMessage("Failed to process JSON file at path: $jsonFilePath. Error: $_")
                }
            }
            else {
                $this.LogMessage("JSON file not found at path: $jsonFilePath")
            }
        }
    }

    # Step 3: Delete any existing ZIP files with *_sve-partije naming convention
    [void] DeleteSvePartijeZipFiles() {
        $this.LogMessage(">>> STEP_03 <<< [DELETE *_sve-partije.ZIP IF EXISTS]")
        $partijeFolders = Get-ChildItem -Path $this.BasePath -Recurse -Directory | Where-Object { $_.Name -like '*_sve-partije' }

        foreach ($folder in $partijeFolders) {
            $zipFilePath = Join-Path -Path $folder.Parent.FullName -ChildPath "$($folder.Name).zip"
            if (Test-Path -Path $zipFilePath) {
                Remove-Item -Path $zipFilePath -Force
                $this.LogMessage("Deleted zip file: $zipFilePath")
            }
        }
    }

    # Step 4: Compress each *_sve-partije folder into a ZIP file
    [void] CompressSvePartijeFolders() {
        $this.LogMessage(">>> STEP_04 <<< [COMPRESS *_sve-partije FOLDERS]")
        $partijeFolders = Get-ChildItem -Path $this.BasePath -Recurse -Directory | Where-Object { $_.Name -like '*_sve-partije' }
        foreach ($folder in $partijeFolders) {
            $zipFilePath = Join-Path -Path $folder.Parent.FullName -ChildPath "$($folder.Name).zip"
            Compress-Archive -Path "$($folder.FullName)\*" -DestinationPath $zipFilePath -Force
            $this.LogMessage("Compressed folder '$($folder.FullName)' to '$zipFilePath'")
        }
    }

    # Step 5: Delete each *_sve-partije folder after compression
    [void] DeleteSvePartijeFolder() {
        $this.LogMessage(">>> STEP_05 <<< [DELETE *_sve-partije FOLDERS]")
        $partijeFolders = Get-ChildItem -Path $this.BasePath -Recurse -Directory | Where-Object { $_.Name -like '*_sve-partije' }
        foreach ($folder in $partijeFolders) {
            Remove-Item -Path $folder.FullName -Recurse -Force
            $this.LogMessage("Deleted folder: $($folder.FullName)")
        }
    }
}

# Initialize logging and perform the defined steps
$timestamp = (Get-Date).ToString("yyyyMMddHHmm")
$logFilePath = "$HOME\izvodi_$timestamp.log"
$manager = [ZipFileManager]::new("$HOME\izvodi", $logFilePath)
$manager.ExtractZipFiles()
$manager.ExtractZipFilesFromSeparateOrgID()
$manager.DeleteSvePartijeZipFiles()
$manager.CompressSvePartijeFolders()
$manager.DeleteSvePartijeFolder()
