<#
TODO:
    - Fill the 'Deploy-Application.ps1' file with the App Name, Version, etc
    - Display a HELP when the script is run without the needed parameters
    - Try to create a PowerShell script that, given a program name installed, creates a detection script for use in the Intune application
#>

[CmdletBinding()]
Param (
    [Parameter(Mandatory = $false)]
    [String]$DestinationPath = '',
    [Parameter(Mandatory = $false)]
    [String]$ApplicationVendor = '',
    [Parameter(Mandatory = $false)]
    [String]$ApplicationName = '',
    [Parameter(Mandatory = $false)]
    [String]$ApplicationVersion = '',
    [Parameter(Mandatory = $false)]
    [switch]$JoinApplicationVendorAndApplicationName = $false,
    [Parameter(Mandatory = $false)]
    [switch]$JoinApplicationNameAndApplicationVersion = $false
)

Add-Type -AssemblyName System.IO.Compression.FileSystem

Try {
    ##*===============================================
    ##* VARIABLE DECLARATION
    ##*===============================================
    [String]$assetsDirectoryName = 'Assets'
    [String]$packagesDirectoryName = 'Package'
    [String]$sourcesDirectoryName = 'Source'
    [String]$ToolsDirectoryName = 'Utils'
    # URLs
    [String]$intuneWinAppUtilUrl = "https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool/raw/master/IntuneWinAppUtil.exe"
    [String]$psadtUrl = 'https://api.github.com/repos/PSAppDeployToolkit/PSAppDeployToolkit/releases/latest'
    # Paths
    [String]$psadtUrlZipFilePath = "$env:TEMP\PSAppDeployToolkit.zip"
    [String]$buildPackageFile = ""
    [String]$readmeMdFile = ""
    [String]$mainAppPath = ""
    ##*===============================================
    ##* END VARIABLE DECLARATION
    ##*===============================================

    # If the final directory exists, stops the script
    If (Test-Path -Path "$DestinationPath\$ApplicationVendor\$ApplicationName\$ApplicationVersion") {
        Write-Host "There is already a directory with this version of the application in the destination path provided. The script will now terminate." -ForegroundColor Red
        Exit 1
    }

    # Creates the directory structure
    Write-Host "Creating the directory structure..." 
    New-Item -Path "$DestinationPath" -Name "$ApplicationVendor" -ItemType Directory -Force | Out-Null
    New-Item -Path "$DestinationPath\$ApplicationVendor" -Name "$ApplicationName" -ItemType Directory -Force | Out-Null
    New-Item -Path "$DestinationPath\$ApplicationVendor\$ApplicationName" -Name "$ApplicationVersion" -ItemType Directory -Force | Out-Null

    $mainAppPath = "$DestinationPath\$ApplicationVendor\$ApplicationName\$ApplicationVersion"
    New-Item -Path "$mainAppPath" -Name "$assetsDirectoryName" -ItemType Directory -Force | Out-Null
    New-Item -Path "$mainAppPath" -Name "$packagesDirectoryName" -ItemType Directory -Force | Out-Null
    New-Item -Path "$mainAppPath" -Name "$sourcesDirectoryName" -ItemType Directory -Force | Out-Null
    New-Item -Path "$mainAppPath" -Name "$ToolsDirectoryName" -ItemType Directory -Force | Out-Null

    # Define path variables
    $buildPackageFile = "$mainAppPath\BuildPackage.cmd"
    $readmeMdFile = "$mainAppPath\README.md"

    # Downloads the latest version of the Microsoft Win32 Content Prep Tool
    Write-Host "Downloading the latest version of the Microsoft Win32 Content Prep Tool..." 
    $intuneWinAppUtilOutputPath = "$mainAppPath\$ToolsDirectoryName\IntuneWinAppUtil.exe"
    Invoke-WebRequest -Uri $intuneWinAppUtilUrl -OutFile $intuneWinAppUtilOutputPath

    # Downloads the latest version of the PowerShell App Deployment Toolkit to temp folder
    Write-Host "Downloading the latest version of the PowerShell App Deployment Toolkit..." 
    $response = Invoke-RestMethod -Uri $psadtUrl
    $psadtUrlZipFileURL = $response.assets | Where-Object{$_.name -like "*.zip"} | Select-Object -First 1 -ExpandProperty browser_download_url
    Invoke-WebRequest -Uri $psadtUrlZipFileURL -OutFile "$psadtUrlZipFilePath"
    Start-Sleep -Seconds 1
    # Extracts the content of the PSADT Zip file
    Write-Host "Extracting the contents of the PowerShell App Deployment Toolkit..." 
    If (Test-Path -Path "$ApplicationVersion") { Remove-Item -Path "$ApplicationVersion" -Force }
    If (Test-Path -Path "$env:TEMP\PSADT") { Remove-Item -Path "$env:TEMP\PSADT" -Force -Recurse }
    [System.IO.Compression.ZipFile]::ExtractToDirectory("$psadtUrlZipFilePath", "$env:TEMP\PSADT")
    Start-Sleep -Seconds 1
    # Copy the Toolkit folder to the apropriate location
    Write-Host "Copying the contents of the PowerShell App Deployment Toolkit to the correct location..." 
    Copy-Item -Path "$env:TEMP\PSADT\Toolkit\*" -Destination "$mainAppPath\$sourcesDirectoryName" -Recurse -Force
    Start-Sleep -Seconds 1

    # Rename Deploy-Application.ps1 file
    Write-Host "Renaming the Deploy-Application.ps1 file..." 
    $AppPs1FullName = "$($ApplicationVendor)_$($ApplicationName)_$($ApplicationVersion).ps1"
    Rename-Item -Path "$mainAppPath\$sourcesDirectoryName\Deploy-Application.ps1" -NewName "$AppPs1FullName" -Force

    # Creates the BuildPackage.cmd file
    Write-Host "Creating the BuildPackage.cmd file..." 
    Add-Content -Value "@ECHO OFF" -Path "$buildPackageFile" -Force
    Add-Content -Value "" -Path "$buildPackageFile" -Force
    Add-Content -Value "ECHO Removing previous package..." -Path "$buildPackageFile" -Force
    Add-Content -Value "DEL .\$packagesDirectoryName\*.intunewin" -Path "$buildPackageFile" -Force
    Add-Content -Value "" -Path "$buildPackageFile" -Force
    Add-Content -Value "ECHO Building package..." -Path "$buildPackageFile" -Force
    Add-Content -Value ".\Utils\IntuneWinAppUtil.exe -c "".\$sourcesDirectoryName"" -s "".\$sourcesDirectoryName\$AppPs1FullName"" -o "".\$packagesDirectoryName""" -Path "$buildPackageFile" -Force
    Add-Content -Value "" -Path "$buildPackageFile" -Force
    Add-Content -Value "ECHO Package built with success!" -Path "$buildPackageFile" -Force
    Add-Content -Value "PAUSE" -Path "$buildPackageFile" -Force

    # Creates the README.md file
    Write-Host "Creating the README.md file..." 
    $AppFullName = "$($ApplicationVendor)_$($ApplicationName)_$($ApplicationVersion)"
    Add-Content -Value "##$AppFullName" -Path "$readmeMdFile" -Force
    Add-Content -Value "" -Path "$readmeMdFile" -Force
    Add-Content -Value "**Description**" -Path "$readmeMdFile" -Force
    Add-Content -Value "> <PUT SOFTWARE DESCRIPTION HERE>" -Path "$readmeMdFile" -Force
    Add-Content -Value "" -Path "$readmeMdFile" -Force
    Add-Content -Value "**Publisher:** $ApplicationVendor" -Path "$readmeMdFile" -Force
    Add-Content -Value "**App Version:** $ApplicationVersion" -Path "$readmeMdFile" -Force
    Add-Content -Value "**Information URL:** <INSERT THE INFORMATION URL HERE>" -Path "$readmeMdFile" -Force
    Add-Content -Value "**Privacy URL:** <INSERT THE PRIVACY URL HERE>" -Path "$readmeMdFile" -Force
    Add-Content -Value "" -Path "$readmeMdFile" -Force
    Add-Content -Value "**Commands:**" -Path "$readmeMdFile" -Force
    Add-Content -Value "- **Install**" -Path "$readmeMdFile" -Force
    Add-Content -Value "	``Deploy-Application.exe "".\$($AppFullName).ps1"" -DeploymentType 'Install' -DeployMode 'Silent'``" -Path "$readmeMdFile" -Force
    Add-Content -Value "- **Uninstall**:" -Path "$readmeMdFile" -Force
    Add-Content -Value "	``Deploy-Application.exe "".\$($AppFullName).ps1"" -DeploymentType 'Uninstall' -DeployMode 'Silent'``" -Path "$readmeMdFile" -Force
    Add-Content -Value "" -Path "$readmeMdFile" -Force
    Add-Content -Value "**Detection Rules:**" -Path "$readmeMdFile" -Force
    Add-Content -Value "" -Path "$readmeMdFile" -Force
    Add-Content -Value "" -Path "$readmeMdFile" -Force
    Add-Content -Value "" -Path "$readmeMdFile" -Force




    Write-Host "End of the script." 
    ##*===============================================
    ##* END SCRIPT BODY
    ##*===============================================
} Catch {

}
