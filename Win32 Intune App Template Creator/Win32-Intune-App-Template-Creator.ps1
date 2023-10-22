<#
TODO:
    - Show a info screen (Text based), describing the tool usage, purpose, etc
    - Ask for the App Vendor
    - Ask for the App Name
    - Ask for the App Version
    - Ask for the App Location
    - Ask for the Script Author
    - Fill the Installation and Uninstallation files With the App Name, Version, etc
    - Try to create a PowerShell script that, given a program name installed, creates a detection script
    - Try to download Logo files for the given application
    - Create a MarkDown template file with sample information
    - Save some information on registry, like Script Author, for use as sugestion on another run of the tool
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
    [String]$ApplicationVersion = ''
)

Add-Type -AssemblyName System.IO.Compression.FileSystem

Try {
    ##*===============================================
    ##* VARIABLE DECLARATION
    ##*===============================================
    [String]$assetsDirectoryName = 'Assets'
    [String]$packagesDirectoryName = 'Packages'
    [String]$sourcesDirectoryName = 'Sources'
    [String]$ToolsDirectoryName = 'Utils'
    # URLs
    [String]$intuneWinAppUtilUrl = "https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool/raw/master/IntuneWinAppUtil.exe"
    [String]$psadtUrl = 'https://api.github.com/repos/PSAppDeployToolkit/PSAppDeployToolkit/releases/latest'
    # Paths
    [String]$psadtUrlZipFilePath = "$env:TEMP\PSAppDeployToolkit.zip"
    [String]$buildPackageFile = ""
    [String]$readmeMdFile = ""
    ##*===============================================
    ##* END VARIABLE DECLARATION
    ##*===============================================

    # FOR TESTS PURPOSE ONLY
    $DestinationPath = 'D:\Packages'
    $ApplicationVendor = 'Mozilla'
    $ApplicationName = 'Firefox'
    $ApplicationVersion = '118.0.2'
    # FOR TESTS PURPOSE ONLY

    # Creates the directory structure
    New-Item -Path "$DestinationPath" -Name "$ApplicationVendor" -ItemType Directory -Force | Out-Null
    New-Item -Path "$DestinationPath\$ApplicationVendor" -Name "$ApplicationName" -ItemType Directory -Force | Out-Null
    New-Item -Path "$DestinationPath\$ApplicationVendor\$ApplicationName" -Name "$ApplicationVersion" -ItemType Directory -Force | Out-Null

    New-Item -Path "$DestinationPath\$ApplicationVendor\$ApplicationName\$ApplicationVersion" -Name "$assetsDirectoryName" -ItemType Directory -Force | Out-Null
    New-Item -Path "$DestinationPath\$ApplicationVendor\$ApplicationName\$ApplicationVersion" -Name "$packagesDirectoryName" -ItemType Directory -Force | Out-Null
    New-Item -Path "$DestinationPath\$ApplicationVendor\$ApplicationName\$ApplicationVersion" -Name "$sourcesDirectoryName" -ItemType Directory -Force | Out-Null
    New-Item -Path "$DestinationPath\$ApplicationVendor\$ApplicationName\$ApplicationVersion" -Name "$ToolsDirectoryName" -ItemType Directory -Force | Out-Null

    # Define path variables
    $buildPackageFile = "$DestinationPath\$ApplicationVendor\$ApplicationName\$ApplicationVersion\BuildPackage.cmd"

    # Downloads the latest version of the Microsoft Win32 Content Prep Tool
    $intuneWinAppUtilOutputPath = "$DestinationPath\$ApplicationVendor\$ApplicationName\$ApplicationVersion\$ToolsDirectoryName\IntuneWinAppUtil.exe"
    Invoke-WebRequest -Uri $intuneWinAppUtilUrl -OutFile $intuneWinAppUtilOutputPath

    # Downloads the latest version of the PowerShell App Deployment Toolkit to temp folder
    $response = Invoke-RestMethod -Uri $psadtUrl
    $psadtUrlZipFileURL = $response.assets | Where-Object{$_.name -like "*.zip"} | Select-Object -First 1 -ExpandProperty browser_download_url
    Invoke-WebRequest -Uri $psadtUrlZipFileURL -OutFile "$psadtUrlZipFilePath"
    Start-Sleep -Seconds 1
    # Extracts the content of the PSADT Zip file
    If (Test-Path -Path "$ApplicationVersion") { Remove-Item -Path "$ApplicationVersion" -Force }
    If (Test-Path -Path "$env:TEMP\PSADT") { Remove-Item -Path "$env:TEMP\PSADT" -Force -Recurse }
    [System.IO.Compression.ZipFile]::ExtractToDirectory("$psadtUrlZipFilePath", "$env:TEMP\PSADT")
    Start-Sleep -Seconds 1
    # Copy the Toolkit folder to the apropriate location
    Copy-Item -Path "$env:TEMP\PSADT\Toolkit\*" -Destination "$DestinationPath\$ApplicationVendor\$ApplicationName\$ApplicationVersion\$sourcesDirectoryName" -Recurse -Force
    Start-Sleep -Seconds 1

    # Rename Deploy-Application.ps1 file
    $AppPs1FullName = "$($ApplicationVendor)_$($ApplicationName)_$($ApplicationVersion).ps1"
    Rename-Item -Path "$DestinationPath\$ApplicationVendor\$ApplicationName\$ApplicationVersion\$sourcesDirectoryName\Deploy-Application.ps1" -NewName "$AppPs1FullName" -Force

    # Creates the BuildPackage.cmd file
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
    $ApplicationVendor = 'Mozilla'
    $ApplicationName = 'Firefox'
    $ApplicationVersion = '118.0.2'
    $AppFullName = "$($ApplicationVendor)_$($ApplicationName)_$($ApplicationVersion)"
    Add-Content -Value "##$AppFullName" -Path "$readmeMdFile" -Force
    Add-Content -Value "" -Path "$readmeMdFile" -Force
    Add-Content -Value "**Description**" -Path "$readmeMdFile" -Force
    Add-Content -Value ">PUT SOFTWARE DESCRIPTION HERE!" -Path "$readmeMdFile" -Force
    Add-Content -Value "" -Path "$readmeMdFile" -Force
    Add-Content -Value "**Publisher:** $ApplicationVendor" -Path "$readmeMdFile" -Force
    Add-Content -Value "" -Path "$readmeMdFile" -Force
    Add-Content -Value "" -Path "$readmeMdFile" -Force
    Add-Content -Value "" -Path "$readmeMdFile" -Force
    Add-Content -Value "" -Path "$readmeMdFile" -Force
    Add-Content -Value "" -Path "$readmeMdFile" -Force
    Add-Content -Value "" -Path "$readmeMdFile" -Force
    Add-Content -Value "" -Path "$readmeMdFile" -Force
    Add-Content -Value "" -Path "$readmeMdFile" -Force
    Add-Content -Value "" -Path "$readmeMdFile" -Force
    Add-Content -Value "" -Path "$readmeMdFile" -Force
    Add-Content -Value "" -Path "$readmeMdFile" -Force


    # Put some information in the Install.ps1 and Uninstall.ps1 files
    #$installContent = Get-Content "$DestinationPath\$ApplicationVendor\$ApplicationName\$ApplicationVersion\$sourcesDirectoryName\Install.ps1"
    #$installContent = $installContent -replace '[String]$appVendor = ''', "[String]$appVendor = '$($ApplicationVendor)'"
    #$installContent = $installContent -replace "", ""
    #$installContent = $installContent -replace "", ""
    #$installContent = $installContent -replace "", ""
    #$installContent = $installContent -replace "", ""
    #$installContent | Set-Content "$DestinationPath\$ApplicationVendor\$ApplicationName\$ApplicationVersion\$sourcesDirectoryName\Install.ps1"



    ##*===============================================
    ##* END SCRIPT BODY
    ##*===============================================
} Catch {

}
