## Win32 Intune App Template Creator

**Description**
> The purpose of this script is to help the process of create a Win32 Intune application. It creates a structure that aims to make the activity of create a Win32 application more easy. Another advantage is to standardizing  the process.

**Main features**
> PUT SOME TEXT

**Directory structure:**
The script creates the following structure (Using Mozilla Firefox 118.0.2 as example):
```
\---Mozilla
    \---Firefox
        \---118.0.2
            |   BuildPackage.cmd
            |   README.md
            |
            +---Assets
            +---Package
            +---Source
            |   |   Deploy-Application.exe
            |   |   Deploy-Application.exe.config
            |   |   Mozilla_Firefox_118.0.2.ps1
            |   |
            |   +---AppDeployToolkit
            |   |       AppDeployToolkitBanner.png
            |   |       AppDeployToolkitConfig.xml
            |   |       AppDeployToolkitExtensions.ps1
            |   |       AppDeployToolkitHelp.ps1
            |   |       AppDeployToolkitLogo.ico
            |   |       AppDeployToolkitLogo.png
            |   |       AppDeployToolkitMain.cs
            |   |       AppDeployToolkitMain.ps1
            |   |
            |   +---Files
            |   \---SupportFiles
            \---Utils
                    IntuneWinAppUtil.exe

- The 'Assets' directory should be used to store assets files, like the application's logo used in Intune, for example.
- The 'Package' directory is where the .intunewin file will be created.
- The 'Source' directory is where all the sources should be stored. For default this directory will be pre-populated with the necessary files of the PowerShell App Deployment Toolkit. All files within this directory will be encapsulated in the intunewin file.
- The 'Utils' directory by default contains only the IntuneWinAppUtil.exe file. This file is used for generate the intunewin file.
- The 'BuildPackage.cmd' is a simple batch file that helps the creation process of the intunewin file.
```

**Contributors:**
- Bruno Siqueira

