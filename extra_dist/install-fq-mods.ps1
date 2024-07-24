# Powershell script to setup perl and Finance::Quote

# Ensure script stops on first error
$ErrorActionPreference = "Stop"

# Strawberry Perl Version to download.  Strawberry Perl is downloaded from
#  github.com and they can be inconsistent in their naming conventions.
#  Examine the URL for download prior to changing one or both version vars.
$strVersion = "5.38.2.1"     
$strVersionNoDot = "5382"

# Locations to store temp install file and log file
$strHDLocation = "$env:TEMP\Perl.msi"
$strLogLogation = "$env:TEMP\perl-log.txt"

# Minimum perl version required
# Support is currently at 5.8.x, but 5.6 will also work.
$perlVersion = 8

# Function to install and verify perl.
function install_perl {
    Write-Host "`n  No Perl executable found in current PATH."
    Write-Host "  Attempting to download and install Strawberry Perl"
    Write-Host "  This may take a while depending on your network speed.`n"
    $strFileURL = "https://github.com/StrawberryPerl/Perl-Dist-Strawberry/releases/download/SP`_$strVersionNoDot`_32bit/strawberry-perl-$strVersion-32bit.msi"
    $webClient = New-Object System.Net.WebClient
    try {
        $webClient.DownloadFile($strFileURL, $strHDLocation)
        Write-Host "`n >> Perl v $strVersion was downloaded OK <<`n"
    }
    catch {
        Write-Host "`nFailed to download Perl Install File. Unable to Continue`n"
        Pause
    }
    Write-Host "`n * Running automated Perl install`n"
    # Install Perl
    try {
        Start-Process msiexec.exe -ArgumentList " /i ""$strHDLocation"" /qb /L*V ""$strLogLogation"" PERL_PATH=Yes PERL_EXT=Yes" -Wait    
    }
    catch {
        Write-Host "`n  Failed to install perl from $env:TEMP\Perl.msi`n"
        Remove-Item "$env:TEMP\Perl.msi"
    }
    
    Remove-Item "$env:TEMP\Perl.msi"
    
    Write-Host "`n >> Perl Install completed <<`n"

    # Strawberry Perl will set the system/machine PATH during install
    # We need to set the local process PATH variable to finish install of FQ.
    $env:Path = [System.Environment]::GetEnvironmentVariable('PATH', "Machine")
}

# Check Perl Version
function chkPerlVer {
    
    Write-Host "`n * Checking Perl version`n"
   
    perl -e "exit(int($]));"
    $perlMajor = $LastExitCode
    perl -e "`$ver=1000*sprintf('%0.3f', $]); exit(int(`$ver)-5000);"
    $perlMinor = $LastExitCode


    if ($perlminor -lt $perlVersion) {
        Write-Host "`n Found perl version $perlMajor.$perlMinor, but GnuCash requires at least version 5.$perlVersion."
        Write-Host "Please manually install version 5.$perlVersion or above from"
        Write-Host "* ActivePerl (http://www.activestate.com/store/activeperl) or"
        Write-Host "* Strawberry Perl (http://code.google.com/p/strawberry-perl/downloads/)"
        Write-Host "and add the bin directory to your Path environment variable. `n"
        Pause
        Throw
    }

}

# Function to install the Finance::Quote Module
function install_fq_mod {
    Write-Host "`n * Installing required perl modules`n"
    
    try {
        perl -w gnc-fq-update  
    }
    catch {
        "Perl appears to be installed, but cannot install Finance::Quote module"
        Pause
    } 
    
}

#----------------------------------------------------
# Start of main script.
#----------------------------------------------------

# Run test to see if _any_ Perl is already installed
Write-Host "`n * Checking for any installed Perl `n"

try {
    perl -v > $null 2>&1  
}
catch {
    install_perl
} 

chkPerlVer

install_fq_mod

Write-Host "`n >> Installation succeeded << `n"
Pause
Exit
