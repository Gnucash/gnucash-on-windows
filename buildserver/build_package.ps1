# build_package.ps1: Powershell Script to build gnucash with MinGW64
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

Builds a gnucash installer and copies it to code.gnucash.org.

.DESCRIPTION

Updates gnucash-on-windows from origin, updates the MinGW-w64
installation, builds gnucash and dependencies with jhbuild, makes an
installer with bundle-mingw64.ps1, and secure-copies the installer and
session transcript to the download server.

This script must not be moved from the gnucash-on-windows.git working
directory.

You may need to allow running scripts on your computer and depending
on where the target_dir is you may need to run the script with
Administrator privileges.

.PARAMETER target_dir

Optional. The root path to the build environment. Defaults to the root of the script's path, e.g. if the script's path is C:\gcdev64\src\gnucash-on-windows.git\bundle-mingw64.ps1 the default target_dir will be C:\gcdev64.

.PARAMETER hostname

Optional. A ssh compatible server specification (which means [user@]hostname:basedirectory) to which the build artifacts will be uploaded. If omitted no upload will be attempted. Note for this to work you must be able to connect to the given hostname.

#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [validatePattern("(master|unstable|release)")][string]$branch,
    [Parameter()] [string]$target_dir,
    [Parameter()] [string]$hostname
)

$script_dir = Split-Path $script:MyInvocation.MyCommand.Path | Split-Path
$root_dir = Split-Path $script_dir | Split-Path
$package = "gnucash"
if (!$target_dir) {
    $target_dir = $root_dir
}

$progressPreference = 'silentlyContinue'
$env:MSYSTEM = 'MINGW32'
$env:TERM = 'dumb' #Prevent escape codes in the log.
$env:TARGET = "$package-$branch"

function bash-command() {
    param ([string]$command = "")
    if (!(test-path -path $target_dir\msys2\usr\bin\bash.exe)) {
	write-host "Shell program not found, aborting."
	return
    }
    #write-host "Running bash command ""$command"""
    Start-Process -FilePath "$target_dir\msys2\usr\bin\bash.exe" -ArgumentList "-lc ""$command""" -NoNewWindow -Wait
}

function make-unixpath([string]$path) {
    $path -replace  "^([A-Z]):", '/$1' -replace "\\", '/'
}
$script_unix = make-unixpath -path $script_dir
$target_unix = make-unixpath -path $target_dir

#$hostname = "upload@code.gnucash.org:public_html/win32"
$log_dir = "build-logs"

#Make sure that there's no running transcript, then start one:
$time_stamp = get-date -format "yyyy-MM-dd-HH-mm-ss"
$log_file = "$target_dir\build-$branch-$time_stamp.log"
$log_unix = make-unixpath -path $log_file
$time_stamp = get-date -format "yyyy-MM-dd HH:mm:ss"
bash-command -command "echo Build Started $time_stamp > $log_unix"
#copy the file to the download server so that everyone can see we've started
if ($hostname) {
    bash-command -command "scp -p $log_unix $hostname/$log_dir/"
}

# Update MinGW-w64
bash-command -command "pacman -Su --noconfirm > >(tee -a $log_unix) 2>&1"

# Update the gnucash-on-windows repository
#bash-command -command "cd $script_unix && git reset --hard && git pull --rebase"
# Build the latest GnuCash and all dependencies not installed via mingw64
bash-command -command "jhbuild --no-interact -f $script_unix/jhbuildrc build > >(tee -a $log_unix) 2> >(tee -a $log_unix)"
$new_file = test-path -path $target_dir\$package\$branch\inst\bin\gnucash.exe -NewerThan $time_stamp
if ($new_file) {
#Build the installer
    $is_git = ($branch.CompareTo("master") -or $branch.CompareTo("unstable"))
    bash-command -command "echo 'Creating GnuCash installer.' > >(tee -a $log_unix)"
    & $script_dir\bundle-mingw64.ps1 -target_dir $target_dir\$package\$branch -git_build $is_git 2>&1 | Tee-Object -FilePath $log_file -Append
}
$time_stamp = get-date -format "yyyy-MM-dd HH:mm:ss"
bash-command -command "echo Build Ended $time_stamp >> $log_unix"

# Copy the transcript and installer to the download server and delete them.
if ($hostname) {
	bash-command -command "scp -p $log_unix $hostname/$log_dir/"
    if ($new_file) {
	bash-command -command "scp -p $target_unix/gnucash*setup.exe $hostname/master"
    }
}
