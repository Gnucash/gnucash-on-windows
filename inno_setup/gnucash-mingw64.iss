; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Input configuration for the Inno Setup Compiler
; Copyright (c) 2004-2005 Christian Stimming <stimming@tuhh.de>
; Copyright 2017 John Ralls <jralls@ceridwen.us>
; Inno Setup Compiler: See http://www.jrsoftware.org/isdl.php
; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

[Setup]
; Using the name here directly because we want it capitalized
AppName=GnuCash
AppVersion=@PACKAGE_VERSION@
AppVerName=GnuCash @PACKAGE_VERSION@
AppPublisher=GnuCash Development Team
AppPublisherURL=http://www.gnucash.org
AppSupportURL=http://www.gnucash.org
AppUpdatesURL=http://www.gnucash.org
VersionInfoVersion=@PACKAGE_VERSION@
DefaultDirName={pf}\@PACKAGE@
DefaultGroupName=GnuCash
InfoBeforeFile=@INST_DIR@\share\doc\@PACKAGE@\LICENSE
Compression=lzma
MinVersion=5.0
PrivilegesRequired=poweruser
OutputDir=.
OutputBaseFilename=@PACKAGE@-@PACKAGE_VERSION@.setup
UninstallFilesDir={app}\uninstall\@PACKAGE@
InfoAfterFile=@GC_WIN_REPOS_DIR@\inno_setup\README.win32-bin.txt
SetupIconFile=@INST_DIR@\share\@PACKAGE@\pixmaps\gnucash-icon.ico
WizardSmallImageFile=@INST_DIR@\share\@PACKAGE@\pixmaps\gnucash-icon-48x48.bmp

[Types]
Name: "full"; Description: "{cm:FullInstall}"
Name: "custom"; Description: "{cm:CustomInstall}"; Flags: iscustom

[Components]
Name: "main"; Description: "{cm:MainFiles}"; Types: full custom; Flags: fixed
Name: "translations"; Description: "{cm:TranslFiles}"; Types: full
Name: "templates"; Description: "{cm:TemplFiles}"; Types: full

[Tasks]
Name: desktopicon; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"
Name: menuicon; Description: "{cm:CreateMenuLink}"; GroupDescription: "{cm:AdditionalIcons}"

[Icons]
Name: "{group}\GnuCash"; Filename: "{app}\bin\@PACKAGE@.exe"; WorkingDir: "{code:GetDocPath}"; Comment: "{cm:IconComment_GnuCash}"; IconFilename: "{app}\share\@PACKAGE@\pixmaps\gnucash-icon.ico"; Tasks: menuicon
Name: "{group}\{cm:IconName_README}"; Filename: "{app}\doc\@PACKAGE@\{cm:IconFilename_README}"; Comment: "{cm:IconComment_README}"; Tasks: menuicon
Name: "{group}\{cm:IconName_FAQ}"; Filename: "http://wiki.gnucash.org/wiki/FAQ"; Tasks: menuicon
Name: "{group}\{cm:IconName_Bugzilla}"; Filename: "https://bugs.gnucash.org/enter_bug.cgi?product=GnuCash"; Tasks: menuicon
Name: "{group}\{cm:IconName_InstallFQ}"; Filename: "{syswow64}/WindowsPowershell/v1.0/powershell.exe"; Parameters: "-ExecutionPolicy Bypass -File ""{app}\bin\install-fq-mods.ps1"""; WorkingDir: "{app}\bin"; Comment: "{cm:IconComment_InstallFQ}"; Tasks: menuicon
Name: "{group}\{cm:IconName_Uninstall}"; Filename: "{uninstallexe}"; Comment: "{cm:IconComment_Uninstall}"; Tasks: menuicon

Name: "{commondesktop}\GnuCash"; Filename: "{app}\bin\@PACKAGE@.exe"; WorkingDir: "{code:GetDocPath}"; Comment: "{cm:IconComment_GnuCash}"; IconFilename: "{app}\share\@PACKAGE@\pixmaps\gnucash-icon.ico"; Tasks: desktopicon

[Run]
Filename: "{app}\bin\@PACKAGE@.exe"; Description: "{cm:RunPrg}"; WorkingDir: "{code:GetDocPath}"; OnlyBelowVersion: 0,6; Flags: postinstall skipifsilent

; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Here we configure the included files and the place of their
; installation
; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
[Files]
;;;; The first section retrieves files built with jhbuild from the prefix directory.
; The main executables and DLLs
Source: "@INST_DIR@\bin\*"; DestDir: "{app}\bin"; Flags: recursesubdirs ignoreversion; Components: main
Source: "@INST_DIR@\etc\*"; DestDir: "{app}\etc"; Flags: recursesubdirs; Components: main
Source: "@INST_DIR@\etc\@PACKAGE@\environment"; DestDir: "{app}\etc\@PACKAGE@"; Components: main; AfterInstall: MyAfterInstallEnvironment()
; Note: The above AfterInstall function will adapt the
; environment config file on-the-fly by the Pascal script below.
Source: "@INST_DIR@\lib\*"; DestDir: "{app}\lib"; Flags: recursesubdirs; Components: main
; Deprecated installation location for gnucash guile scripts. Can be removed after we're done with gnucash 3.x
Source: "@INST_DIR@\lib\gnucash\scm\ccache\2.2\*"; DestDir: "{app}\lib\gnucash\scm\ccache\2.2"; Flags: recursesubdirs skipifsourcedoesntexist; Components: main
Source: "@INST_DIR@\lib\guile\2.2\*"; DestDir: "{app}\lib\guile\2.2"; Flags: recursesubdirs; Components: main
Source: "@INST_DIR@\lib\dbd\*.dll"; DestDir: "{app}\lib"; Components: main
Source: "@INST_DIR@\lib\aqbanking\*"; DestDir: "{app}\lib\aqbanking"; Excludes: "*.dll.a"; Flags: recursesubdirs; Components: main
Source: "@INST_DIR@\lib\gwenhywfar\*"; DestDir: "{app}\lib\gwenhywfar"; Excludes: "*.dll.a"; Flags: recursesubdirs; Components: main
;; We don't have anything in libexec anymore at the moment
;Source: "@INST_DIR@\libexec\*"; DestDir: "{app}\libexec"; Flags: recursesubdirs; Components: main
;; Retrieve all of the share directories for the package and its dependencies
Source: "@INST_DIR@\share\@PACKAGE@\*"; DestDir: "{app}\share\@PACKAGE@"; Flags: recursesubdirs; Components: main
Source: "@INST_DIR@\share\aqbanking\*"; DestDir: "{app}\share\aqbanking"; Flags: recursesubdirs; Components: main
Source: "@INST_DIR@\share\gwenhywfar\*"; DestDir: "{app}\share\gwenhywfar"; Flags: recursesubdirs; Components: main
Source: "@INST_DIR@\share\chipcard\*"; DestDir: "{app}\share\chipcard"; Flags: recursesubdirs; Components: main
Source: "@INST_DIR@\share\guile\*"; DestDir: "{app}\share\guile"; Flags: recursesubdirs; Components: main
Source: "@INST_DIR@\share\glib-2.0\*"; DestDir: "{app}\share\glib-2.0"; Flags: recursesubdirs; Components: main
Source: "@INST_DIR@\share\libofx\*"; DestDir: "{app}\share\libofx"; Flags: recursesubdirs; Components: main
Source: "@INST_DIR@\share\OpenSP\*"; DestDir: "{app}\share\OpenSP"; Flags: recursesubdirs; Components: main
Source: "@INST_DIR@\share\icons\hicolor\*"; DestDir: "{app}\share\icons\hicolor"; Flags: recursesubdirs; Components: main
Source: "@INST_DIR@\share\glib-2.0\schemas\*"; DestDir: "{app}\share\glib-2.0\schemas"; Flags: recursesubdirs; Components: main

;; The translations
Source: "@INST_DIR@\share\locale\*"; DestDir: "{app}\share\locale"; Flags: recursesubdirs; Components: translations
;
;; The account templates
Source: "@INST_DIR@\share\@PACKAGE@\accounts\*"; DestDir: "{app}\share\@PACKAGE@\accounts"; Flags: recursesubdirs; Components: templates

; And all the @PACKAGE@ documentation
Source: "@INST_DIR@\share\doc\@PACKAGE@\README"; DestDir: "{app}\doc\@PACKAGE@"; Components: main
Source: "@GC_WIN_REPOS_DIR@\inno_setup\README.win32-bin.txt"; DestDir: "{app}\doc\@PACKAGE@"; Components: main
Source: "@GC_WIN_REPOS_DIR@\inno_setup\README-ca.win32-bin.txt"; DestDir: "{app}\doc\@PACKAGE@"; Components: main
Source: "@GC_WIN_REPOS_DIR@\inno_setup\README-de.win32-bin.txt"; DestDir: "{app}\doc\@PACKAGE@"; Components: main
Source: "@GC_WIN_REPOS_DIR@\inno_setup\README-fr.win32-bin.txt"; DestDir: "{app}\doc\@PACKAGE@"; Components: main
Source: "@GC_WIN_REPOS_DIR@\inno_setup\README-it.win32-bin.txt"; DestDir: "{app}\doc\@PACKAGE@"; Components: main
Source: "@GC_WIN_REPOS_DIR@\inno_setup\README-zh_CN.win32-bin.txt"; DestDir: "{app}\doc\@PACKAGE@"; Components: main
Source: "@GC_WIN_REPOS_DIR@\inno_setup\README-zh_TW.win32-bin.txt"; DestDir: "{app}\doc\@PACKAGE@"; Components: main
Source: "@INST_DIR@\share\doc\@PACKAGE@\LICENSE"; DestDir: "{app}\doc\@PACKAGE@"; Flags: ignoreversion; Components: main
Source: "@INST_DIR@\share\doc\@PACKAGE@\AUTHORS"; DestDir: "{app}\doc\@PACKAGE@"; Components: main
Source: "@INST_DIR@\share\doc\@PACKAGE@\ChangeLog"; DestDir: "{app}\doc\@PACKAGE@"; Components: main
Source: "@INST_DIR@\share\doc\@PACKAGE@-docs\*.chm"; DestDir: "{app}\share\@PACKAGE@\help"; Flags: recursesubdirs; Components: main
Source: "@INST_DIR@\share\doc\@PACKAGE@-docs\*.hhmap"; DestDir: "{app}\share\@PACKAGE@\help"; Flags: recursesubdirs; Components: main

;;;; The second section retrieves the dependencies that we need from MinGW.
;; Required DLLs
;; gnucash.exe: libglib-2.0-0.dll, libgtk-3-0.dll, ligdk-3-0.dll, libatk-1.0-dll, libgobject-2.0-0.dll, libintl-8.dll, libcairo-gobject-2.dll, libcairo-2.dll, libfontconfig-1.0.dll, libcrypto-3.dll, libfreetype-6.dll, libpixman-1-0.dll, libpng16-16.dll, zlib1.dll, libgdk-pixbuf-2.0-0.dll, libgio-2.0-0.dll, libgmodule-2.0-0.dll, libpango-1.0-0.dll, libpangocairo-1.0-0.dll, libpangowin32-1.0-0.dll, libpangoft2-1.0-0.dll, libpcre2-8-0.dll, libharfbuzz-0.dll, libharpyuv-0.dll, libfribidi-0.dll, libiconv-2.dll, libwinpthread-1.dll, libsecret-1-0.dll, libsystre-0.dll, libxml2-2.dll, libxml2-16.dll, libxslt-1.dll, libicuuc57.dll, libicudt57.dll, libtre-5.dll, libffi-8.dll, libgmp-10.dll, libltdl-7.dll
;; AQBanking: libgcrypt-20.dll, libgnutls-30.dll, libwinpthread-1.0.dll, libgmp-10.dll, libhogweed-6.dll, libidn-11.dll, libintl-8.dll, libnettle-8.dll, libp11-kit-0.dll, libtasn1-6.dll, zlib1.dll, libgpg-error-0.dll, libiconv-2.dll, libintl-8.dll, libgtk-win32-2.0-0.dll
;; libwebkit: libbrotlicommon.dll, libbrotlidec.dll libharfbuzz-icu-0.dll, liborc-0.4-0.dll, libgsttag-1.0-0.dll, libgraphite2.dll, libicudt65.dll, libicuin65.dll, liicuuc65.dll, libicudt.dll, libsoup-2.4-1.dll, libsqlite3-0.dll, libssl-3.dll, libstdc__-6.dll, libunistring-5.dll, libwebp-7.dll
;;lib/dbd/libdbdmysql.dll: libmariadb.dll, libeay32.dll, ssleay32.dll
;;lib/dbd/libdbdpgsql.dll: ssleay32.dll, libeay32.dll

Source: "@MINGW_DIR@\bin\libatk-1.0-0.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libboost_date_time-mt.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libboost_locale-mt.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libboost_filesystem-mt.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libboost_program_options-mt.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libboost_thread-mt.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libbz2-1.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libbrotlidec.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libbrotlicommon.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libbrotlienc.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libcairo-2.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libcairo-gobject-2.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libcurl-4.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libcrypto-3.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libdatrie-1.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libdeflate.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libepoxy-0.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libexpat-1.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libffi-8.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libfontconfig-1.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libfreetype-6.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libfribidi-0.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libgcrypt-20.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libgdk-3-0.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libgdk_pixbuf-2.0-0.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libgio-2.0-0.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libglib-2.0-0.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libgmodule-2.0-0.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libgmp-10.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libgnutls-30.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libgobject-2.0-0.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libgpg-error-0.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libgraphite2.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libgtk-3-0.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libharfbuzz-0.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libharfbuzz-icu-0.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libhogweed-6.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libiconv-2.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libicudt*.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libicuin*.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libicuuc*.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libidn2-0.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libintl-8.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libjavascriptcoregtk-3.0-0.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libjbig-0.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libjpeg-8.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libLerc.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libltdl-7.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\liblzma-5.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libnettle-8.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libnghttp2-14.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libnghttp3-9.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libngtcp2-16.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libngtcp2_crypto_ossl-0.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libp11-kit-0.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libpango-1.0-0.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libpangocairo-1.0-0.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libpangoft2-1.0-0.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libpangowin32-1.0-0.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libpcre2-8-0.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libpixman-1-0.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libpng16-16.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libpsl-5.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\librsvg-2-2.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libsharpyuv-0.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libsoup-2.4-1.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libsqlite3-0.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libssh2-1.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libssl-3.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libstdc++-6.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libsecret-1-0.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libsystre-0.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libtasn1-6.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libthai-0.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libtiff-6.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libtre-5.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libunistring-5.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libwebp-7.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libwebkitgtk-3.0-0.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libwinpthread-1.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libxml2-16.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libxslt-1.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libzstd.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\libmariadb.dll"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\zlib1.dll"; DestDir: "{app}\bin"; Components: main

Source: "@MINGW_DIR@\bin\gspawn-win32-helper.exe"; DestDir: "{app}\bin"; Components: main
Source: "@MINGW_DIR@\bin\gspawn-win32-helper-console.exe"; DestDir: "{app}\bin"; Components: main

Source: "@MINGW_DIR@\lib\gdk-pixbuf-2.0\2.10.0\loaders\*.dll"; DestDir: "{app}\lib\gdk-pixbuf-2.0\2.10.0\loaders"; Components: main
Source: "@MINGW_DIR@\lib\gdk-pixbuf-2.0\2.10.0\loaders.cache"; DestDir: "{app}\lib\gdk-pixbuf-2.0\2.10.0\"; Components: main

Source: "@MINGW_DIR@\share\icons\*"; DestDir: "{app}\share\icons"; Flags: recursesubdirs; Components: main
Source: "@MINGW_DIR@\share\themes\*"; DestDir: "{app}\share\themes"; Flags: recursesubdirs; Components: main
Source: "@MINGW_DIR@\share\xml\iso-codes\*"; DestDir: "{app}\share\xml\iso-codes"; Flags: recursesubdirs; Components: main
Source: "@MINGW_DIR@\share\xml\fontconfig\*"; DestDir: "{app}\share\xml\fontconfig"; Flags: recursesubdirs; Components: main

Source: "@MINGW_DIR@\etc\gtk-3.0\*"; Destdir: "{app}\etc\gtk-3.0"; Flags: recursesubdirs; Components: main
Source: "@MINGW_DIR@\etc\fonts\*"; DestDir: "{app}\etc\fonts"; Flags: recursesubdirs; Components: main

;;; Finally we have three files in the extra_dist directory to put in bin:
Source: "@GC_WIN_REPOS_DIR@\extra_dist\*"; DestDir: "{app}\bin"; Flags: recursesubdirs; Components: main

; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Define the registry keys Setup should create (HKLM = HKEY_LOCAL_MACHINE)
; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
[Registry]
Root: HKCR; Subkey: ".gnucash"; ValueType: string; ValueName: ""; ValueData: "GnuCash.Financial.Data"; Flags: uninsdeletevalue
Root: HKCR; Subkey: ".gnucash"; ValueType: string; ValueName: "Content Type"; ValueData: "application/x-gnucash"; Flags: uninsdeletevalue
Root: HKCR; Subkey: "GnuCash.Financial.Data"; ValueType: string; ValueName: ""; ValueData: "GnuCash Financial Data"; Flags: uninsdeletevalue
Root: HKCR; Subkey: "GnuCash.Financial.Data\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\share\@PACKAGE@\pixmaps\gnucash-icon.ico,0"
Root: HKCR; Subkey: "GnuCash.Financial.Data\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\bin\@PACKAGE@.exe"" ""%1"""

Root: HKLM; Subkey: "Software\GnuCash"; ValueType: none; Flags: uninsdeletekeyifempty
Root: HKLM; Subkey: "Software\GnuCash\Paths"; ValueType: none; Flags: uninsdeletekeyifempty
Root: HKLM; Subkey: "Software\GnuCash\Paths"; ValueType: string; ValueName: "prefix"; ValueData: "{app}"; Flags: uninsdeletevalue
Root: HKLM; Subkey: "Software\GnuCash"; ValueType: string; ValueName: "InstallationDirectory"; ValueData: "{app}"; Flags: uninsdeletevalue
Root: HKLM; Subkey: "Software\GnuCash\Paths"; ValueType: string; ValueName: "libdir"; ValueData: "{app}\lib"; Flags: uninsdeletevalue
Root: HKLM; Subkey: "Software\GnuCash\Paths"; ValueType: string; ValueName: "pkglibdir"; ValueData: "{app}\lib\@PACKAGE@"; Flags: uninsdeletevalue
Root: HKLM; Subkey: "Software\GnuCash\Paths"; ValueType: string; ValueName: "sysconfdir"; ValueData: "{app}\etc"; Flags: uninsdeletevalue
Root: HKLM; Subkey: "Software\GnuCash\Paths"; ValueType: string; ValueName: "localedir"; ValueData: "{app}\share\locale"; Flags: uninsdeletevalue

; Store the version information
Root: HKLM; Subkey: "Software\GnuCash\Version"; ValueType: none; Flags: uninsdeletekeyifempty
Root: HKLM; Subkey: "Software\GnuCash\Version"; ValueType: string; ValueName: "Version"; ValueData: "@PACKAGE_VERSION@"; Flags: uninsdeletevalue
Root: HKLM; Subkey: "Software\GnuCash\Version"; ValueType: dword; ValueName: "VersionMajor"; ValueData: "@GNUCASH_MAJOR_VERSION@"; Flags: uninsdeletevalue
Root: HKLM; Subkey: "Software\GnuCash\Version"; ValueType: dword; ValueName: "VersionMinor"; ValueData: "@GNUCASH_MINOR_VERSION@"; Flags: uninsdeletevalue

; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Delete the created config script on uninstall
; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
[UninstallDelete]
Type: files; Name: "{app}\etc\@PACKAGE@\environment"
Type: filesandordirs; Name: "{app}\share\guile"
Type: dirifempty; Name: "{app}\etc\@PACKAGE@"
Type: dirifempty; Name: "{app}\etc"

; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Perform some additional actions in code that can't be done
; by the installer by default. The code snippets below hook
; into the installer code at specific events. See
; http://www.jrsoftware.org/ishelp/index.php?topic=scriptintro
; for more information on iss scription and a syntax reference.
; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
[Code]
var
  PrevInstDetectedPage : TOutputMsgWizardPage;
  PrevAppName, PrevUninstallString : String;
  PrevVersionMajor, PrevVersionMinor, PrevVersionMicro : Cardinal;
  Uninstallrequired : Boolean;

// ----------------------------------------------------------------
// Sometimes it's not possible to install a newer version of
// GnuCash over an older one on Windows. This happens for example
// when libraries or reports are moved around in the newer version.
// The code below will detect an existing GnuCash installation
// and will remove it (if the user accepts) before installing
// the version the user has selected.
// ----------------------------------------------------------------

{ Lookup the registry information on a previous installation }
procedure GetPrevInstallInfo();
var
  sUnInstPath, sAppVersionPath: String;
  rootKey : Integer;
begin
  sAppVersionPath := 'Software\GnuCash\Version';
  sUnInstPath := 'Software\Microsoft\Windows\CurrentVersion\Uninstall\GnuCash_is1';

  PrevAppName := '';
  PrevUninstallString := '';
  PrevVersionMajor := 0;
  PrevVersionMinor := 0;
  PrevVersionMicro := 0;

  if RegKeyExists(HKLM, sUnInstPath) then
    rootKey := HKLM
  else
    rootKey := HKCU;

  RegQueryStringValue(rootKey, sUnInstPath, 'UninstallString', PrevUninstallString);
  RegQueryStringValue(rootKey, sUnInstPath, 'DisplayName', PrevAppName);
  RegQueryDwordValue(rootKey, sAppVersionPath, 'VersionMajor', PrevVersionMajor);
  RegQueryDwordValue(rootKey, sAppVersionPath, 'VersionMinor', PrevVersionMinor);
  RegQueryDwordValue(rootKey, sAppVersionPath, 'VersionMicro', PrevVersionMicro);
end;

{ Check if there is another GnuCash currently installed                  }
{ If so, the user will be prompted if it can be uninstalled first.       }
{ If the user doesn't allow uninstall, the installation will be aborted. }
procedure CheckUninstallRequired();
begin
  UninstallRequired := True;
  GetPrevInstallInfo;

  if (PrevUninstallString = '') then
    UninstallRequired := False
// We used to check on major-minor versions to determine the uninstall requirement,
// but this is not always sufficient. So the following code won't be used until
// refined.
//  else if (PrevVersionMajor = @GNUCASH_MAJOR_VERSION@) and (PrevVersionMinor = @GNUCASH_MINOR_VERSION@) then
//    UninstallRequired := False;
end;

{ Uninstall the current installation }
function UnInstallOldVersion(): Integer;
var
  sUnInstallString: String;
  iResultCode: Integer;
begin
// Return Values:
// 1 - uninstall string is empty
// 2 - error executing the UnInstallString
// 3 - successfully executed the UnInstallString

  // default return value
  Result := 0;

  if PrevUninstallString <> '' then begin
    sUnInstallString := RemoveQuotes(PrevUninstallString);
    if Exec(sUnInstallString, '/SILENT /NORESTART /SUPPRESSMSGBOXES','', SW_HIDE, ewWaitUntilTerminated, iResultCode) then
      Result := 3
    else
      Result := 2;
  end else
    Result := 1;
end;

function GetPrevAppName(Param: String): String;
begin
  Result := PrevAppName;
end;

{ Setup a page to display if a previous (incompatible) GnuCash installation is found }
procedure InitializeWizard;
begin
  CheckUninstallRequired;
  PrevInstDetectedPage := CreateOutputMsgPage(wpReady,
    ExpandConstant('{cm:AIWP_Title}'),
    ExpandConstant('{cm:AIWP_Description,{code:GetPrevAppName}}'),
    ExpandConstant('{cm:AIWP_Message,{code:GetPrevAppName}}'));
end;

{ Determine whether the previous installation page should be displayed or not }
function ShouldSkipPage(PageID: Integer): Boolean;
begin
  Result := False
  if (PageID = PrevInstDetectedPage.ID) and (not UninstallRequired) then
    Result := True;
end;

{ If a previous (incompatible) installation is present start the installation }
{ process with deleting this old installation }
procedure CurStepChanged(CurStep: TSetupStep);
begin
  if (CurStep=ssInstall) and (UninstallRequired) then
    UnInstallOldVersion();
end;

// ------------------------------------------------------------
// The GnuCash environment file contains paths that have to be
// adapted at install time. The code below does that.
// ------------------------------------------------------------
function MingwBacksl(const S: String): String;
begin
  { Modify the path name S so that it can be used by MinGW }
  if Length(ExtractFileDrive(S)) = 0 then
    Result := S
  else begin
    Result := '/'+S;
    StringChange(Result, ':\', '\');
  end;
  StringChange(Result, '\', '/');
end;

function BackslashPath(const S: String): String;
begin
  { Convert c:\soft to c:/soft }
  Result := S;
  StringChange(Result, '\', '/');
end;

procedure MyAfterInstallEnvironment();
var
  EnvFile, EtcDir: String;
  iLineCounter, iSize : Integer;
  EnvStrList: TArrayOfString;
  Res: Boolean;
begin
  { Make some Windows-only changes to the etc/@PACKAGE@/environment file }
  { If you make any changes here, you should probably also change the equivalent sections }
  { in install.sh }
  { A new line is stared with #13#10 - #10 is the linefeed character and #13 CR }

  { Get the installation-specific paths }
  EnvFile := ExpandConstant(CurrentFileName);
  EtcDir := ExtractFileDir(EnvFile);

  { Load the current contents of the environment file }
  Res := LoadStringsFromFile(EnvFile, EnvStrList);
  if Res = False then
    MsgBox('Error on reading ' + EnvFile + ' for completing the installation', mbInformation, MB_OK);

  iSize := GetArrayLength(EnvStrList);
  for iLineCounter := 0 to iSize-1 do
    begin
      { Adapt GUILE_LOAD_PATH parameter and prevent cygwin interference in SCHEME_LIBRARY_PATH }
      if (Pos('GUILE_LOAD_PATH', EnvStrList[iLineCounter]) = 1) then
      begin
        StringChangeEx(EnvStrList[iLineCounter], '{GUILE_LOAD_PATH}', '{GNC_HOME}/share/guile/2.2;{GUILE_LOAD_PATH}', True);

        EnvStrList[iLineCounter] := EnvStrList[iLineCounter] + #13#10 + '# Clear SCHEME_LIBRARY_PATH to prevent interference from other guile installations (like cygwin)' + #13#10;
        EnvStrList[iLineCounter] := EnvStrList[iLineCounter] + 'SCHEME_LIBRARY_PATH=' + #13#10;
      end;
      { Adapt GNC_DBD_DIR parameter }
      if (Pos('GNC_DBD_DIR', EnvStrList[iLineCounter]) > 0) then
        EnvStrList[iLineCounter] := 'GNC_DBD_DIR={GNC_HOME}/lib/dbd';
      { Adapt XDG_DATA_DIRS parameter }
      if (Pos('XDG_DATA_DIRS=', EnvStrList[iLineCounter]) > 0) then
        EnvStrList[iLineCounter] := 'XDG_DATA_DIRS={GNC_HOME}/share;{XDG_DATA_DIRS};/usr/local/share;/usr/share';
    end;

  { Save the final file }
  Res := ForceDirectories(EtcDir);
  if Res = False then
    MsgBox('Error on creating ' + EtcDir + ' for completing the installation', mbInformation, MB_OK);

  Res := SaveStringsToFile(EnvFile, EnvStrList, False);
  if Res = False then
    MsgBox('Error on saving ' + EnvFile + ' for completing the installation', mbInformation, MB_OK);
end;

// Sometimes a user either doesn't have a CSIDL_PERSONAL setting or
// it's invalid. This function tests is and if that's the case returns
// CSIDL_COMMON_DOCUMENTS. Code lifted from
// http://stackoverflow.com/questions/28635548/avoiding-failed-to-expand-shell-folder-constant-userdocs-errors-in-inno-setup.

function GetDocPath(Param: string): string;
var Folder: string;
begin
  try
    // first try to expand the {userdocs} folder; if this raises that
    // internal exception, you'll fall down to the except block where
    // you expand the {%allusersprofile}
    Folder := ExpandConstant('{userdocs}');
    // the {userdocs} folder expanding succeded, so let's test if the
    // folder exists and if not, expand {%allusersprofile}
    if not DirExists(Folder) then
      Folder := ExpandConstant('{%allusersprofile}');
  except
    Folder := ExpandConstant('{%allusersprofile}');
  end;
  // return the result
  Result := Folder;
end;

[Languages]
Name: "en"; MessagesFile: "compiler:Default.isl"
Name: "ca"; MessagesFile: "compiler:Languages\Catalan.isl"; InfoAfterFile: "@GC_WIN_REPOS_DIR@\inno_setup\README-ca.win32-bin.txt"
Name: "de"; MessagesFile: "compiler:Languages\German.isl"; InfoAfterFile: "@GC_WIN_REPOS_DIR@\inno_setup\README-de.win32-bin.txt"
Name: "el"; MessagesFile: "compiler:Languages\Greek.isl"
Name: "fr"; MessagesFile: "compiler:Languages\French.isl"; InfoAfterFile: "@GC_WIN_REPOS_DIR@\inno_setup\README-fr.win32-bin.txt"
Name: "hr"; MessagesFile: "@GC_WIN_REPOS_DIR@\inno_setup\Croatian-5.5.3.isl"; InfoAfterFile: "@GC_WIN_REPOS_DIR@\inno_setup\README-hr.win32-bin.txt"
Name: "it"; MessagesFile: "compiler:Languages\Italian.isl"; InfoAfterFile: "@GC_WIN_REPOS_DIR@\inno_setup\README-it.win32-bin.txt"
Name: "ja"; MessagesFile: "compiler:Languages\Japanese.isl"
Name: "lv"; MessagesFile: "@GC_WIN_REPOS_DIR@\inno_setup\Latvian-5.5.0.isl"; InfoAfterFile: "@GC_WIN_REPOS_DIR@\inno_setup\README-lv.win32-bin.txt"
Name: "nl"; MessagesFile: "compiler:Languages\Dutch.isl"; InfoAfterFile: "@GC_WIN_REPOS_DIR@\inno_setup\README-nl.win32-bin.txt"
Name: "pt_BR"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"
Name: "zh_CN"; MessagesFile: "@GC_WIN_REPOS_DIR@\inno_setup\ChineseSimplified-5.5.3.isl"; InfoAfterFile: "@GC_WIN_REPOS_DIR@\inno_setup\README-zh_CN.win32-bin.txt"
Name: "zh_TW"; MessagesFile: "@GC_WIN_REPOS_DIR@\inno_setup\ChineseTraditional-5.5.3.isl"; InfoAfterFile: "@GC_WIN_REPOS_DIR@\inno_setup\README-zh_TW.win32-bin.txt"

;; See http://www.jrsoftware.org/files/istrans/ for a complete list of
;; Inno Setup translations. Unofficial translations must be downloaded
;; and added to this repository as is done with Latvian and Chinese above.
;; Unofficial translations should be updated when Inno Setup is.

; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; These are only for improved text messages
; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
[Messages]

[CustomMessages]
; *** "Select Components" wizard page
FullInstall=Full installation
CustomInstall=Custom installation
CreateDesktopIcon=Create a &desktop icon
CreateMenuLink=Create a start menu link
RunPrg=Run GnuCash now
AdditionalIcons=Create these icons:
StatusMsgFirewall=Installing Windows firewall rules...
; *** "Another install" wizard page
; %1 in the following messages will be replaced with the application name and version, like "GnuCash 2.3.15"
AIWP_Title=Another installation has been found
AIWP_Description=%1 is currently installed on this computer
AIWP_Message=This earlier installation has to be removed before continuing.%n%nIf you don't want that, click Cancel now to abort the current installation.%n%nClick Next to remove %1 and continue with the installation.%n%nNote: Only the program will be removed, not your financial data.

MainFiles=GnuCash Program
TranslFiles=Translation Files
TemplFiles=Account Template Files

IconComment_GnuCash=GnuCash Free Finance Manager
IconName_README=Show GnuCash README
IconComment_README=Show the README file
IconFilename_README=README.win32-bin.txt
IconName_FAQ=GnuCash FAQ (Online)
IconName_Bugzilla=Report a GnuCash Bug (Online)
IconName_InstallFQ=Install Online Price Retrieval for GnuCash
IconComment_InstallFQ=Install the necessary perl module Finance-Quote for online retrieval of prices.  Requires ActivePerl or Strawberry Perl 5.8 or later
IconName_Theme=Select GnuCash Theme
IconName_Uninstall=Uninstall GnuCash
IconComment_Uninstall=Uninstall the Finance Manager GnuCash

;; List of Code pages
LanguageCodePage=0
ca.LanguageCodePage=0
de.LanguageCodePage=0
el.LanguageCodePage=0
fr.LanguageCodePage=0
hr.LanguageCodePage=0
it.LanguageCodePage=0
ja.LanguageCodePage=0
nl.LanguageCodePage=0
pt_BR.LanguageCodePage=0
zh_CN.LanguageCodePage=0
zh_TW.LanguageCodePage=0

;; ;;;;;;;;;;;;;;;;;;;;;
;; Catalan translation

ca.FullInstall=Instal·lació completa
ca.CustomInstall=Instal·lació personalitzada
ca.CreateDesktopIcon=Crear una icona a l'escriptori
ca.CreateMenuLink=Crear una drecera al menú d'inici
ca.RunPrg=Executar el GnuCash ara
ca.AdditionalIcons=Crear les següents icones
ca.StatusMsgFirewall=Instal·lació de les regles del tallafocs de Windows

ca.MainFiles=Programa GnuCash
ca.TranslFiles=Traducció catalana
ca.TemplFiles=Model d'estructura de comptes

ca.IconComment_GnuCash=GnuCash, el gestor de finances OpenSource
ca.IconName_README=Mostra el LLEGIU-ME del GnuCash
ca.IconComment_README=Mostra el fitxer LLEGIU-ME
ca.IconFilename_README=README-ca.win32-bin.txt
ca.IconName_FAQ=GnuCash FAQ - Preguntes freqüents (en línia, en anglès)
ca.IconName_Bugzilla=Informar d'un error al GnuCash (en línia, en anglès)
ca.IconName_InstallFQ=Instal·lar les cotitzacions en línia per al GnuCash
ca.IconComment_InstallFQ=Instal·leu el mòdul perl necessari Finance-Quote per a la recuperació de preus en línia. Requereix ActivePerl o Strawberry Perl 5.8 o posterior
ca.IconName_Theme=Selecció del tema GnuCash
ca.IconName_Uninstall=Desinstal·lar GnuCash
ca.IconComment_Uninstall=Desinstal·lar el gestor de finances GnuCash

ca.AIWP_Title=S'ha trobat una altra instal·lació
ca.AIWP_Description=%1 actualment està instal·lat en aquesta computadora
ca.AIWP_Message=Aquesta instal·lació anterior s'ha d'eliminar abans de continuar.%n%nSi no voleu això, feu clic a »Cancel·la« ara per cancel·lar la instal·lació actual.%n%nFeu clic a »Següent« per eliminar %1 i continuar amb la instal·lació.%n%nNota: Només es retirarà el programa, no les vostres dades financeres.


;; ;;;;;;;;;;;;;;;;;;;;
;; German translation

de.FullInstall=Komplett-Installation
de.CustomInstall=Benutzerdefiniert
de.CreateDesktopIcon=Ein Icon auf dem Desktop erstellen
de.CreateMenuLink=Eine Verknüpfung im Startmenü erstellen
de.RunPrg=GnuCash jetzt starten
de.AdditionalIcons=Folgende Icons erstellen:
de.StatusMsgFirewall=Windows Firewall für GnuCash automatisch Anpassen (empfohlen)...

de.MainFiles=GnuCash Hauptprogramm
de.TranslFiles=Deutsche Übersetzung
de.TemplFiles=Beispiel-Kontenrahmen

de.IconComment_GnuCash=GnuCash OpenSource-Finanzverwaltung
de.IconName_README=GnuCash README anzeigen
de.IconComment_README=Die Informationsdatei (README) anzeigen
de.IconFilename_README=README-de.win32-bin.txt
de.IconName_FAQ=GnuCash Häufige Fragen (online, engl.)
de.IconName_Bugzilla=Fehlerbericht einsenden für GnuCash (online, engl.)
de.IconName_InstallFQ=Erweiterung um Wechselkurse mit GnuCash online abzurufen
de.IconComment_InstallFQ=Aktien- und Devisenkurse online abrufen (optionales Modul Finance-Quote: Achtung! Erfordert das Programm ActivePerl oder Strawberry Perl 5.8 oder neuer)
de.IconName_Theme=GnuCash's Erscheinungsbild (GTK-Thema) auswählen
de.IconName_Uninstall=Deinstallieren von GnuCash
de.IconComment_Uninstall=Die OpenSource-Finanzverwaltung GnuCash wieder deinstallieren und vom Computer löschen

de.AIWP_Title=Frühere Version gefunden
de.AIWP_Description=%1 ist momentan auf diesem Computer installiert
de.AIWP_Message=Diese frühere Version muss vor der neuen Installation entfernt werden. %n%nFalls Sie das nicht möchten, klicken Sie jetzt auf »Abbrechen«.%n%nKlicken Sie auf »Fortsetzen«, um %1 zu entfernen und die neue Version zu installieren.%n%nHinweis: Lediglich die Programmversion wird entfernt, aber nicht Ihre finanziellen Daten.


;; ;;;;;;;;;;;;;;;;;;;
;; Greek translation

el.FullInstall=Πλήρης εγκατάσταση
el.CustomInstall=Προσαρμοσμένη εγκατάσταση
el.CreateDesktopIcon=Δημιουργία εικονιδίου στην επιφάνεια εργασίας
el.CreateMenuLink=Προσθήκη στο μενού Έναρξη
el.RunPrg=Εκτέλεση του GnuCash τώρα
el.AdditionalIcons=Δημιουργία εικονιδίων:
el.StatusMsgFirewall=Εγκατάσταση κανόνων για το τοίχος προστασίας των Windows...

el.MainFiles=Πρόγραμμα GnuCash
el.TranslFiles=Αρχεία μετάφρασεων
el.TemplFiles=Αρχεία με πρότυπα λογαριασμών

el.IconComment_GnuCash=GnuCash πρόγραμμα διαχ. οικονομικών
el.IconName_README=GnuCash - Εμφάνιση του README
el.IconComment_README=Εμφάνιση του αρχείου README
el.IconFilename_README=README.win32-bin.txt
el.IconName_FAQ=GnuCash - Συχνές ερωτήσεις (Online)
el.IconName_Bugzilla=GnuCash - Αναφορά σφάλματος (Online)
el.IconName_InstallFQ=GnuCash - Εγκατάσταση λήψης τιμών (online)
el.IconComment_InstallFQ=Εγκατάσταση του perl module Finance-Quote για λήψη τιμών online.  Απαιτεί ActivePerl/Strawberry Perl 5.8+
el.IconName_Uninstall=Απεγκατάσταση GnuCash
el.IconComment_Uninstall=Απεγκατάσταση του διαχειριστή οικονομικών GnuCash


;; ;;;;;;;;;;;;;;;;;;;;
;; French translation

fr.FullInstall=Installation complète
fr.CustomInstall=Installation personnalisée
fr.CreateDesktopIcon=Créer un icône sur le bureau
fr.CreateMenuLink=Créer un lien dans le menu de démarrage
fr.RunPrg=Démarrer GnuCash maintenant
fr.AdditionalIcons=Créer les icônes suivants:
fr.StatusMsgFirewall=Installation des règles de pare-feu de Windows

fr.MainFiles=Programme GnuCash
fr.TranslFiles=Traduction française
fr.TemplFiles=Modèle de plan comptable

fr.IconComment_GnuCash=GnuCash, le gestionnaire financier OpenSource
fr.IconName_README=Afficher le GnuCash LISEZMOI
fr.IconComment_README=Afficher le fichier LISEZMOI
fr.IconFilename_README=README-fr.win32-bin.txt
fr.IconName_FAQ=GnuCash FAQ (En ligne, en anglais)
fr.IconName_Bugzilla=Envoyer un rapport d'erreur pour GnuCash (En ligne, en anglais)
fr.IconName_InstallFQ=Installer les quotations en ligne pour GnuCash
fr.IconComment_InstallFQ=Installation du module Finance-Quote requis pour le téléchargement du cours des devises et actions. Le programme ActivePerl 5.8 ou plus récent est aussi requis
fr.IconName_Theme=Selection du style GnuCash
fr.IconName_Uninstall=Dé-installer GnuCash
fr.IconComment_Uninstall=Désinstalle le gestionnaire financier GnuCash


;; ;;;;;;;;;;;;;;;;;;;;
;; Croatian translation

; *** "Select Components" wizard page
hr.FullInstall=Kompletna instalacija
hr.CustomInstall=Prilagođena instalacija
hr.CreateDesktopIcon=Stvori ikonu na radnoj površini
hr.CreateMenuLink=Stvori poveznicu u izborniku Start
hr.RunPrg=Pokreni GnuCash
hr.AdditionalIcons=Stvori ove ikone:
hr.StatusMsgFirewall=Instaliranje pravila vatrozida Windowsa …
; *** "Another install" wizard page
; %1 in the following messages will be replaced with the application name and version, like "GnuCash 2.3.15"
hr.AIWP_Title=Nađena je jedna druga instalacija
hr.AIWP_Description=%1 je trenutačno instaliran na ovom računalu
hr.AIWP_Message=Ovu raniju instalaciju moraš ukloniti prije nego što nastaviš s instaliranjem.%n%nAko to ne želiš, klikni "Odustani" i prekinut ćeš ovo instaliranje.%n%nKlikni "Dalje" ako želiš ukloniti %1 i nastaviti s instaliranjem.%n%nNapomena: Uklonit će se samo program, ne i tvoji financijski podaci.

hr.MainFiles=GnuCash program
hr.TranslFiles=Hrvatski prijevod
hr.TemplFiles=Predlošci kontnih planova

hr.IconComment_GnuCash=GnuCash – slobodan računovodstveni program
hr.IconName_README=Prikaži GnuCash README
hr.IconComment_README=Prikaži informativnu README-datoteku
hr.IconFilename_README=README-hr.win32-bin.txt
hr.IconName_FAQ=Često postavljana pitanja o GnuCashu (web stranica na engleskom)
hr.IconName_Bugzilla=Prijavi grešku (web stranica na engleskom)
hr.IconName_InstallFQ=Instaliraj dohvaćanje internetskih tečajeva za GnuCash
hr.IconComment_InstallFQ=Instaliraj potreban perl modul Finance-Quote za dohvaćanje tečajeva putem interneta. Zahtijeva ActivePerl ili Strawberry Perl 5.8 ili noviji
hr.IconName_Theme=Odaberi GnuCashovu temu
hr.IconName_Uninstall=Deinstaliraj GnuCash
hr.IconComment_Uninstall=Deinstaliraj računovodstveni program GnuCash


;; ;;;;;;;;;;;;;;;;;;;;;
;; Italian translation

; *** Pagina di "Selezione dei componenti"
it.FullInstall=Installazione completa
it.CustomInstall=Installazione personalizzata
it.CreateDesktopIcon=Crea un'icona sul desktop
it.CreateMenuLink=Crea un collegamento nel menu "Start"
it.RunPrg=Avvia GnuCash
it.AdditionalIcons=Crea queste icone:
it.StatusMsgFirewall=Installazione delle regole per il firewall di Windows...
; *** Pagina di "Altra installazione"
; nel messaggio seguente la stringa %1 sarà sostituita dal nome e dalla versione dell'applicazione, ad esempio "GnuCash 2.3.15"
it.AIWP_Title=È stata trovata un'altra installazione
it.AIWP_Description=%1 è installato in questo computer
it.AIWP_Message=Questa precedente installazione deve essere rimossa prima di continuare.%n%nSe non si intende rimuoverla, fare clic su «Annulla» per terminare l'installazione.%n%nFare invece clic su «Avanti» per rimuovere %1 e continuare con l'installazione.%n%nNota: verrà rimosso solo il programma, non i propri dati finanziari.

it.MainFiles=File del programma GnuCash
it.TranslFiles=Traduzione Italiana
it.TemplFiles=Modelli di strutture dei conti

it.IconComment_GnuCash=GnuCash: gestore di finanze libero
it.IconName_README=Mostra il file GnuCash LEGGIMI
it.IconComment_README=Mostra il file LEGGIMI
it.IconFilename_README=README-it.win32-bin.txt
it.IconName_FAQ=GnuCash FAQ (online, in Inglese)
it.IconName_Bugzilla=Segnalare un bug en GnuCash (online, in Inglese)
it.IconName_InstallFQ=Installa la funzione di ricerca delle quotazioni online per GnuCash
it.IconComment_InstallFQ=Installa il modulo di perl Finance-Quote necessario per ricevere le quotazioni online. Richiede ActivePerl 5.8+
it.IconName_Theme=Selezione del tema GnuCash
it.IconName_Uninstall=Disinstalla GnuCash
it.IconComment_Uninstall=Disinstalla il programma di gestione delle finanze GnuCash


;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Japanese translation

ja.FullInstall=完全インストール
ja.CustomInstall=カスタムインストール
ja.CreateDesktopIcon=デスクトップにアイコンを作成(&D)
ja.CreateMenuLink=スタートメニューにリンクを作成
ja.RunPrg=GnuCashをすぐに実行
ja.AdditionalIcons=作成されたアイコン:
ja.StatusMsgFirewall=ファイアウォール定義をインストール中
; *** "Another install" wizard page
; %1 in the following messages will be replaced with the application name and version, like "GnuCash 2.3.15"
ja.AIWP_Title=他のバージョンがインストールされています
ja.AIWP_Description=このコンピュータには %1 が現在インストールされています
ja.AIWP_Message=インストールを継続する前に前のバージョンはアンインストールされます。%n%nもしこの動作を望まないなら「キャンセル」をクリックしてインストールを中止してください。%n%n%1 を削除してインストールを継続する場合は「次へ」をクリックしてください。%n%n備考: 作成した財務データは削除されません。プログラムのみが削除されます。

ja.MainFiles=GnuCashプログラム
ja.TranslFiles=翻訳ファイル
ja.TemplFiles=勘定科目テンプレートファイル

ja.IconComment_GnuCash=GnuCash フリーの財務ソフトウェア
ja.IconName_README=GnuCash - READMEを表示
ja.IconComment_README=READMEファイルを表示します
ja.IconFilename_README=README.win32-bin.txt
ja.IconName_FAQ=GnuCash - FAQ (オンライン)
ja.IconName_Bugzilla=GnuCash - バグを報告 (オンライン)
ja.IconName_InstallFQ=GnuCash - オンライン相場表取得ツールをインストール
ja.IconComment_InstallFQ=オンライン相場表を取得するためにFinance-Quote perl モジュールをインストールします。ActivePerl5.8または5.10が必要です
ja.IconName_Theme=GnuCash テーマの選択
ja.IconName_Uninstall=GnuCashをアンインストール
ja.IconComment_Uninstall=財務ソフトウェアGnuCashをアンインストールします


;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Latvian translation

; *** "Select Components" wizard page
lv.FullInstall=Pilna uzstādīšana
lv.CustomInstall=Izvēles uzstādīšana
lv.CreateDesktopIcon=Izveidot &darbvirsmas ikonu
lv.CreateMenuLink=Izveidot starta izvēlnes saiti
lv.RunPrg=Palaist GnuCash tagad
lv.AdditionalIcons=Izveidot sekojošas ikonas:
lv.StatusMsgFirewall=Uzstāda Windows ugunssienas likumus...

; *** "Another install" wizard page
; %1 in the following messages will be replaced with the application name and version, like "GnuCash 2.3.15"
lv.AIWP_Title=Ir atrasta cita programmas versija
lv.AIWP_Description=Uz šī datora jau ir uzstādīt %1 versija
lv.AIWP_Message=Pirms turpināt, ir nepieciešams noņemt iepriekš uzstādīto versiju.%n%nJa nevēlaties to darīt, spiediet Atcelt pogu, un šī uzstādīšana tiks atcelta.%n%nSpiediet Turpināt, lai noņemtu %1 un turpinātu jaunās versijas uzstādīšanu.%n%nNote: Tiks noņemta tikai iepriekšējās programmas versija. Jūsu finanšu dati aiztikti netiks.

lv.MainFiles=GnuCash Programma
lv.TranslFiles=Tulkojumu faili
lv.TemplFiles=Kontu sagatavju faili

lv.IconComment_GnuCash=GnuCash grāmatvedības programma
lv.IconName_README=GnuCash - Parādīt README
lv.IconComment_README=Parāda README failu
lv.IconFilename_README=README-lv.win32-bin.txt
lv.IconName_FAQ=GnuCash - BUJ (tiešsaistē)
lv.IconName_Bugzilla=GnuCash - Ziņot par kļūdu (tiešsaistē)
lv.IconName_InstallFQ=GnuCash - Uzstādīt tiešsaistes kursu iegūšanu
lv.IconComment_InstallFQ=Uzstādīt nepieciešamos Perl moduļus valūtas kursu iegūšanai. Nepieciešams ActivePerl 5.8+
lv.IconName_Theme=Izvēlieties tēmu GnuCash
lv.IconName_Uninstall=Noņemt GnuCash
lv.IconComment_Uninstall=Noņemt GnuCash grāmatvedības programmu


;; ;;;;;;;;;;;;;;;;;
;; Dutch translation

nl.FullInstall=Volledige installatie
nl.CustomInstall=Aangepaste installatie
nl.CreateDesktopIcon=Een icoon op het Bureaublad plaatsen
nl.CreateMenuLink=Een koppeling in menu Start plaatsen
nl.RunPrg=GnuCash nu starten
nl.AdditionalIcons=Deze iconen aanmaken:
nl.StatusMsgFirewall=Windows Firewall-regels installeren...

nl.MainFiles=Programmabestanden voor GnuCash
nl.TranslFiles=Vertalingsbestanden
nl.TemplFiles=Grootboekrekeningssjablonen

nl.IconComment_GnuCash=GnuCash vrije boekhoudsoftware
nl.IconName_README=GnuCash LEESMIJ tonen
nl.IconComment_README=Het LEESMIJ-bestand weergeven
nl.IconFilename_README=README-nl.win32-bin.txt
nl.IconName_FAQ=GnuCash FAQ (online)
nl.IconName_Bugzilla=Een bug melden in GnuCash (online)
nl.IconName_InstallFQ=Online koersinformatie installeren voor GnuCash
nl.IconComment_InstallFQ=De Perl-module Finance-Quote installeren om online koersen op te vragen. Hiervoor is ActivePerl or Strawberry Perl 5.8 of recenter nodig.
nl.IconName_Theme=Thema voor GnuCash selecteren
nl.IconName_Uninstall=GnuCash verwijderen
nl.IconComment_Uninstall=De vrije boekhoudsoftware GnuCash verwijderen
nl.AIWP_Title=Een eerdere installatie werd gevonden
nl.AIWP_Description=%1 is momenteel op deze computer geïnstalleerd
nl.AIWP_Message=Deze eerdere installatie moet verwijderd worden alvorens verder te gaan.%n%nAls u dat niet wil, klik dan nu op Annuleren om de huidige installatie af te breken.%n%nKlik op Volgende om %1 te verwijderen en de installatie te vervolgen.%n%nOpmerking: alleen het programma zal verwijderd worden, niet je financiële gegevens.


;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Brazilian Portuguese translation

pt_BR.FullInstall=Instalação Completa
pt_BR.CustomInstall=Instalação Personalizada
pt_BR.CreateDesktopIcon=Criar um ícone na Área de Trabalho
pt_BR.CreateMenuLink=Criar um link no menu Iniciar
pt_BR.RunPrg=Executar o GnuCash agora
pt_BR.AdditionalIcons=Criar estes ícones:
pt_BR.StatusMsgFirewall=Instalando as regras de firewall do Windows...

pt_BR.MainFiles=Programa GnuCash
pt_BR.TranslFiles=Tradução
pt_BR.TemplFiles=Modelos de Conta

pt_BR.IconComment_GnuCash=Gerenciador Financeiro Livre GnuCash
pt_BR.IconName_README=GnuCash - Mostrar LEIA-ME (README)
pt_BR.IconComment_README=Mostra o arquivo LEIA-ME (README)
pt_BR.IconFilename_README=LEIA-ME.win32-bin.txt
pt_BR.IconName_FAQ=GnuCash - Perguntas Freqüentes (online, inglês)
pt_BR.IconName_Bugzilla=GnuCash - Relatar um erro (online, inglês)
pt_BR.IconName_InstallFQ=GnuCash - Instalar a Consulta de Preços Online
pt_BR.IconComment_InstallFQ=Instala o módulo perl Finance-Quote, necessário para a busca de preços online. Requer ActivePerl 5.8+.
pt_BR.IconName_Uninstall=Desinstalar o GnuCash
pt_BR.IconComment_Uninstall=Desinstala o Gerenciador Financeiro GnuCash


;; ;;;;;;;;;;;;;;;;;
;; Simplified Chinese translation

zh_CN.FullInstall=完全安装
zh_CN.CustomInstall=自定义安装
zh_CN.CreateDesktopIcon=创建桌面图标
zh_CN.CreateMenuLink=创建开始菜单链接
zh_CN.RunPrg=现在开始运行 GnuCash
zh_CN.AdditionalIcons=创建这些图标
zh_CN.StatusMsgFirewall=正在安装 Windows 防火墙规则...

zh_CN.MainFiles=GnuCash 程序
zh_CN.TranslFiles=翻译文件
zh_CN.TemplFiles=会计科目模板文件

zh_CN.IconComment_GnuCash=GnuCash 免费财务管理
zh_CN.IconName_README=GnuCash - 显示自述文件
zh_CN.IconComment_README=显示自述文件
zh_CN.IconFilename_README=README-zh_CN.win32-bin.txt
zh_CN.IconName_FAQ=GnuCash - 常见问题 (在线)
zh_CN.IconName_Bugzilla=GnuCash - 报告软件 Bug (在线)
zh_CN.IconName_InstallFQ=GnuCash - 安装在线价格检索功能
zh_CN.IconComment_InstallFQ=安装在线价格检索所必需的 Perl Finance-Quote模块。需要 ActivePerl 5.8 或 5.10
zh_CN.IconName_Uninstall=卸载 GnuCash
zh_CN.IconComment_Uninstall=卸载财务管理软件 GnuCash

;; ;;;;;;;;;;;;;;;;;
;; Traditional Chinese translation

; *** "Select Components" wizard page
zh_TW.FullInstall=完整安裝
zh_TW.CustomInstall=自訂安裝
zh_TW.CreateDesktopIcon=產生桌面圖示
zh_TW.CreateMenuLink=產生開始功能表圖示
zh_TW.RunPrg=現在開始執行 GnuCash
zh_TW.AdditionalIcons=建立這些圖示:
zh_TW.StatusMsgFirewall=正在安裝 Windows 防火牆規則...
; *** "Another install" wizard page
; %1 in the following messages will be replaced with the application name and version, like "GnuCash 2.3.15"
zh_TW.AIWP_Title=發現已安裝過
zh_TW.AIWP_Description=%1 已經安裝於系統中
zh_TW.AIWP_Message=舊版必須先移除才能繼續。%n%n若您不想移除，現在就點選「取消」中斷安裝。%n%n點選「下一步」會移除 %1 並繼續安裝。%n%n注意: 只有程式會被移除，不會影響到您的財務資料存檔。

zh_TW.MainFiles=GnuCash 程式
zh_TW.TranslFiles=翻譯檔
zh_TW.TemplFiles=會計科目範本檔

zh_TW.IconComment_GnuCash=GnuCash 自由財務管理
zh_TW.IconName_README=GnuCash - 顯示 README
zh_TW.IconComment_README=顯示 README 檔
zh_TW.IconFilename_README=README-zh_TW.win32-bin.txt
zh_TW.IconName_FAQ=GnuCash - 常見問題 (線上)
zh_TW.IconName_Bugzilla=GnuCash - 回報程式 Bug (線上)
zh_TW.IconName_InstallFQ=GnuCash - 安裝網路報價截取功能
zh_TW.IconComment_InstallFQ=安裝截取網路報價所需的 Perl Finance-Quote 模組。需要 ActivePerl 5.8 或 5.10
zh_TW.IconName_Theme=選擇介面風格 GnuCash
zh_TW.IconName_Uninstall=反安裝 GnuCash
zh_TW.IconComment_Uninstall=反安裝財務管理員 GnuCash
