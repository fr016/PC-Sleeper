param ([switch]$Prod,
    [switch]$Mail)

<#
# Name :  - Objective :  - Author : 
How to read this Script:
1.Open it with ISE
2.CTRL + M for collapse all code regions
3.Go to "Main region" at the end of the script and click on the + for expand the region
4.Start reading the script

-How to use this Script:
1.Ensure your credentials are saved and Encrypted on Line 71 and by call function "GereLesCredentials" below
2.Ensure Avoid spacing character in all titles ExcelFile and replace it by "_"
3.to run the script : .\NomScript.ps1 -Prod $true
#>

<#

Respecter le principe KISS
Utiliser l'existant et aller voir dabord ds notre github
Follow a simple but organized script flow:
-	#Requires comments 
-	Define your params 
-	Create your functions 
-	Setup any variables 
-	Run your code 
-	Comment based help
#>

<#
    TODO


#>

Set-StrictMode -version Latest
#region Data Declaration

$ScriptDir = ($MyInvocation.MyCommand.Path).replace($MyInvocation.MyCommand.Name, "")
$ScriptFullName = $MyInvocation.MyCommand.Path
$ScriptName = $(Split-Path $ScriptFullName -Leaf).Replace(".ps1", "")
$dataPath = "$($ScriptDir)data"
$ScriptVersion = 1.5
$ActionDate = $("Actions of $(Get-Date -UFormat '%m-%d-%Y') at $(Get-Date -Format HH) h $(Get-Date -Format mm) min $(Get-Date -Format ss) s")
$LogPath = "$dataPath\Logs\$ActionDate.log"
$TranscriptPath = "$dataPath\Logs\transcript-$ActionDate.txt"
$pathCred = "$dataPath\Cred"
$PathLogExcelOutput = "$dataPath\Logs\$ActionDate.csv"
$ErrorActionPreference = "Stop"

Start-Transcript -Path $TranscriptPath


#REMPLIR SI BESOIN

$MailDst = "dan.guedj-ext@socgen.com"
$MailDstCC = ""
$SmtpServerName = "smtp-gw.int.world.socgen"
$SmtpServerIP = "184.7.50.153"

#REMPLIR SI BESOIN



$Domains = @{
    'Current' = $env:USERDNSDOMAIN
}

$Creds = @{
    #'MesCred' = new-object -typename System.Management.Automation.PSCredential -argumentlist ("$($Domaine.Current)\login"), (Get-Content $pathCred\mdp.txt | convertto-securestring)
}

function LoadModule ([parameter(Mandatory = $true)]$moduleName)
{
    $res = @(Get-Module -listavailable $moduleName)
    [boolean]$moduleLoaded = $false
    if ($res.Count -gt 0)
    {
        [boolean]$moduleLoaded = @(Get-Module -listavailable $moduleName | Select-Object Name).name -contains $moduleName
    }
	
    if (!$moduleLoaded)
    {
        Import-Module -Name $dataPath\Modules\$moduleName
    }
}

LoadModule "Pester"
LoadModule "PSLogging"
#endregion Data Declaration

#region Tool

& $dataPath\Modules\Tools.ps1

#endregion Tool

#region Business function

#endregion Business function

#region Main

Start-Log -LogPath (Split-Path $LogPath) -LogName (Split-Path $logPath -Leaf) -ScriptVersion "1.5" | Out-Null
$Common = @"
ScriptDir : $ScriptDir
dataPath : $dataPath
ScriptVersion : $ScriptVersion

"@

LogAndDisplay $Common

if ($Prod.IsPresent) 
{
    
    LogAndDisplay @"
List of Exceptions encountered during the execution :
$($Error)
"@
    if ($Mail.IsPresent)
    {
        Stop-Log -LogPath $logPath -NoExit
        Stop-Transcript
        
        sleep -Milliseconds 500
        
        $req = (ls "$(Split-Path -parent $dataPath)\*.ps1" | where name -NotMatch "Tests.ps1")
        $Subject = ($req | select Name).Name
        $Sender = ($req | select BaseName).BaseName + "@ScriptReport.com"
        $pathLogs = @(ls $dataPath\Logs\*.log | sort -Property LastWriteTime -Descending | select -First 1 | select FullName).FullName
        $pathLogsExcel = ""
        $pathScript_ = "$env:TMP\$ScriptName._ps1"
        cp $ScriptFullName $pathScript_ -Force
        $body = "Here are the script results $(($req | select BaseName).BaseName) 
from $(HOSTNAME.EXE) : $ScriptDir"

        if ((ls $dataPath\Logs\*.csv) -ne $null)
        {
            $pathLogsExcel = @(ls $dataPath\Logs\*.csv | sort -Property LastWriteTime -Descending | select -First 1 | select FullName).FullName
        }
        else
        {
            $pathLogsExcel = "$dataPath\Logs\NoInput.csv"
            "No inputs in csv file, please check .log file" > $pathLogsExcel
        }

        if ($MailDstCC -ne "")
        {
            SendMail -subject $Subject -Receiver $MailDst -CC $MailDstCC -Sender $Sender -SmtpServerName $SmtpServerName -SmtpServerIP $SmtpServerIP -Body $body -Attachment @($pathLogs, $pathLogsExcel,$pathScript_)
        }
        else
        {
            SendMail -subject $Subject -Receiver $MailDst -Sender $Sender -SmtpServerName $SmtpServerName -SmtpServerIP $SmtpServerIP -Body $body -Attachment @($pathLogs, $pathLogsExcel,$pathScript_)
        }
    }
}
else 
{
    Stop-Log -LogPath $logPath -NoExit
}

#endregion Main
