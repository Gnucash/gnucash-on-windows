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

Prepares a MinGW-w64 development environment from scratch
or enhances one already existing on the system.

.DESCRIPTION

Prepares a development environment for building GnuCash with jhbuild
in a MinGW-w64 (a.k.a. MSys2) environment. All required packages are
installed and the gnucash-on-windows repository containing the other
needed scripts is cloned into the target.

You may need to allow running scripts on your computer and depending
on where the target_dir is you may need to run the script with
Administrator privileges.

.PARAMETER target_dir

Optional. The path at which you wish to create the environment. If
none is provided the environment will be created at C:\gcdev64.

.PARAMETER download_dir

Optional. A path to which to download installers. Defaults to
target_dir\downloads.

.PARAMETER msys2_root

Optional. The root path of an already installed MSys2 environment. 
E.g. C:\msys64.

.PARAMETER x86_64

Optional. A switch value.If true the toolchain will build x86_64
binaries; if false it will build i686 binaries. Defaults to false.

#>

[CmdletBinding()]
Param(
	[Parameter()] [string]$target_dir = "c:\\gcdev64",
	[Parameter()] [string]$download_dir = "$target_dir\\downloads",
	[Parameter()] [string]$msys2_root = "$target_dir\\msys2",
	[Parameter()] [switch]$x86_64
)

$bash_path = "$msys2_root\\usr\\bin\\bash.exe"

$progressPreference = 'silentlyContinue'
if ($x86_64) {
    $arch = "mingw64"
    $arch_code = "x86_64"
}
else {
    $arch = "mingw32"
    $arch_code = "i686"
}

$arch_long = "mingw-w64-$arch_code"
$mingw_prefix = "$arch/$arch_long-"
$mingw_path = "/$arch"
$mingw_bin = "$mingw_path/bin"
$mingw_url_prefix = "http://repo.msys2.org/mingw/$arch_code/$arch_long-"
$env:MSYSTEM = $arch.ToUpper()

if (!(test-path -path $target_dir)) {
    new-item "$target_dir" -type directory
}

if (!(test-path -path $download_dir)) {
    new-item "$download_dir" -type directory
}

function make-pkgnames ([string]$prefix, [string]$items) {
    $items.split(" ") | foreach-object {"$prefix$_"}
}

function Install-Package([string]$url, [string]$download_file,
	  [string]$install_dir, [string]$setup_cmd, [string]$setup_args)
{
    if (!(test-path -path $download_file)) {
	write-host "Downloading $download_file from $url"
	(New-Object System.Net.WebClient).DownloadFile($url, $download_file)
    }

    write-host "Installing $download_dir\$setup_cmd $setup_args"
    $psi = new-object "Diagnostics.ProcessStartInfo"
    $psi.Filename = "$download_dir\$setup_cmd"
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

function make-unixpath([string]$path) {
    $path -replace  "^([A-Z]):", '/$1' -replace "\\", '/' -replace "//", '/'  -replace "\(", '\(' -replace "\)", '\)' -replace " ", '\ '
}

# Install MSYS2 for the current machine's architechture.

if (!(test-path -path $bash_path)) {
    $mingw64_installer32 = "http://repo.msys2.org/distrib/i686/msys2-i686-20180531.exe"
    $mingw64_installer64 = "http://repo.msys2.org/distrib/x86_64/msys2-x86_64-20180531.exe"

    $mingw64_installer_file = "$download_dir\msys2.exe"
    $mingw64_installer = If ([IntPtr]::size -eq 4) {$mingw64_installer32} Else {$mingw64_installer64}
    $msys_install_dir = (join-path $target_dir "msys2") -replace "\\", '/'
    $msys_setup_args = @"
function Controller() {}
Controller.prototype.IntroductionPageCallback = function() {
    gui.clickButton(buttons.NextButton);
}
Controller.prototype.TargetDirectoryPageCallback = function() {
    var page = gui.pageWidgetByObjectName("TargetDirectoryPage");
    page.TargetDirectoryLineEdit.setText("$msys_install_dir");
    gui.clickButton(buttons.NextButton);
}
Controller.prototype.StartMenuDirectoryPageCallback = function() {
    gui.clickButton(buttons.NextButton);
}
Controller.prototype.FinishedPageCallback = function() {
    var page = gui.pageWidgetByObjectName("FinishedPage");
    page.RunItCheckBox.checked = false;
    gui.clickButton(buttons.FinishButton);
}
"@

    $setup_script = "$target_dir\input.qs"
    set-content -path $setup_script -value $msys_setup_args | out-null
    install-package -url $mingw64_installer -download_file $mingw64_installer_file -install_dir "$msys2_root" -setup_cmd "msys2.exe" -setup_args "--script $setup_script"
#    remove-item $setup_script
}
if (!(test-path -path $bash_path)) {
    write-host "Failed to install MSys2, aborting."
    exit
}

# Install Html Help Workshop

$html_help_workshop_url =  "http://download.microsoft.com/download/0/a/9/0a939ef6-e31c-430f-a3df-dfae7960d564/htmlhelp.exe"
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

#if MSys2 isn't already installed, install it.
if (!(test-path -path $bash_path)) {
   Write-Host @"
Updating the new installation. A bash window will open. In that window accept the proposed installation and close the window when the update completes.

There will be a second update.
"@
   bash-command -command "pacman -Syuu --noconfirm"
}

#Update the system.
Write-Host @"

Updating the installation. Accept the proposed changes. If the window doesn't close on its own then close it and re-run the script when it finishes.
"@

bash-command -command "pacman -Syuu --noconfirm"

# Set up aliases for the parts of msys-devtools and mingw-w64-toolchain that
# we need:
$devel = "asciidoc autoconf autoconf2.13 autogen automake-wrapper automake1.10 automake1.11 automake1.12 automake1.13 automake1.14 automake1.15 automake1.6 automake1.7 automake1.8 automake1.9 bison diffstat diffutils dos2unix file flex gawk gettext gettext-devel gperf grep groff intltool libtool m4 make man-db pacman pactoys-git patch patchutils perl pkg-config sed swig texinfo texinfo-tex wget xmlto git jhbuild-git texinfo"

$toolchain = "binutils cmake crt-git gcc gcc-libs gdb headers-git libmangle-git libtool libwinpthread-git make pkg-config tools-git winpthreads-git"

$clang_toolchain = "clang libc++ libc++abi lld libunwind clang-tools-extra compiler-rt"

# Install the system and toolchain:
$msys_devel = make-pkgnames -prefix "msys/" -items $devel
bash-command -command "pacman -S $msys_devel --noconfirm --needed"
$mingw_toolchain = make-pkgnames -prefix $mingw_prefix -items $toolchain
bash-command -command "pacman -S $mingw_toolchain --noconfirm --needed"

# webkitgtk3 was removed from the pacman database but the package is still available via direct url
# so we install it from that url directly.
# Note webkitgtk3 depends on icu. Icu updates require dependent packages to be rebuilt to work with the new version.
# However as there won't be any webkitgtk3 updates, we have to peg icu to the version the last webkitgtk3
# was built with. That also impacts other icu dependent packages: boost and harfbuzz. As we peg icu
# we equally need to peg these two.
# Note that webkitgtk3 will pull in gtk3 automatically.

Write-Host @"

Now we'll install webkitgtk3 via direct url as it's no longer in the pacman database. With this we install a couple of other packages that are pegged to fixed version numbers due to how icu forces package dependencies. If the window doesn't close on its own then close it and re-run the script when it finishes.
"@
$direct_deps = "webkitgtk3-2.4.11-6-any.pkg.tar.xz boost-1.67.0-2-any.pkg.tar.xz harfbuzz-1.8.4-1-any.pkg.tar.xz icu-61.1-1-any.pkg.tar.xz"
$mingw_direct_deps = make-pkgnames -prefix $mingw_url_prefix -items $direct_deps
bash-command -command "pacman -U $mingw_direct_deps --noconfirm --needed"

# Tell pacman to no longer update these manually installed packages
$ignorefile = @"
IgnorePkg   = mingw-w64-i686-icu
IgnorePkg   = mingw-w64-i686-boost
IgnorePkg   = mingw-w64-i686-harfbuzz
IgnorePkg   = mingw-w64-i686-webkitgtk3
"@
[IO.File]::WriteAllLines( (join-path $target_dir (join-path "msys2" (join-path "etc" (join-path "pacman.d" "gnucash-ignores.pacman")))), $ignorefile)
bash-command -command "perl -ibak -pe 'BEGIN{undef $/;} s#[[]options[]]\R(Include = [^\R]*\R)?#[options]\nInclude = /etc/pacman.d/gnucash-ignores.pacman\n#smg' /etc/pacman.conf"

# Install the remaining dependencies.
$deps = "iso-codes shared-mime-info libmariadbclient postgresql ninja ncurses"

Write-Host @"

Now we'll install the dependencies. Accept the installation as usual. About half-way through it will stop with a message about fontconfig. Just type "Return" at it and it will resume after a minute or two (be patient!) and complete the installation.
"@

$mingw_deps = make-pkgnames -prefix $mingw_prefix -items $deps
bash-command -command "pacman -S $mingw_deps --noconfirm --needed"

$target_unix = make-unixpath $target_dir
$download_unix = make-unixpath $download_dir

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
****** ERROR ****
There was an error installing HTML Help Workshop. This will prevent building the documentation. If you didn't before, run setup-mingw64.ps1 in a PowerShell instance with Administrative priviledge. If you did that already, you may need to install HTML Help Workshop by hand.
****************
"@
    } else {
	bash-command -command "cp $installed_hh/include/htmlhelp.h $mingw_path/include"

	bash-command -command "$mingw_bin/gendef $hhctrl_ocx - > $mingw_path/lib/htmlhelp.def"
	bash-command -command "$mingw_bin/dlltool -k -d $mingw_path/lib/htmlhelp.def -l $mingw_path/lib/libhtmlhelp.a"
    }
    if (!(test-path -path $htmlhelp_h)) {
	Write-Host "HTML Help Workshop isn't correctly installed."
    }
}
Write-Host @"

Clone the gnucash-on-windows repository into the target source directory, patch jhbuild to disable its DESTDIR dance and set up jhbuildrc with our prefixes.
"@

if (!(test-path -path "$target_dir\\src")) {
  New-Item $target_dir\\src -type directory
}
if (!(test-path -path "$target_dir\\src\\gnucash-on-windows.git")) {
  bash-command -command "git clone https://github.com/gnucash/gnucash-on-windows.git $target_unix/src/gnucash-on-windows.git"
}
if (!(test-path -path "$target_dir\\src\\gnucash-on-windows.git")) {
   write-host "Failed to clone the gnucash-on-windows repo, exiting."
   exit
}

bash-command -command "/usr/bin/patch -f -d/ -p0 -i $target_unix/src/gnucash-on-windows.git/patches/jhbuild.patch"
bash-command -command "/usr/bin/patch -f -d $(dirname $(/usr/bin/find /$arch/share/cmake* -name FindSWIG.cmake) ) -p2 -i $target_unix/src/gnucash-on-windows.git/patches/FindSWIG.patch"

$jhbuildrc = get-content "$target_dir\\src\\gnucash-on-windows.git\\jhbuildrc.in" |
 %{$_ -replace "@-BASE_DIR-@", "$target_unix"} |
 %{$_ -replace "@-DOWNLOAD_DIR-@", "$download_unix"} |
 %{$_ -replace "@-ARCH-@", "$arch"}
 [IO.File]::WriteAllLines("$target_dir\\src\\gnucash-on-windows.git\\jhbuildrc", $jhbuildrc)

Write-Host @"


Your build environment is now ready to use. Open an MSys2/$arch shell from the start menu, cd to $target_unix, and run
jhbuild -f src/gnucash-on-windows.git/jhbuildrc build

Note that the build will not work with the plain MSys2 shell!
"@
