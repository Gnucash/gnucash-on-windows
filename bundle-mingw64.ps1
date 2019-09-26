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

Creates a gnucash installer program from a GnuCash build environment created with setup-mingw64.ps1 in which GnuCash has been built with jhbuild using the jhbuildrc and gnucash.modules from gnucash-on-windows.git.

This script must not be moved from the gnucash-on-windows.git working directory.

You may need to allow running scripts on your computer and depending
on where the target_dir is you may need to run the script with
Administrator privileges.

.PARAMETER root_dir

Mandatory. The root path to the build environment. Typically C:\gcdev64.

.PARAMETER target_dir

Mandatory. The base path to where the build to be packaged is located. This is typically $root_dir\gnucash\$branch, for example C:\gcdev64\gnucash\maint

.PARAMETER package

Mandatory. The name of the package to bundle. This is currently only used by the Inno installer builder for things like the registry group to add values to.

.PARAMETER package

Mandatory. Boolean to indicate whether or not this is a git build.

#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)] [string]$root_dir,
    [Parameter(Mandatory=$true)] [string]$target_dir,
    [Parameter(Mandatory=$true)] [string]$package,
    [Parameter(Mandatory=$true)] [bool]$git_build
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

function bitness([string]$path) {
  $type = -1
  $result = [Win32Utils.BinaryType]::GetBinaryType($path, [ref]$type)
  if ($type -eq 6) { 64 } else { 32 }
}

function version_item([string]$tag, [string]$path) {
   $splits = select-string -pattern $tag -path $path | %{$_ -split "\s+"}
   $splits[2]
}

function bash-command() {
    param ([string]$command = "")
    if (!(test-path -path $root_dir\msys2\usr\bin\bash.exe)) {
	write-host "Shell program not found, aborting."
	exit
    }
    #write-host "Running bash command ""$command"""
    Start-Process -FilePath "$root_dir\msys2\usr\bin\bash.exe" -ArgumentList "-c ""export PATH=/usr/bin; $command""" -NoNewWindow -Wait
}

function make-unixpath([string]$path) {
    $path -replace  "^([A-Z]):", '/$1' -replace "\\", '/'
}

if ($git_build) {
  $gnucash = "gnucash-git"
}
else {
  $gnucash = get-childitem -path $target_dir\build | where-object {$_.Name -match "gnucash-[0-9.]+"} | select-object -last 1
}

if ($PSVersionTable.PSVersion.Major -ge 3) {
    $PSDefaultParameterValues['*:Encoding'] = 'utf8'
    }

$gnc_config_h = "$target_dir\build\$gnucash\common\config.h"

$major_version = version_item -tag "GNUCASH_MAJOR_VERSION" -path $gnc_config_h
$minor_version = version_item -tag "GNUCASH_MINOR_VERSION" -path $gnc_config_h
$package_version = "$major_version.$minor_version"
$inst_dir = "$target_dir\inst"
$mingw_ver = bitness("$inst_dir\bin\gnucash.exe")
$aqb_dir = version_item -tag "SO_EFFECTIVE "-path "$inst_dir\include\aqbanking6\aqbanking\version.h"
$gwen_dir = version_item -tag "SO_EFFECTIVE " -path "$inst_dir\include\gwenhywfar5\gwenhywfar\version.h"

# We must use sed under bash in order to preserve the UTF-8 encoding
# with Unix line endings; PowerShell wants to re-code the output as
# UTF-16 and Inno Setup finds that indigestible. The ridiculous number
# of backslashes is due to bash and sed eating them. It results in a
# single backslash in the output file. Inno Setup doesn't understand
# forward slashes as path delimiters.
$root = %{$root_dir -replace "\\", "\\\\\\\\"}
$target = %{$target_dir -replace "\\", "\\\\\\\\"}
$script = %{$script_dir -replace "\\", "\\\\\\\\"}
$issue_in = make-unixpath -path  $script_dir\inno_setup\gnucash-mingw64.iss
$issue_out = make-unixpath -path $target_dir\gnucash.iss
$proc = bash-command("sed  < $issue_in > $issue_out \
  -e ""s#@MINGW_DIR@#$root\\\\\\\\msys2\\\\\\\\mingw$mingw_ver#g"" \
  -e ""s#@INST_DIR@#$target\\\\\\\\inst#g"" \
  -e ""s#@-gwenhywfar_so_effective-@#$gwen_dir#g"" \
  -e ""s#@-aqbanking_so_effective-@#$aqb_dir#g"" \
  -e ""s#@PACKAGE_VERSION@#$package_version#g"" \
  -e ""s#@PACKAGE@#$package#g"" \
  -e ""s#@GNUCASH_MAJOR_VERSION@#$major_version#g"" \
  -e ""s#@GNUCASH_MINOR_VERSION@#$minor_version#g"" \
  -e ""s#@GC_WIN_REPOS_DIR@#$script#g"" ")

$date = get-date -format "yyyy-MM-dd"
$setup_result =  "$target_dir\gnucash-$package_version.setup.exe"
$final_file = ""
if ($git_build) {
  $gnc_vcsinfo_h = "$target_dir\build\gnucash-git\libgnucash\core-utils\gnc-vcs-info.h"
  $vcs_rev = version_item -tag "GNC_VCS_REV" -path $gnc_vcsinfo_h | %{$_ -replace """", ""}
  $final_file = "$target_dir\gnucash-$package_version-$date-git-$vcs_rev.setup.exe"
  }
else {
  $final_file = "$target_dir\gnucash-$package_version.setup.exe"
}

$mingw_dir = "$root_dir\msys2\mingw$mingw_ver"
$schema_dir = "share\glib-2.0\schemas"
$target_schema_dir = "$target_dir\inst\$schema_dir"
copy-item $mingw_dir\$schema_dir\org.gtk.Settings.* $target_schema_dir
$target_schema_unix = make-unixpath -path $target_schema_dir
$schema_compiler = make-unixpath -path "$mingw_dir\bin\glib-compile-schemas"
bash-command("$schema_compiler $target_schema_unix")


# Inno-setup isn't able to easily pick out particular message catalogs from $mingw_dir/share/locale, so copy the ones we want to $inst_dir\share\locale.

$source_locale_dir = "$mingw_dir\share\locale\"
$inst_locale_dir = "$inst_dir\share\locale"
foreach ($msgcat in "gtk30.mo","iso_4217.mo") {
    foreach ($dir in get-childitem -Directory $source_locale_dir) {
	$source_path = "$source_locale_dir\$dir\LC_MESSAGES"
	$inst_path = "$inst_locale_dir\$dir\LC_MESSAGES"
	if ((test-path $source_path) -and (test-path "$source_path\$msgcat") -and (test-path $inst_path)) {
	    copy-item "$source_path\$msgcat" -Destination $inst_path -recurse
	}
    }
}

write-host "Running Inno Setup to create $final_file."

if (test-path -path $setup_result) {
    remove-item -path $setup_result
}
& ${env:ProgramFiles(x86)}\inno\iscc /Q $target_dir\gnucash.iss

if ($git_build) {
  if ((test-path -path $setup_result) -and (test-path -path $final_file)) {
    remove-item $final_file
  }
  rename-item -path $setup_result $final_file
}
return $final_file
