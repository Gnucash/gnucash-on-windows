' This helper script will try to determine the installation directory
' for HTML Help Workshop. If found it will be returned on stdout
'
' Exit codes:
'    0 if program was found to be installed
'    1 if program was not found to be installed

' Note: the script works as follows
'    - it will query the Uninstall information in the Windows registry
'    - when it finds uninstall information for HTML Help Workshop it will read the uninstall string
'    - and will extract the installation path from this string

Const HKLM = &H80000002 'HKEY_LOCAL_MACHINE

strKey = "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"
strDisplayName = "DisplayName"
strUninstallString = "UninstallString"

Set objReg = GetObject("winmgmts://./root/default:StdRegProv")
objReg.EnumKey HKLM, strKey, arrSubkeys

For Each strSubkey In arrSubkeys
    intRet1 = objReg.GetStringValue(HKLM, strKey & strSubkey, strDisplayName, strValue)
    If strValue = "HTML Help Workshop" Then
        intRet1 = objReg.GetStringValue(HKLM, strKey & strSubkey, strUninstallString, strValue)
        Set myRegExp = new RegExp
        myRegExp.Global = True
        myRegExp.Pattern = "\\setup.exe.*"
        strInstallDir = myRegExp.Replace (strValue, "")
        WScript.Echo strInstallDir
        WScript.Quit 0
    End If
Next

WScript.Quit 1