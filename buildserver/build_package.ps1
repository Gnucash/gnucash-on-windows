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

.PARAMETER mingw_arch

Optional. One of mingw32, mingw64, clang64, or ucrt64. Defaults to ucrt64.

.PARAMETER hostname

Optional. A ssh compatible server specification (which means [user@]hostname:basedirectory) to which the build artifacts will be uploaded. If omitted no upload will be attempted. Note for this to work you must be able to connect to the given hostname.

#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [validatePattern("(stable|future|unstable|release)")][string]$branch,
    [Parameter()] [string]$target_dir,
    [Parameter()]
    [validatePattern("(mingw32|mingw64|clang64|ucrt64)")][string]$mingw_arch,
    [Parameter()] [string]$hostname
)

$script_dir = Split-Path $script:MyInvocation.MyCommand.Path | Split-Path
$root_dir = Split-Path $script_dir | Split-Path
$package = "gnucash"
if (!$target_dir) {
    $target_dir = $root_dir
}
if (!$mingw_arch) {
    $mingw_arch = "ucrt64"
}

$progressPreference = 'silentlyContinue'
$env:MSYSTEM = $mingw_arch
$env:TERM = 'dumb' #Prevent escape codes in the log.
$env:GNUCASH_BUILD = $branch
# This allows us to run Msys2 commands such as bash.exe directly
$Env:Path = "$target_dir\msys2\usr\bin;$Env:Path"

if ($PSVersionTable.PSVersion.Major -ge 3) {
    $PSDefaultParameterValues['*:Encoding'] = 'utf8'
}

if (!(test-path -path $target_dir\msys2\usr\bin\bash.exe)) {
    Write-Output "Shell program not found, aborting."
    Exit 1
}

function bash-command() {
    param ([string]$command = "")
    #Write-Output "Running bash command ""$command"""
    bash.exe -lc "$command 2>&1"
}

function check-version([string]$program) {
    $program_path = "$target_dir\msys2\$mingw_arch\bin\$program"
    if (test-path -path $program_path) {
        $vline = & $program_path --version | Select-String "Build ID:" | %{$_ -split "\s+"}
        if ($vline[2] -eq "git") {
            $package_version = $vline[3].split('+')[0]
        }
        else {
            $package_verion = $vline[2].split('+')[0]
        }
    }
    else {
        $package_version = "not-installed"
    }
    return $package_version
}

function make-unixpath([string]$path) {
    $path -replace  "^([A-Z]):", '/$1' -replace "\\", '/'
}
$script_unix = make-unixpath -path $script_dir
$target_unix = make-unixpath -path $target_dir

#$hostname = "upload@code.gnucash.org:public_html/win32"
$log_dir = "build-logs"

#Make sure that there's no running transcript, then start one:
$time_stamp_file = get-date -format "yyyy-MM-dd-HH-mm-ss"
$yyyy_mm_dir = get-date -format "yyyy-MM"
$log_dir_full = "$target_dir\win32\$log_dir\$branch\$yyyy_mm_dir"
$log_file = "$log_dir_full\build-$branch-$time_stamp_file.log"
$log_unix = make-unixpath -path $log_file
New-Item -ItemType Directory -Force -Path "$log_dir_full" | Out-Null

$time_stamp = get-date -format "yyyy-MM-dd HH:mm:ss"
Write-Output "Build Started $time_stamp" | Tee-Object -FilePath $log_file
Write-Output ":: Checking gnucash-on-windows for updates..." | Tee-Object -FilePath $log_file
git.exe -C $script_unix pull 2>&1 | Tee-Object -FilePath $log_file -Append
#copy the file to the download server so that everyone can see we've started
if ($hostname) {
    bash.exe -lc "$script_unix/buildserver/upload_build_log.sh $log_unix $hostname $log_dir $branch"
}

# Update MinGW-w64 twice. If the first is a system update a second is
# needed to update the dependencies.
pacman.exe -Syu --noconfirm 2>&1 | Tee-Object -FilePath $log_file -Append
pacman.exe -Syu --noconfirm 2>&1 | Tee-Object -FilePath $log_file -Append

$starting_gc_version = check-version -program "gnucash-cli.exe"

$_unix_path = make-unixpath("$script_dir\packages\gnucash")
bash-command("cd $_unix_path && makepkg-mingw -sCLi --noconfirm --needed" )
$_unix_path = make-unixpath("$script_dir\packages\gnucash-docs")
bash-command("cd $_unix_path && makepkg-mingw -sCLi --noconfirm --needed")

$new_gc_version = check-version -program "gnucash-cli.exe"

if ($starting_gc_version -eq "not-installed" -or
    $new_gc_version -ne $starting_gc_version) {
#Build the installer
    Write-Output "Creating GnuCash installer." | Tee-Object -FilePath $log_file -Append
    $setup_file = & $script_dir\bundle-mingw64.ps1 -mingw_prefix $target_dir\msys2 -mingw_arch $mingw_arch 2>&1 | Tee-Object -FilePath $log_file -Append
    $setup_file_valid = Test-Path -Path "$setup_file"
    if ($setup_file_valid) {
        $destination_dir="$target_dir\win32\$branch"
        New-Item -ItemType Directory -Force -Path "$destination_dir" | Out-Null
        Move-Item -Path "$setup_file" -Destination "$destination_dir" -Force
        $pkg_name = Split-Path -Path "$setup_file" -Leaf
        $setup_file = "$destination_dir\$pkg_name"
        Write-Output "Created GnuCash Setup File $setup_file" | Tee-Object -FilePath $log_file -Append
    }
    else {
        Write-Output "An error occurred while creating the GnuCash installer:" | Tee-Object -FilePath $log_file -Append
        Write-Output "$setup_file" | Tee-Object -FilePath $log_file -Append
    }

    }
else
{
    Write-Output "The GnuCash version is unchanged." ! Tee-Object -FilePath $log_file -Append

}
$time_stamp = get-date -format "yyyy-MM-dd HH:mm:ss"
Write-Output "Build Ended $time_stamp" | Tee-Object -FilePath $log_file -Append

# Copy the transcript and installer to the download server and delete them.
if ($hostname) {
    bash.exe -lc "$script_unix/buildserver/upload_build_log.sh $log_unix $hostname $log_dir $branch 2>&1"
    if ($setup_file_valid) {
        $setup_file = make-unixpath -path $setup_file
        bash.exe -lc "rsync.exe -e ssh -a $setup_file $hostname/$branch 2>&1"
    }
}
