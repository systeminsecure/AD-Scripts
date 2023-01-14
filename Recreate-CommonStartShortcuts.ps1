<# 
Recreate-CommonStartShortcuts.ps1 v0.1 2023-01-13

This script aims to recreate the shortcut links on the start menu after it has been corrupted.

Each separate array line is pipe delimited. When constructing a new entry, the format is as follows: 
    <path to exe to test for presense>|<Name on Shortcut>|<path to exe for shortcut>|<path to start menu folder to put shortcut in>

Update the $location array variable with one of the following types of example entries:

    #Shortcut in user profile - Nmap
        @("C:\Program Files (x86)\Nmap\zenmap.exe|Nmap - Zenmap GUI|C:\Program Files (x86)\Nmap\zenmap.exe|$($env:USERPROFILE)\Start Menu\Programs\"),`

    #Both shortcut and program in user profile - Slack
        @("$($env:USERPROFILE)\AppData\Local\slack\slack.exe|Slack|$($env:USERPROFILE)\AppData\Local\slack\slack.exe|$($env:USERPROFILE)\Start Menu\Programs\Slack Technologies Inc\"),`

    #Shortcut in default start location - NEED ELEVATION
        @("C:\Program Files\Notepad++\notepad++.exe|Notepad++|C:\Program Files\Notepad++\notepad++.exe|C:\ProgramData\Microsoft\Windows\Start Menu\Programs\"), ` 

#>

Function CreateShortcut{
param
(
[Parameter(Mandatory=$true)]
[String]$ExePathTest = "C:\Windows\system32\notepad.exe",
[Parameter(Mandatory=$true)]
[String]$ProgramPath = "%windir%\system32\notepad.exe",
[Parameter(Mandatory=$true)]
[String]$ProgramName = "Notepad",
[Parameter(Mandatory=$true)]
[String]$Profile = "$($env:USERPROFILE)\Start Menu\Programs\"
)
    if (Test-Path -Path $ExePathTest){
        $ShortcutPath = "$($Profile)$($ProgramName).lnk"
        write-host ("$($ExePathTest) exists, creating shortcut for $($ProgramName) as $($ShortcutPath)") -ForegroundColor Cyan  -NoNewline
        Try{
            #Check shortcut folder path exists       
            if (!(Test-Path $Profile -PathType Container)) {
                [void](New-Item -ItemType Directory -Force -Path $Profile)
            }
            #Create shortcut
            $WshShell = New-Object -comObject WScript.Shell
            $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
            $Shortcut.TargetPath = "$($ProgramPath)"
            [void]$Shortcut.Save()
            if (Test-Path -Path $ShortcutPath){
                write-host(" Present") -ForegroundColor Green
                } else {
                write-host(" Not present") -ForegroundColor Red
                }
        }
        Catch{
        }

    } else {
    write-host ("$($ExePathTest) Present?:$([string]$(Test-Path -Path $ExePathTest))") -ForegroundColor DarkCyan
    }

}

$Locations = @( `
    @("C:\Program Files (x86)\Nmap\zenmap.exe|Nmap - Zenmap GUI|C:\Program Files (x86)\Nmap\zenmap.exe|$($env:USERPROFILE)\Start Menu\Programs\"),` #shortcut in user profile - Nmap
    @("$($env:USERPROFILE)\AppData\Local\slack\slack.exe|Slack|$($env:USERPROFILE)\AppData\Local\slack\slack.exe|$($env:USERPROFILE)\Start Menu\Programs\Slack Technologies Inc\"),` #shortcut and program in user profile - Slack
    @("C:\Program Files\Notepad++\notepad++.exe|Notepad++|C:\Program Files\Notepad++\notepad++.exe|C:\ProgramData\Microsoft\Windows\Start Menu\Programs\"), ` #Default start location
    @("C:\Program Files\Google\Chrome\Application\chrome.exe|Google Chrome|C:\Program Files\Google\Chrome\Application\chrome.exe|C:\ProgramData\Microsoft\Windows\Start Menu\Programs\"), `
    @("C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe|Microsoft Edge|C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe|C:\ProgramData\Microsoft\Windows\Start Menu\Programs\"),`
    @("C:\Program Files\Microsoft Office\root\Office16\EXCEL.EXE|Excel|C:\Program Files\Microsoft Office\root\Office16\EXCEL.EXE|C:\ProgramData\Microsoft\Windows\Start Menu\Programs\"),`
    @("C:\Program Files\Microsoft Office\root\Office16\ONENOTE.EXE|OneNote|C:\Program Files\Microsoft Office\root\Office16\ONENOTE.EXE|C:\ProgramData\Microsoft\Windows\Start Menu\Programs\"),`
    @("C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE|Outlook|C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE|C:\ProgramData\Microsoft\Windows\Start Menu\Programs\"),`
    @("C:\Program Files\Microsoft Office\root\Office16\POWERPNT.EXE|PowerPoint|C:\Program Files\Microsoft Office\root\Office16\POWERPNT.EXE|C:\ProgramData\Microsoft\Windows\Start Menu\Programs\"),`
    @("C:\Program Files\Microsoft Office\root\Office16\MSPUB.EXE|Publisher|C:\Program Files\Microsoft Office\root\Office16\MSPUB.EXE|C:\ProgramData\Microsoft\Windows\Start Menu\Programs\"),`
    @("C:\Program Files\Microsoft Office\root\Office16\WINWORD.EXE|Word|C:\Program Files\Microsoft Office\root\Office16\WINWORD.EXE|C:\ProgramData\Microsoft\Windows\Start Menu\Programs\"),`
    #@("C:\Program Files\Microsoft Office\root\Office16\MSACCESS.EXE|Access|C:\Program Files\Microsoft Office\root\Office16\MSACCESS.EXE|C:\ProgramData\Microsoft\Windows\Start Menu\Programs\"),`
    @("C:\Program Files\Adobe\Acrobat DC\Acrobat\acrobat.exe|Adobe Acrobat|C:\Program Files\Adobe\Acrobat DC\Acrobat\acrobat.exe\|C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Adobe\")

)

ForEach($item in $Locations){
    $location = $item.split("|")
    CreateShortcut -ExePathTest $location[0] -ProgramName $location[1] -ProgramPath $($location[2]) -profile $location[3]

}

<# --== Errata ==--

Prerequisites needed before launching:
- Powershell 5.1 or better

Restrictions
- The script needs to run elevated to write to C:\ProgramData\Microsoft\Windows\Start Menu\Programs. This is a security restriction in Windows.

Prerequisites to support a new shortcut:
- Update the $location variable

To do in later versions:
- Nothing planned

Changelog:
- 0.1 Initial version 2023-01-13
#>

