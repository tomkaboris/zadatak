# Izvodi (KDI) Generator
This PowerShell script automates the generation of daily statements (KDI) in a ZIP archive format. Each archive includes all unpacked daily records for a specified date, covering all active records for your organization as well as any accessible records from other organisations.

## Table of Contents
- [Overview](#overview)
- [Requirements](#requirements)
- [Usage](#usage)
- [Script Details](#script-details)
- [Mock Data Generator](#mock-data-generator)
  
## Overview
- The script performs five steps to generate the KDI ZIP archive. It operates from a designated izvodi base folder, sequentially processing files and directories to create a consolidated archive.

### Workflow Steps:
- **Step 1:** Extract ZIP files in organization directories.
- **Step 2:** Extract associated organization ZIP files based on JSON content.
- **Step 3:** Delete any existing ZIP files with *_sve-partije  if they exists.
- **Step 4:** Compress each *_sve-partije folder into a ZIP file.
- **Step 5:** Delete each *_sve-partije folder after compression.
 
## Requirements
- The script requires **PowerShell (pwsh)** version 7.4.6 or higher.
- The script expects the folder **izvodi** to be located in the $HOME/izvodi directory, as it will use this as directory for processing files.

To install PowerShell, see the [official installation guide](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell) for Windows, Linux, and macOS.

## Usage
Run the script from your terminal as follows:
```bash
pwsh kdi.ps1
```

## Mock Data Generator
The mock data generator script creates a sample directory structure for testing the KDI generation process. It generates randomized data that conforms to the required schema. This script is written in Python and requires version 3.9.13 or higher.

### Running the Mock Generator
To get details on all available parameters and options, use the --help flag:
```bash
python3 kdi_mock.py --help
```
### Available Parameters
The script is highly customizable, with the following parameters available for defining the mock data structure:
```bash
Generate mock data directory structure.

optional arguments:
  -h, --help            show this help message and exit
  --base_dir    BASE_DIR    Base directory to create. [Default (str): izvodi]
  --num_ids     NUM_IDS     Number of ID directories to create. [Default (int): 5]
  --id_length   ID_LENGTH   Length of the numeric ID. [Default (int): 5]
  --start_date START_DATE   Start date for date directories (YYYY-MM-DD). [Default (str): 2024-09-10]
  --end_date END_DATE       End date for date directories (YYYY-MM-DD). [Default (str): 2024-11-10]
  --min_dates MIN_DATES     Minimum number of date directories per ID. [Default (int): 2]
  --max_dates MAX_DATES     Maximum number of date directories per ID. [Default (int): 15]
  --min_partija MIN_PARTIJA Minimum number of partije per date directory. [Default (int): 2]
  --max_partija MAX_PARTIJA Maximum number of partije per date directory. [Default (int): 6]
  --num_orgs NUM_ORGS       The number of possible organizations that will have access to others depending on the percentage of probability. [Default (int): 2]
  --per_acc PER_ACC         Percentage of merge probability with other organisations (0.3 = 30 percent). [Default (float): 0.5]
```
