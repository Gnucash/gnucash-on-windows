@echo off
setlocal

REM ----------------------------------------------------------------------------
echo.
echo * Check Perl
echo.
perl -v > NUL 2>&1 
if %errorlevel% equ 0 goto chkver
echo. 
echo   No Perl executable found, attempt to install Strawberry Perl
echo   This may take a while depending on your network speed

REM ----------------------------------------------------------------------------
echo.
echo * Download Strawberry Perl package
echo.
call cscript//nologo getperl.vbs %TEMP%\Perl.msi
if %errorlevel% neq 0 (
   echo   Return Value: "%errorlevel%"
   echo.
   echo   failed to download perl install file
   echo.
   goto error
)

REM ----------------------------------------------------------------------------
echo.
echo * Run automated Perl install
echo.
msiexec /qb /l* %TEMP%\perl-log.txt /i %TEMP%\Perl.msi PERL_PATH=Yes PERL_EXT=Yes
if %errorlevel% neq 0 (
   echo   Return Value: "%errorlevel%"
   echo.
   echo   failed to install perl from %TEMP%\Perl.msi
   echo.
   del  %TEMP%\Perl.msi
   goto error
)
%SystemDrive%\strawberry\perl\bin\perl -v
del  %TEMP%\Perl.msi

REM ----------------------------------------------------------------------------
echo.
echo * Update PATH variable to include Perl
echo.
:: delims is a TAB followed by a space
FOR /F "tokens=2* delims=	 " %%A IN ('REG QUERY "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path') DO SET NewPath=%%B
ECHO NewPath = %NewPath%
set Path=%NewPath%

REM ----------------------------------------------------------------------------
:chkver
echo.
echo * Check Perl version
echo.
perl -e "exit(int($]));"
set _perlmajor=%errorlevel%
perl -e "$ver=1000*sprintf(\"%%.3f\", $]); exit(int($ver)-5000);"
set _perlminor=%errorlevel%
if %_perlmajor% equ 5 (
  if %_perlminor% geq 10 (
    set _perlversion=5.10
    goto install
  )
  if %_perlminor% equ 8 (
    set _perlversion=5.8
    goto install
  )
REM Note: GnuCash no longer "officially" supports perl 5.6, but as long as it works it will be allowed...
  if %_perlminor% equ 6 (
    set _perlversion=5.6
    goto install
  )
)
echo.
echo Found perl version %_perlmajor%.%_perlminor%, but GnuCash requires at least version 5.8.
echo Please install version 5.8 or above of
echo * ActivePerl (http://www.activestate.com/store/activeperl) or
echo * Strawberry Perl (http://code.google.com/p/strawberry-perl/downloads/)
echo and add the bin directory to your Path environment variable.
goto error

REM ----------------------------------------------------------------------------
:pchk
REM echo.
REM echo * Run gnc-path-check
REM echo.
REM perl -w gnc-path-check
REM if %errorlevel% neq 0 goto error

REM ----------------------------------------------------------------------------
:install
echo.
echo * Install required perl modules
echo.
perl -w gnc-fq-update
if %errorlevel% neq 0 goto error

REM ----------------------------------------------------------------------------
echo.
echo * Check environment variable ALPHAVANTAGE_API_KEY
echo.

echo.  ***
echo.  *** You need an API key (from https://www.alphavantage.co)
echo.  ***   to run the Perl module Finance::Quote.
echo.  ***
echo.  *** Make it available to GnuCash by
if not [%ALPHAVANTAGE_API_KEY%] == [] set "done=(done) "
echo.  ***    - setting the environment variable ALPHAVANTAGE_API_KEY %done%or
echo.  ***    - starting GnuCash and adding the Alpha Vantage api key in
echo.  ***        Edit-^>Preferences-^>Online Quotes
echo.  ***

REM ----------------------------------------------------------------------------
echo.
echo * Run gnc-fq-check
echo.
perl -w gnc-fq-check
if %errorlevel% neq 0 goto error

REM ----------------------------------------------------------------------------
echo.
echo * Run gnc-fq-helper
echo.
echo (alphavantage "AMZN") | perl -w gnc-fq-helper
if %errorlevel% neq 0 goto error

REM ----------------------------------------------------------------------------
:success
echo.
echo * Installation succeeded
echo.
goto end

REM ----------------------------------------------------------------------------
:error:
echo.
echo An error occurred, see above.
echo.

REM ----------------------------------------------------------------------------
:end
endlocal
pause

