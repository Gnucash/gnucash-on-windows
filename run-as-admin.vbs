' Attempt to run the command passed with administrator privileges
' on Windows versions starting from Vista
' On Windows XP it will just run the command with current privileges

' Note: this script uses ShellExecute to elevate privileges when
' necessary. This command however is asynchronous but we want to
' wait for it to finish.
' There is no good universal way to do this. I have chosen to
' read the running processes list and wait for as long as the name of the requested
' command is still in the list. This as limitations:
' - if the started command immediatly starts another command and then quits
'   this test will fail and run-as admin.vbs script will exit too soon
' - if a command appears with a different name in the process list than what is
'   passed as argument, this will fail as well
' - if more than one instance of the command are running, run-as-admin.vbs will
'   only quit if all instances have exited.
' For our limited purposes this is ok for now (we only wait for a windows installer
' to finish)

' Parameters:
' - strInstFile: name of the command to run, without path
' - strInstParms: parameters to pass to the command
' - strInstPath: directory in which the command is stored if not in the system path
' Note: if you don't have any parameters to add to the command call, you still need
'       to set strInstParms to the empty string ("")

strInstFile = WScript.Arguments (0)
strInstPath = WScript.Arguments (1)
strInstPath = WScript.Arguments (2)

' Read OS version number
strComputer = "."
Set objWMIService = GetObject("winmgmts:" _
    & "{impersonationLevel=impersonate}!\\" _
    & strComputer & "\root\cimv2")
Set colOperatingSystems = objWMIService.ExecQuery _
    ("Select * from Win32_OperatingSystem")
For Each objOperatingSystem in colOperatingSystems
    strVersion = objOperatingSystem.Version
Next

' Parse only major version.
' Windows Vista is version 6.0 so any Windows version with a major
' version >= 6 needs elevated privileges
' Note this ignores various Windows server editions between XP and Vista
' assuming those are not used for gnucash development
Set objRegExp = new RegExp
objRegExp.Global = True
objRegExp.Pattern = "\..*"
strMajor = objRegExp.Replace (strVersion, "")

If cint (strMajor = 5) Then
    ' Windows XP - just execute without any extras
    strCommand = "open"
Else
    ' Windows Vista or up - run with elevated privileges
    strCommand = "runas"
End If


set objShell = CreateObject("shell.application")
objShell.ShellExecute strInstFile, strInstParms, strInstPath, strCommand, 1

WScript.Sleep 100
Set objShell2 = WScript.CreateObject("WScript.Shell")
Set objExecObject = objShell2.Exec("cscript //nologo get-install-path.vbs")

Do
    WScript.Sleep 100
    bStillRunning = False
    For Each objProcess In objWMIService.InstancesOf("Win32_process")
        If objProcess.Name = strInstFile Then
            bStillRunning = True
            Exit For
        End If
    Next
Loop While bStillRunning = True