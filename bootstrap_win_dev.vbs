' bootstap_win_dev.vbs
'
' The goal of this script is to simplify setting up a development
' environment to develop for GnuCash on Windows.
' It will set up an absolute minimal environment from where
' the regular GnuCash Windows build system can take over.
' This minimal environment consists of
' - mingw-get: the mingw package installer tool
' - msys-base: a basic MSYS shell environment
' - git for windows, required for:-
' - the GnuCash source code repository, cloned from the github GnuCash repository
'
' The bootstrap script can also be run on top of an existing set up
' in which case the script will only do what is necessary to get
' the above items in place. For example, if git is already installed
' in the location pointed to by GIT_DIR below, it won't be installed
' again.
'
' IN CASE OF UNEXPECTED CLOSING OF THE CONSOLE
' Please open a console (cmd.exe) and run the script under cscript.exe as follows:
' cscript.exe <path-to-this-script>
' This will keep your console open, so you can read if there were errors

' Script start
' ------------
' Ensure we have a visible console to display output
CheckStartMode

' This regexp is used to "Windoize" path names when this script is called
' from inside an msys environment (like from the build_tags.sh script)
' It should be a noop when the script is called from a pure Windows cmd prompt
Set myRegExp = New RegExp
myRegExp.Global = True
myRegExp.Pattern = "/"

' Parameters than can be overridden on the command line
' -----------------------------------------------------
' Everything will be installed in the base directory specified below.
' If this path doesn't suit you, you can specify another path as a named
' variable on the command line like so:
' bootstrap_win_dev.vbs /GLOBAL_DIR:c:\soft

' Note: avoid paths with spaces or other special characters (like &).
'       these can confuse msys/mingw or some of the tools depending on them.

' Any of the parameters set up below can be overridden in this way. 
If WScript.Arguments.Named.Exists("GLOBAL_DIR") Then
    GLOBAL_DIR = myRegExp.Replace (WScript.Arguments.Named.Item("GLOBAL_DIR"), "\")
Else
    GLOBAL_DIR = "c:\gcdev"
End If
If WScript.Arguments.Named.Exists("MINGW_DIR") Then
    MINGW_DIR = myRegExp.Replace (WScript.Arguments.Named.Item("MINGW_DIR"), "\")
Else
    MINGW_DIR  = GLOBAL_DIR & "\mingw"
End If
If WScript.Arguments.Named.Exists("TMP_DIR") Then
    TMP_DIR = myRegExp.Replace (WScript.Arguments.Named.Item("TMP_DIR"), "\")
Else
    TMP_DIR= GLOBAL_DIR & "\tmp"
End If
If WScript.Arguments.Named.Exists("DOWNLOAD_DIR") Then
    DOWNLOAD_DIR = myRegExp.Replace (WScript.Arguments.Named.Item("DOWNLOAD_DIR"), "\")
Else
    DOWNLOAD_DIR= GLOBAL_DIR & "\downloads"
End If
If WScript.Arguments.Named.Exists("GIT_PKG") Then
    GIT_PKG = WScript.Arguments.Named.Item("GIT_PKG")
Else
    GIT_PKG = "Git-1.9.4-preview20140611"
End If
If WScript.Arguments.Named.Exists("strGitBaseUrl") Then
    strGitBaseUrl = WScript.Arguments.Named.Item("strGitBaseUrl")
Else
    strGitBaseUrl = "https://github.com/msysgit/msysgit/releases/download/"
End If
If WScript.Arguments.Named.Exists("GIT_URL") Then
    GIT_URL = WScript.Arguments.Named.Item("GIT_URL")
Else
    GIT_URL = strGitBaseUrl & GIT_PKG & "/" & GIT_PKG & ".exe"
End If
If WScript.Arguments.Named.Exists("GIT_DIR") Then
    GIT_DIR = myRegExp.Replace (WScript.Arguments.Named.Item("GIT_DIR"), "\")
Else
    GIT_DIR = GLOBAL_DIR & "\git-1.9.4"
End If
If WScript.Arguments.Named.Exists("GC_WIN_REPOS_URL") Then
    GC_WIN_REPOS_URL = WScript.Arguments.Named.Item("GC_WIN_REPOS_URL")
Else
    GC_WIN_REPOS_URL = "git://github.com/Gnucash/gnucash-on-windows.git"
End If
If WScript.Arguments.Named.Exists("GC_WIN_REPOS_DIR") Then
    GC_WIN_REPOS_DIR = myRegExp.Replace (WScript.Arguments.Named.Item("GC_WIN_REPOS_DIR"), "\")
Else
    GC_WIN_REPOS_DIR = GLOBAL_DIR & "\gnucash-on-windows.git"
End If
If WScript.Arguments.Named.Exists("REPOS_URL") Then
    REPOS_URL = WScript.Arguments.Named.Item("REPOS_URL")
Else
    REPOS_URL = "git://github.com/Gnucash/gnucash.git"
End If
If WScript.Arguments.Named.Exists("REPOS_DIR") Then
    REPOS_DIR = myRegExp.Replace (WScript.Arguments.Named.Item("REPOS_DIR"), "\")
Else
    REPOS_DIR = GLOBAL_DIR & "\gnucash.git"
End If

' If you want the script to run without prompting the user,
' add the /silent:yes switch to the command line
' It will still print output though to help in locating errors
silent = False
If WScript.Arguments.Named.Exists("silent") Then
    silent = True
End If

' Parameters that can't/shouldn't be overridden
'----------------------------------------------
' Global parameters for visual basic
Set objFso = CreateObject("Scripting.FileSystemObject")
Set stdout = objFso.GetStandardStream(1)
Set stdin  = objFso.GetStandardStream(0)
Set objWsh = WScript.CreateObject ("WScript.Shell")
Const ForReading = 1, ForWriting = 2, ForAppending = 8

Welcome


' Create base directories if necessary
' ------------------------------------
If Not objFso.FolderExists(GLOBAL_DIR) Then
    stdout.Write "Creating " & GLOBAL_DIR & "... "
    objFso.CreateFolder(GLOBAL_DIR)
    stdout.WriteLine "Ok"
End If
If Not objFso.FolderExists(MINGW_DIR) Then
    stdout.Write "Creating " & MINGW_DIR & "... "
    objFso.CreateFolder(MINGW_DIR)
    stdout.WriteLine "Ok"
End If
If Not objFso.FolderExists(TMP_DIR) Then
    stdout.Write "Creating " & TMP_DIR & "... "
    objFso.CreateFolder(TMP_DIR)
    stdout.WriteLine "Ok"
End If
If Not objFso.FolderExists(DOWNLOAD_DIR) Then
    stdout.Write "Creating " & DOWNLOAD_DIR & "... "
    objFso.CreateFolder(DOWNLOAD_DIR)
    stdout.WriteLine "Ok"
End If


' Install mingw-get
' -----------------

strMingwGet = MINGW_DIR & "\bin\mingw-get.exe"
stdout.Write "Checking " & strMingwGet & "... "
If objFso.FileExists(strMingwGet) Then
    stdout.WriteLine "Found, no need to install"
Else
    stdout.WriteLine "Not found, will be installed"

    strMingwGetZip = DOWNLOAD_DIR & "\mingw-get.zip"
    If Not objFso.FileExists(strMingwGetZip) Then
        stdout.Write "Downloading mingw-get.zip (slow!)... "
        strMingwGetZipUrl = "https://github.com/Gnucash/gnucash-on-windows/raw/master/mingw-get.zip"
        HTTPDownloadBinaryFile strMingwGetZipUrl, strMingwGetZip
        stdout.WriteLine "Success"
    End If

    ' Extract mingw-get.zip into our MINGW_DIR
    ' using a detour via a temporary directory to deal with the
    ' cludgy way to detect when extracting is finished.
    ' I couldn't find a better way so far.
    stdout.Write "Installing mingw-get... "
    strMingwTmpDir = TMP_DIR & "\mingwtmp"
    If objFso.FolderExists(strMingwTmpDir) Then
        objFso.DeleteFolder strMingwTmpDir , True
    End If
    ExtractAll DOWNLOAD_DIR & "\mingw-get.zip", strMingwTmpDir
    objFso.CopyFolder strMingwTmpDir & "\*", MINGW_DIR, True
    objFso.DeleteFolder strMingwTmpDir , True
    ' Create a default profile for mingw-get to avoid constant warnings
    objFso.CopyFile MINGW_DIR & "\var\lib\mingw-get\data\defaults.xml", MINGW_DIR & "\var\lib\mingw-get\data\profile.xml"
    stdout.WriteLine "Success"

End If


' Instal Basic Msys (we need msys-wget to install git)
' ----------------------------------------------------
' Note: we don't check if these are installed already.
'       mingw-get will do this for us automatically.
stdout.Write "Installing msys and wget... "
strMingwGet = MINGW_DIR & "\bin\mingw-get.exe"

objWsh.Run strMingwGet & " install mingw-get msys-base msys-wget msys-patch", 1, True
'Set objExec = objWsh.Exec (strMingwGet & " install msys-base msys-wget")

strWget = MINGW_DIR & "\msys\1.0\bin\wget.exe"
If Not objFso.FileExists(strWget) Then
    stdout.WriteLine "Failed"
    stdout.WriteBlankLines (1)
    stdout.WriteLine "*** ERROR ***"
    stdout.WriteLine "Msys/Wget installation failed."
    stdout.WriteBlankLines (1)
    stdout.WriteLine "Cannot continue until this has been resolved."
    AbortScript
End If
stdout.WriteLine "Success"


' Install Git
' -----------
strGit = GIT_DIR & "\bin\git.exe"
stdout.Write "Checking " & strGit & "... "
If objFso.FileExists(strGit) Then
    stdout.WriteLine "Found, no need to install"
Else
    stdout.WriteLine "Not found, will be installed"

    strGitPkg = DOWNLOAD_DIR & "\" & GIT_PKG & ".exe"
    If Not objFso.FileExists(strGitPkg) Then
        stdout.Write "Downloading git installer... "
        objWsh.Run strWget & " -O" & strGitPkg & " --no-check-certificate " & GIT_URL, 1, true

        If Not objFso.FileExists(strGitPkg) Then
            stdout.WriteLine "Failed"
            stdout.WriteBlankLines (1)
            stdout.WriteLine "*** ERROR ***"
            stdout.WriteLine "Download git installer failed."
            stdout.WriteBlankLines (1)
            stdout.WriteLine "Cannot continue until this has been resolved."
            AbortScript
        End If
        stdout.WriteLine "Success"
    End If

    stdout.Write "Installing git... "
    objWsh.Run strGitPkg & " /SP- /SILENT /DIR=" & GIT_DIR, 1, true

    If Not objFso.FileExists(strGit) Then
        stdout.WriteLine "Failed"
        stdout.WriteBlankLines (1)
        stdout.WriteLine "*** ERROR ***"
        stdout.WriteLine "Git installation failed."
        stdout.WriteBlankLines (1)
        stdout.WriteLine "Cannot continue until this has been resolved."
        AbortScript
    End If
    stdout.WriteLine "Sucess"
End If


' Set up gnucash-on-windows git repository
' ----------------------------------------
strBootstrap = GC_WIN_REPOS_DIR & "\bootstrap_win_dev.vbs"
stdout.WriteLine "Checking if " & GC_WIN_REPOS_DIR
stdout.Write "         is a gnucash-on-windows git repository... "
If objFso.FolderExists(GC_WIN_REPOS_DIR & "\.git") And objFso.FileExists(strBootstrap) Then
    stdout.WriteLine "Most likely ok, won't clone"
Else
    stdout.WriteLine "Not found"
    stdout.WriteLine "Set up gnucash-on-windows git repository... "
    objWsh.Run strGit & " clone " & GC_WIN_REPOS_URL & " " & GC_WIN_REPOS_DIR, 1, true

    If Not objFso.FileExists(strBootstrap) Then
        stdout.WriteLine "Failed"
        stdout.WriteBlankLines (1)
        stdout.WriteLine "*** ERROR ***"
        stdout.WriteLine "Failed to set up gnucash-on-windows git repository."
        stdout.WriteBlankLines (1)
        stdout.WriteLine "Cannot continue until this has been resolved."
        AbortScript
    End If
    stdout.WriteLine "Ok"
End If


' Set up gnucash git repository
' -----------------------------
strGCbin = REPOS_DIR & "\gnucash\gnucash-bin.c"
stdout.WriteLine "Checking if " & REPOS_DIR
stdout.Write "         is a GnuCash git repository... "
If objFso.FolderExists(REPOS_DIR & "\.git") And objFso.FileExists(strGCbin) Then
    stdout.WriteLine "Most likely ok, won't clone"
Else
    stdout.WriteLine "Not found"
    stdout.WriteLine "Set up GnuCash git repository... "
    objWsh.Run strGit & " clone " & REPOS_URL & " " & REPOS_DIR, 1, true

    If Not objFso.FileExists(strGCbin) Then
        stdout.WriteLine "Failed"
        stdout.WriteBlankLines (1)
        stdout.WriteLine "*** ERROR ***"
        stdout.WriteLine "Failed to set up GnuCash git repository."
        stdout.WriteBlankLines (1)
        stdout.WriteLine "Cannot continue until this has been resolved."
        AbortScript
    End If
    stdout.WriteLine "Ok"
End If

' Create custom.sh
' ----------------
strCustomSh = GC_WIN_REPOS_DIR & "\custom.sh"
bExistingCustomSh = False
If objFso.FileExists(strCustomSh) Then
    stdout.WriteLine "Found existing custom.sh file"
    bExistingCustomSh = True
Else
    ' Create a custom.sh file that matches the parameters set at the beginning of this script
    ' This ensures install.sh will find the development environment we set up
    ' Note: we're deliberately not storing versions of used components in the autogenerated custom.sh
    '       This allows install.sh to update to newer versions if deemed useful
    stdout.Write "Autogenerating custom.sh file... "
    Set myRegExp = New RegExp
    myRegExp.Global = True
    myRegExp.Pattern = "\\"

    strGlobalDir     = myRegExp.Replace (GLOBAL_DIR, "\\")
    strMingwDir      = myRegExp.Replace (MINGW_DIR, "\\")
    strMsysDir       = myRegExp.Replace (MINGW_DIR & "\msys\1.0", "\\")
    strTmpDir        = myRegExp.Replace (TMP_DIR, "\\")
    strDownloadDir   = myRegExp.Replace (DOWNLOAD_DIR, "\\")
    strGitDir        = myRegExp.Replace (GIT_DIR, "\\")
    strGCWinReposDir = myRegExp.Replace (GC_WIN_REPOS_DIR, "\\")
    strReposDir      = myRegExp.Replace (REPOS_DIR, "\\")

    Set objCustomSh = objFso.OpenTextFile( strCustomSh, ForWriting, True )
    objCustomSh.WriteLine "# custom.sh, automatically created by bootstrap_win_dev.vbs"
    objCustomSh.WriteLine "#"
    objCustomSh.WriteLine "# The parameters set here match the parameters used by"
    objCustomSh.WriteLine "# bootstrap_win_dev.vbs to set up the GnuCash development"
    objCustomSh.WriteLine "# environment and should ensure the install.sh works out"
    objCustomSh.WriteLine "# of the box."
    objCustomSh.WriteLine "#"
    objCustomSh.WriteLine "# You are free to modify these parameters to suit you,"
    objCustomSh.WriteLine "# but keep in mind that if you ever want to run"
    objCustomSh.WriteLine "# bootstrap_win_dev.vbs again you should make sure"
    objCustomSh.WriteLine "# the parameters it uses match the ones you set here."
    objCustomSh.WriteBlankLines 1
    objCustomSh.WriteLine "GLOBAL_DIR=" & strGlobalDir
    objCustomSh.WriteLine "MINGW_DIR=" & strMingwDir
    objCustomSh.WriteLine "MSYS_DIR=" & strMsysDir
    objCustomSh.WriteLine "TMP_DIR=" & strTmpDir
    objCustomSh.WriteLine "DOWNLOAD_DIR=" & strDownloadDir
    objCustomSh.WriteLine "GIT_DIR=" & strGitDir
    objCustomSh.WriteLine "REPOS_TYPE=git" ' Bootstrap only works with a git repo
    objCustomSh.WriteLine "GC_WIN_REPOS_URL=" & GC_WIN_REPOS_URL
    objCustomSh.WriteLine "GC_WIN_REPOS_DIR=" & strGCWinReposDir
    objCustomSh.WriteLine "REPOS_URL=" & REPOS_URL
    objCustomSh.WriteLine "REPOS_DIR=" & strReposDir
    objCustomSh.Close
    stdout.WriteLine "Success"
End If


' End message
' -----------
stdout.WriteBlankLines 1
stdout.WriteLine "Bootstrap completed successfully !"
stdout.WriteBlankLines 1
stdout.WriteLine "You can now continue as follows"
stdout.WriteLine "- Use git to checkout the desired branch/tag in " & REPOS_DIR
stdout.WriteLine "- Open the msys shell"
stdout.WriteLine "- cd " & GC_WIN_REPOS_DIR
stdout.WriteLine "- Properly configure a custom.sh"
stdout.WriteLine "  (if you changed any default path in the bootstrap script)"
stdout.WriteLine "- Run install.sh"
stdout.WriteBlankLines 1
stdout.WriteLine "Happy hacking !"

AbortScript


' Functions used in the script
' ----------------------------
' Initial message to user
Sub Welcome
    If silent then
        ' Don't interact with user if in silent mode
        stdout.WriteLine "Skipping intro because silent mode was set"
        Exit Sub
    End If

    stdout.WriteLine "Boostrap GnuCash Development on Windows"
    stdout.WriteLine "---------------------------------------"
    stdout.WriteLine "This script is intended for people that wish to develop GnuCash on Windows"
    stdout.WriteLine "It will download and install the minimal set of tools"
    stdout.WriteLine "to run a first build of the GnuCash sources."
    stdout.WriteLine "It will install"
    stdout.WriteLine "- mingw-get, an msys shell and wget in " & MINGW_DIR
    stdout.WriteLine "- git in " & GIT_DIR
    stdout.WriteLine "- a gnucash-on-windows git repository cloned from"
    stdout.WriteLine "  " & GC_WIN_REPOS_URL
    stdout.WriteLine "  into " & GC_WIN_REPOS_DIR
    stdout.WriteLine "- a GnuCash git repository cloned from"
    stdout.WriteLine "  " & REPOS_URL
    stdout.WriteLine "  into " & REPOS_DIR
    stdout.WriteBlankLines 1
    stdout.WriteLine "Notes:"
    stdout.WriteLine "* Components already found in the given locations"
    stdout.WriteLine "  won't be touched. Instead the available versions"
    stdout.WriteLine "  will be used in that case."
    stdout.WriteLine "* If the proposed locations don't suit you, you can"
    stdout.WriteLine "  pass alternate locations as named parameters to this script."
    stdout.WriteLine "  For example to use c:\soft as base directory you can run this script as"
    stdout.WriteLine "  bootstrap_win_dev.vbs /GLOBAL_DIR:c:\soft"
    stdout.WriteLine "  Which parameters you can modify can be found near the beginning of this script."
    stdout.WriteBlankLines 1
    stdout.Write "Continue with the set up (Y/N) ? "
    chRead = stdin.ReadLine
    If Not (UCase(Left(chRead,1)) = "Y") Then
        stdout.WriteLine "Installation interrupted."
        AbortScript
    End If
End Sub
    

' Download a binary type file over http
Sub HTTPDownloadBinaryFile( myURL, myPath )
' This Sub downloads the FILE specified in myURL to the path specified in myPath.
'
' myURL must always end with a file name
' myPath may be a directory or a file name; in either case the directory must exist
'
' Based on a script written by Rob van der Woude
' http://www.robvanderwoude.com
' Ref: https://stackoverflow.com/questions/29367130/downloading-a-file-in-vba-and-storing-it

    ' Standard housekeeping
    Dim i, objFile, objHTTP, strFile, strMsg

    Const adSaveCreateOverWrite = 2, adSaveCreateNotExist = 1
    Const adTypeBinary = 1

    ' Check if the specified target file or folder exists,
    ' and build the fully qualified path of the target file
    If objFso.FolderExists( myPath ) Then
        strFile = objFso.BuildPath( myPath, Mid( myURL, InStrRev( myURL, "/" ) + 1 ) )
    ElseIf objFso.FolderExists( Left( myPath, InStrRev( myPath, "\" ) - 1 ) ) Then
        strFile = myPath
    Else
        stdout.WriteLine "ERROR: Target folder not found."
        AbortScript
    End If

    ' Create an HTTP object
    Set objHTTP = CreateObject( "MSXML2.ServerXMLHTTP" )

    ' Download the specified URL
    objHTTP.Open "GET", myURL, False
    objHTTP.Send

    ' Write the downloaded byte stream to the target file
    If objHTTP.Status = 200 Then
        ' Create the target stream
        Set oStream = WScript.CreateObject( "ADODB.Stream" )
        oStream.Open
        oStream.Type = adTypeBinary
        oStream.Write objHTTP.responseBody
        oStream.SaveToFile strFile, adSaveCreateOverWrite ' 1 = no overwrite, 2 = overwrite
        ' Close the target file
        oStream.Close
    End If
End Sub

' Extract a zip file strZipFile into strFolder
Function ExtractAll(strZipFile, strFolder)
   Set objShell = CreateObject("Shell.Application")
   If Not objFso.FolderExists(strFolder) Then
       objFso.CreateFolder(strFolder)
   End If

   intCount = objShell.NameSpace(strFolder).Items.Count
   Set colItems = objShell.NameSpace(strZipFile).Items
   objShell.NameSpace(strFolder).CopyHere colItems, 256
   Do Until objShell.NameSpace(strFolder).Items.Count = intCount + colItems.Count
       WScript.Sleep 200
   Loop
End Function


' Make sure we run in a console (so output is visible)
' Blatantly copied from
' https://stackoverflow.com/questions/4692542/force-a-vbs-to-run-using-cscript-instead-of-wscript
Sub CheckStartMode
    Dim Arg, Str
    If Not LCase( Right( WScript.FullName, 12 ) ) = "\cscript.exe" Then
        For Each Arg In WScript.Arguments
            If InStr( Arg, " " ) Then Arg = """" & Arg & """"
            Str = Str & " " & Arg
        Next
        CreateObject( "WScript.Shell" ).Run _
            "cscript //nologo """ & _
            WScript.ScriptFullName & _
            """ " & Str
        WScript.Quit
    End If
End Sub


' Abort the script
Sub AbortScript
    If silent then
        ' Don't interact with user if in silent mode
        Exit Sub
    End If

    stdout.WriteBlankLines 1
    stdout.Write "Pres enter to continue... "
    chRead = stdin.Read (1)
    WScript.Quit
End Sub

