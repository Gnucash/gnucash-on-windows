
Param([string]$target_dir = "c:\\gcdev64")

$progressPreference = 'silentlyContinue'
$installer32 = "http://repo.msys2.org/distrib/i686/msys2-i686-20161025.exe"
$archive32 = "http://repo.msys2.org/distrib/i686/msys2-base-i686-20161025.tar.xz"
$installer64 = "http://repo.msys2.org/distrib/x86_64/msys2-x86_64-20161025.exe"
$archive64 = "http://repo.msys2.org/distrib/x86_64/msys2-base-x86_64-20161025.tar.xz"

$download_dir = "c:\\gcdev\\downloads"
$installer_file = "$download_dir\\msys2.exe"
$archive_file = "$download_dir\\msys2-base.tar.xz"
$installer = If ([IntPtr]::size -eq 4) {$installer32} Else {$installer64}

$mingw_setup = @"
function Controller() {}
Controller.prototype.IntroductionPageCallback = function() {
    gui.clickButton(buttons.NextButton);
}
Controller.prototype.TargetDirectoryPageCallback = function() {
    var page = gui.pageWidgetByObjectName("TargetDirectoryPage");
    page.TargetDirectoryLineEdit.setText("$target_dir\\msys2");
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

if (!(test-path -path $installer_file)) {
   Write-Host "Downloading $installer_file from $installer"
   Invoke-WebRequest -URI $installer -OutFile $installer_file
}
if (!(test-path -path $target_dir)) {
   New-Item $target_dir -type directory
}

Set-Content -Path $target_dir\mingw64-setup.qs -Value $mingw_setup | Out-Null
Set-Location -Path $target_dir

function bash-command() {
   param ([string]$command = "")
   $psi = new-object "Diagnostics.ProcessStartInfo"
   $psi.Filename = "$target_dir\msys2\usr\bin\bash.exe"
   $psi.Arguments =  "-c ""export PATH=/usr/bin; $command"""
   return [Diagnostics.Process]::Start($psi)
}

#if MSys2 isn't already installed, install it.
if (!(test-path -path $target_dir\msys2\usr\bin\bash.exe)) {
   & $installer_file --script $target_dir\mingw64-setup.qs | Out-Null
   Write-Host @"
Updating the new installation. A bash window will open. In that window accept the proposed installation and close the window when the update completes.

There will be a second update.
"@
   $proc = bash-command("pacman -Syuu")
   $proc.WaitForExit()
}

#Update the system.
Write-Host @"

Updating the installation. Accept the proposed changes. If the window doesn't close on its own then close it and re-run the script when it finishes.
"@

$proc = bash-command("pacman -Syuu")
$proc.WaitForExit()

# Set up aliases for the parts of msys-devtools and mingw-w64-toolchain that
# we need:
$msys_devel = "msys/asciidoc msys/autoconf msys/autoconf2.13 msys/autogen msys/automake-wrapper msys/automake1.10 msys/automake1.11 msys/automake1.12 msys/automake1.13 msys/automake1.14 msys/automake1.15 msys/automake1.6 msys/automake1.7 msys/automake1.8 msys/automake1.9 msys/bison msys/diffstat msys/diffutils msys/dos2unix msys/file msys/flex msys/gawk msys/gdb msys/gettext msys/gettext-devel msys/gperf msys/grep msys/groff msys/intltool msys/libtool msys/m4 msys/make msys/man-db msys/pacman msys/pactoys-git msys/patch msys/patchutils msys/perl msys/pkg-config msys/sed msys/swig msys/texinfo msys/texinfo-tex msys/wget msys/xmlto"

$mingw32_toolchain = "mingw32/mingw-w64-i686-binutils mingw32/mingw-w64-i686-crt-git mingw32/mingw-w64-i686-gcc mingw32/mingw-w64-i686-gcc-libs mingw32/mingw-w64-i686-gdb mingw32/mingw-w64-i686-headers-git mingw32/mingw-w64-i686-libmangle-git mingw32/mingw-w64-i686-libwinpthread-git mingw32/mingw-w64-i686-make mingw32/mingw-w64-i686-pkg-config mingw32/mingw-w64-i686-tools-git mingw32/mingw-w64-i686-winpthreads-git"

# Aliases to collect the other dependencies:
$other_msys = "msys/git msys/jhbuild-git"

$other_mingw = "mingw32/mingw-w64-i686-webkitgtk2 mingw32/mingw-w64-i686-boost mingw32/mingw-w64-i686-iso-codes mingw32/mingw-w64-i686-shared-mime-info mingw32/mingw-w64-i686-libmariaclient mingw32/mingw-w64-i686-postgresql  mingw32/mingw-w64-i686-libgnomecanvas mingw32/mingw-w64-i686-ninja"

Write-Host @"

Now we'll install the dependencies. Accept the installation as usual. About half-way through it will stop with a message about fontconfig. Just type "Return" at it and it will resume and complete the installation.
"@
$proc = bash-command("pacman -S $msys_devel $mingw32_toolchain $other_msys $other_mingw")
$proc.waitForExit()

Write-Host @"

Finally we'll clone the gnucash-on-windows repository into target-dir/src and you'll be ready to build GnuCash.
"@

if (!(test-path -path "$target_dir\\src")) {
  New-Item $target_dir\\src -type directory
}
if (!(test-path -path "$target_dir\\src\\gnucash-on-windows.git")) {
  $proc = bash-command("git clone -b mingw64 https://github.com/gnucash/gnucash-on-windows.git $target_dir/src/gnucash-on-windows.git")
  $proc.waitForExit()
}
