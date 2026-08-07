# setup-mingw64.ps1: Powershell Script to create a MinGW64 Build Environment.
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

Automates installation of a single MSYS2 environment suitable for
building GnuCash and the GnuCash documentation.

.DESCRIPTION

Installs a single MSYS2 environment (one of mingw32, mingw64, clang64
or ucrt64; the last is the default and is recommended for development)
including all dependencies.

You may need to allow running scripts on your computer and depending
on where the target_dir is you may need to run the script with
Administrator privileges.


.PARAMETER target_dir

Optional. The path at which you wish to create the environment. If
none is provided the environment will be created at c:\gcdev64, which
will require admin privileges to set up. Avoid paths with spaces, some
MSYS2 shell scripts have trouble with them.

.PARAMETER mingw_arch

Optional. Either clang64 or ucrt64, default is ucrt64.

.PARAMETER msys2_root

Optional. The root path to the MSys2 environment,
e.g. C:\msys64. Default is target_dir/msys2.

#>

[CmdletBinding()]
Param(
    [Parameter()] [string]$target_dir = "C:\\gcdev64",
    [Parameter()] [string]$mingw_arch = "ucrt64",
    [Parameter()] [string]$msys2_root = "$target_dir\\msys2"
)

function make-unixpath([string]$path) {
    $new_path = $path -replace  "^([A-Z]):", '/$1' -replace "\\", '/' -replace "//", '/'
    "$new_path"
}

$bash_path = "$msys2_root\\usr\\bin\\bash.exe"
switch ($mingw_arch) {
    "clang64" { $mingw_arch_code = "clang-x86_64" }
    "ucrt64"  { $mingw_arch_code = "ucrt-x86_64" }
    default { write-host "$mingw_arch is not supported"
              exit
            }
}

$progressPreference = 'silentlyContinue'
$msys_uri = "http://repo.msys2.org"
$mingw_arch_long = "mingw-w64-$mingw_arch_code"
$mingw_prefix = "$mingw_arch/$mingw_arch_long-"
$mingw_path = "/$mingw_arch"
$mingw_bin = "$mingw_path/bin"
$mingw_url_prefix = "$msys_uri/mingw/$mingw_arch_code/$mingw_arch_long-"
$env:MSYSTEM = $mingw_arch.ToUpper()
$download_dir="$env:USERPROFILE\\Downloads"

if (!(test-path -path $target_dir)) {
    new-item "$target_dir" -type directory
}

function make-pkgnames ([string]$prefix, [string]$items) {
    $items.split(" ") | foreach-object {"$prefix$_"}
}

function install-package([string]$url, [string]$install_dir,
			 [string]$setup_args)
{
    $filename = $url.Substring($url.LastIndexOf("/") + 1)
    $download_file = "$download_dir\$filename"
    if (!(test-path -path $download_file)) {
	write-host "Downloading $download_file from $url"
        curl.exe -L $url --output $download_file
    }

    write-host "Installing $download_file $setup_args"
    $psi = new-object "Diagnostics.ProcessStartInfo"
    $psi.Filename = "$download_file"
    $psi.Arguments = "$setup_args"
    $proc = [Diagnostics.Process]::Start($psi)
    $proc.waitForExit()
}


function bash-command() {
    param ([string]$command = "")
    if (!(test-path -path $bash_path)) {
	write-host "Shell program not found, aborting."
	return
    }
    #write-host "Running bash command ""$command"""
    Start-Process -FilePath "$bash_path" -ArgumentList "-c ""export PATH=/usr/bin; $command""" -NoNewWindow -Wait
}

# Install MSYS2

if (!(test-path -path $bash_path)) {
    $mingw64_installer = "$msys_uri/distrib/msys2-x86_64-latest.exe"

    $msys_install_dir = (join-path $target_dir "msys2") -replace "\\", '/'
    $msys_setup_args = @"
"@

    install-package -url $mingw64_installer -install_dir "$msys2_root" -setup_args "in --root ""$msys_install_dir"" --al --am -c"

}
if (!(test-path -path $bash_path)) {
    write-host "Failed to install MSys2, aborting."
    exit
}

$ucrt_repo_url = "https://github.com/gnucash/gnucash-on-windows/releases/download/gnc-ucrt64-repo/"

$html_help_workshop_url =  "http://web.archive.org/web/20160201063255/http://download.microsoft.com/download/0/A/9/0A939EF6-E31C-430F-A3DF-DFAE7960D564/htmlhelp.exe"
$html_help_workshop_installer = "htmlhelp.exe"

$installed_hh = get-item -path "hkcu:\SOFTWARE\Microsoft\HTML Help Workshop" | foreach-object{$_.GetValue("InstallDir")}

if (! (($installed_hh) -and (test-path -path $installed_hh))) {
  install-package -url $html_help_workshop_url -download_file "$download_dir\\$html_help_workshop_installer" -install_dir ${env:ProgramFiles(x86)} -setup_cmd $html_help_workshop_installer
}
$hhctrl_ocx = "c:\Windows\System32\hhctrl.ocx"
if (!(test-path -path $hhctrl_ocx)) {
    write-host "Something's wrong with HTML Help Workshop, couldn't find $hhctrl_ocx."
    exit
}
$hhctrl_ocx = make-unixpath -path $hhctrl_ocx


# Install Inno Setup
if (!(test-path -path ${env:ProgramFiles(x86)}\inno)) {
    $inno_setup_url = "http://files.jrsoftware.org/is/5/innosetup-5.5.9-unicode.exe"
    $inno_setup_installer = "innosetup-5.5.9-unicode.exe"
    $inno_setup_args = " /verysilent /suppressmsgboxes /nocancel /norestart /dir=""${env:ProgramFiles(x86)}\inno"""
   install-package -url $inno_setup_url -download_file "$download_dir\$inno_setup_installer" -install_dir ${env:ProgramFiles(x86)} -setup_cmd $inno_setup_installer -setup_args $inno_setup_args
}
# Update the core system.
Write-Host @"
Install all base system updates. There will be two updates, one for the core files and a second one for utilities.
"@
bash-command -command "pacman -Syyuu --noconfirm"
bash-command -command "pacman -Syyuu --noconfirm"

$Env:MINGW_ARCH = $mingw_arch
$pwd = pwd
$PWD = make-unixpath $pwd
bash-command -command """$PWD/setup-mingw64.sh"""
Write-Host @"

Next we'll install the HTML Help Workshop includes and libraries into our MinGW directory.
"@

$htmlhelp_h = "$msys2_root/$mingw_path/include/htmlhelp.h"
if (!(test-path -path $htmlhelp_h)) {
    if (!$installed_hh) {
	$installed_hh = get-item -path "hkcu:\SOFTWARE\Microsoft\HTML Help Workshop" | foreach-object{$_.GetValue("InstallDir")}
    }
    $installed_hh = make-unixpath -path $installed_hh
    if (!$installed_hh) {
	Write-Host @"
****** ERROR ***
There was an error installing HTML Help Workshop. This will prevent building the documentation. If you didn't before, run setup-mingw64.ps1 in a PowerShell instance with Administrative priviledge. If you did that already, you may need to install HTML Help Workshop by hand.
****************
"@
    } else {
	bash-command -command "cp """"$installed_hh/include/htmlhelp.h"""" $mingw_path/include"
	bash-command -command "$mingw_bin/gendef $hhctrl_ocx - > $mingw_path/lib/htmlhelp.def"
	bash-command -command "cd $mingw_path/lib && $mingw_bin/dlltool -k -d htmlhelp.def -l libhtmlhelp.a"
    }
    if (!(test-path -path $htmlhelp_h)) {
	Write-Host "HTML Help Workshop isn't correctly installed."
    }
}
Write-Host @"
Your $mingw_arch build environment is set up with all build dependencies installed. Open a $Env:MSYSTEM shell from the MSYS2 folder in the Start Menu and clone https://github.com/gnucash/gnucash and https://gnucash/gnucash-docs somewhere convenient and build them as usual.
"@
