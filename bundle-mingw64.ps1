# bundle-mingw64.ps1: Powershell Script to create gnucash-setup.exe on MinGW64.
# Copyright 2017 John Ralls <jralls@ceridwen.us>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact:
# Free Software Foundation           Voice:  +1-617-542-5942
# 51 Franklin Street, Fifth Floor    Fax:    +1-617-542-2652
# Boston, MA  02110-1301,  USA       gnu@gnu.org

<#
.SYNOPSIS

Runs Inno-Setup to create a gnucash installer program.

.DESCRIPTION

Creates a gnucash installer program from a MSYS2 environment in which GnuCash, the GnuCash documentation, and all dependencies have been installed.

This script must not be moved from the gnucash-on-windows.git working directory.

You may need to allow running scripts on your computer and depending
on where the mingw_prefix is you may need to run the script with
Administrator privileges

PARAMETER mingw_prefix

Mandatory. The absolute path to the root MSYS2 directory, e.g. C:\gcdev64\msys2

.PARAMETER mingw_arch

Mandatory. The MSYS2 archicture to package. Allowed values are mingw32, mingw64, clang64, and ucrt64.

#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)] [string]$mingw_prefix,
    [Parameter(Mandatory=$true)] [string]$mingw_arch
)

$script_dir = Split-Path $script:MyInvocation.MyCommand.Path

$progressPreference = 'silentlyContinue'

try {
    $signature =
    ' [DllImport("kernel32.dll")]
      public static extern bool GetBinaryType(string lpApplicationName,
					      ref int lpBinaryType);'
    add-type -MemberDefinition $signature -Name BinaryType -Namespace Win32Utils
}
catch {} #type already loaded, ignore problem.

function bash-command() {
    param ([string]$command = "")
    if (!(test-path -path $mingw_prefix\usr\bin\bash.exe)) {
	write-host "Shell program not found, aborting."
	exit
    }
    #write-host "Running bash command ""$command"""
    Start-Process -FilePath "$mingw_prefix\usr\bin\bash.exe" -ArgumentList "-c ""export PATH=/usr/bin:/$mingw_arch/bin; $command""" -NoNewWindow -Wait
}

function make-unixpath([string]$path) {
    $path -replace  "^([A-Z]):", '/$1' -replace "\\", '/'
}

if ($PSVersionTable.PSVersion.Major -ge 3) {
    $PSDefaultParameterValues['*:Encoding'] = 'utf8'
    }

$git_build = $false
$vline = & $mingw_prefix\$mingw_arch\bin\gnucash-cli.exe --version | Select-String "Build ID:" | %{$_ -split "\s+"}
if ($vline[2] -eq "git") {
    $package_version = $vline[3].split('+')[0]
    $git_build = $true
}
else {
    $package_version = $vline[2].split('+')[0]
}

$major_version = $package_version.split('.')[0]
$minor_version = $package_version.split('.')[1].split('-')[0]

$architecture = "x64"
if ($mingw_arch -eq "mingw32") {
    $architecture = "x86"
}
# We must use sed under bash in order to preserve the UTF-8 encoding
# with Unix line endings; PowerShell wants to re-code the output as
# UTF-16 and Inno Setup finds that indigestible. The ridiculous number
# of backslashes is due to bash and sed eating them. It results in a
# single backslash in the output file. Inno Setup doesn't understand
# forward slashes as path delimiters.
$root = %{$mingw_prefix -replace "\\", "\\\\\\\\"}
$script = %{$script_dir -replace "\\", "\\\\\\\\"}
$issue_in = make-unixpath -path  $script_dir\inno_setup\gnucash-mingw64.iss
$issue_out = make-unixpath -path $script_dir\gnucash.iss

$proc = bash-command("sed  < $issue_in > $issue_out \
  -e ""s#@ARCHITECTURE@#$architecture#"" \
  -e ""s#@MINGW_DIR@#$root\\\\\\\\$mingw_arch#g"" \
  -e ""s#@PACKAGE_VERSION@#$package_version#g"" \
  -e ""s#@PACKAGE@#gnucash#g"" \
  -e ""s#@GNUCASH_MAJOR_VERSION@#$major_version#g"" \
  -e ""s#@GNUCASH_MINOR_VERSION@#$minor_version#g"" \
  -e ""s#@GC_WIN_REPOS_DIR@#$script#g"" ")

$date = get-date -format "yyyy-MM-dd"
$setup_result =  "$script_dir\gnucash-$package_version.setup.exe"
$final_file = ""
if ($git_build) {
  $final_file = "$script_dir\gnucash-$major_version.$minor_version-$mingw_arch-$date-git-$package_version.setup.exe"
  }
else {
  $final_file = "$script_dir\gnucash-$package_version-$mingw_arch.setup.exe"
}

$mingw_dir = "$mingw_prefix\$mingw_arch"
$schema_dir = "share\glib-2.0\schemas"
$mingw_schema_dir = "$mingw_dir\$schema_dir"
$mingw_schema_unix = make-unixpath -path $mingw_schema_dir
$schema_compiler = make-unixpath -path "$mingw_dir\bin\glib-compile-schemas"
bash-command("$schema_compiler $mingw_schema_unix")


# Inno-setup isn't able to easily pick out particular message catalogs from $mingw_dir/share/locale, so copy the ones we want to $inst_dir\share\locale.

$source_locale_dir = "$mingw_dir\share\locale\"
$inst_locale_dir = "$script_dir\locale"
foreach ($msgcat in "gtk30.mo", "gtk30-properties.mo", "iso_4217.mo", "gnucash.mo", "aqbanking.mo", "gwenhywfar.mo", "WebKitGTK-3.0.mo") {
    foreach ($dir in get-childitem -Directory $source_locale_dir) {
        $dir = split-path -leafbase $dir
	$source_path = "$source_locale_dir\$dir\LC_MESSAGES"
	$inst_path = "$inst_locale_dir\$dir\LC_MESSAGES"
	if ((test-path $source_path) -and (test-path "$source_path\$msgcat")) {
            if (!(test-path $inst_path)) {
                new-item -ItemType Directory -Force $inst_path
            }
	    copy-item "$source_path\$msgcat" -Destination $inst_path -recurse
	}
    }
}

write-host "Running Inno Setup to create $final_file."

if (test-path -path $setup_result) {
    remove-item -path $setup_result
}

& ${env:ProgramFiles(x86)}\inno\iscc /Q $script_dir\gnucash.iss

if (test-path -path $inst_locale_dir) {
    remove-item -path $inst_locale_dir -Recurse -Force
}

if ($git_build) {
  if ((test-path -path $setup_result) -and (test-path -path $final_file)) {
    remove-item $final_file
  }
  rename-item -path $setup_result $final_file
}
return $final_file
