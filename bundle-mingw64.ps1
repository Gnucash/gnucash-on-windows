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

Creates a GnuCash installer program from a GnuCash build. Note that we need to extract the Gtk, AqBanking, and Gwenhywfar message catalogs from the mingw_prefix hierarchy so using the same values for that and prefix will cause extraneous message catalogs to be included in the installer.

This script must not be moved from the gnucash-on-windows.git working directory.

You may need to allow running scripts on your computer and depending
on where the target_dir is you may need to run the script with
Administrator privileges.

.PARAMETER mingw_prefix

Optional. The path to the mingw_arch directory, default c:\gcdev64\msys2\ucrt64

.PARAMETER gnc_build_dir

Optional. The path to the GnuCash build directory, default: c:\gcdev64\gnuncash-build

.PARAMETER prefix

Optional. The value of CMAKE_INSTALL_PREFIX used when configuring the GnuCash and GnuCash Documentation builds. It's where this script expects to find the installed GnuCash and GnuCash-Docs files and is where it will write the installer program. Default: c:\gcdev64\gnucash-inst

.PARAMETER git_build

Optional. Boolean to indicate whether or not this is a git build. Default $true

#>

[CmdletBinding()]
Param(4
    [Parameter(Mandatory=$true)] [string]$mingw_prefix=c:\gcdev64\msys2\ucrt64,
    [Parameter(Mandatory=$true)] [string]$gnc_build_dir=c:\gcdev64\gnucash-build
    [Parameter(Mandatory=$true)] [string],$prefix=c:\gcdev64\inst
    [Parameter(Mandatory=$true)] [bool]$git_build=$true
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
  $gnucash = get-childitem -path $target_dir\build | where-object {$_.Name -match "gnucash-[0-9.]+"} |sort-object -Property {$_.CreationTime} | select-object -last 1
}

if ($PSVersionTable.PSVersion.Major -ge 3) {
    $PSDefaultParameterValues['*:Encoding'] = 'utf8'
    }

$gnc_config_h = "$gnc_build_dir\common\config.h"

$major_version = version_item -tag "PROJECT_VERSION_MAJOR" -path $gnc_config_h
$minor_version = version_item -tag "PROJECT_VERSION_MINOR" -path $gnc_config_h
$package_version = "$major_version.$minor_version"

$date = get-date -format "yyyy-MM-dd"
$setup_result =  "$prefix\gnucash-$package_version.setup.exe"
$final_file = ""
if ($git_build) {
  $gnc_vcsinfo_h = "$target_dir\build\gnucash-git\libgnucash\core-utils\gnc-vcs-info.h"
  $vcs_rev = version_item -tag "GNC_VCS_REV" -path $gnc_vcsinfo_h | %{$_ -replace """", ""}
  $final_file = "$target_dir\gnucash-$package_version-$date-git-$vcs_rev.setup.exe"
  }
else {
  $final_file = "$target_dir\gnucash-$package_version.setup.exe"
}

$schema_dir = "share\glib-2.0\schemas"
$target_schema_dir = "$prefix\$schema_dir"
copy-item $mingw_prefix\$schema_dir\org.gtk.Settings.* $target_schema_dir
$target_schema_unix = make-unixpath -path $target_schema_dir
$schema_compiler = make-unixpath -path "$mingw_prefix\bin\glib-compile-schemas"
bash-command("$schema_compiler $target_schema_unix")


# Inno-setup isn't able to easily pick out particular message catalogs from $mingw_prefix/share/locale, so copy the ones we want to $prefix\share\locale.

$source_locale_dir = "$mingw_prefix\share\locale"
$inst_locale_dir = "$prefix\share\locale"
foreach ($msgcat in "gtk30.mo", "gtk32-properties.mo", "iso_4217.mo ", "aqbanking.mo", "gwenhywfar.mo") {
    foreach ($dir in get-childitem -Directory $source_locale_dir) {
	$source_path = "$source_locale_dir\$dir\LC_MESSAGES"
	$inst_path = "$inst_locale_dir\$dir\LC_MESSAGES"
	if ((test-path $source_path) -and (test-path "$source_path\$msgcat") -and (test-path $inst_path)) {
	    copy-item "$source_path\$msgcat" -Destination $inst_path -recurse
	}
    }
}

# configure gnucash.iss

$msys_prefix = (msys2 -c 'cygpath -w $MSYSTEM_PREFIX').trim()

$content = Get-Content -Raw -Path inno_setup\gnucash-mingw64.iss
$content = $content.replace("@MINGW_DIR@", "$msys_prefix")
$content = $content.replace("@INST_DIR@", "$Env:RUNNER_TEMP\inst")
$content = $content.replace("@PACKAGE_VERSION@", "$package_version")
$content = $content.replace("@PACKAGE@", "gnucash")
$content = $content.replace("@GNUCASH_MAJOR_VERSION@", "$major_version")
$content = $content.replace("@GNUCASH_MINOR_VERSION@", "$minor_version")
$content = $content.replace("@GC_WIN_REPOS_DIR@", ".")
set-content -Path gnucash.iss -Value $content -Encoding utf8BOM

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
