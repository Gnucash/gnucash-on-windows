# Building GnuCash on Windows

This repository provides a simple, repeatable means to build GnuCash 3 on Microsoft Windows using [MinGW-W64](https://mingw-w64.org/doku.php), [Gnome's jhbuild](https://wiki.gnome.org/action/show/Projects/Jhbuild?action=show&redirect=Jhbuild), and [JRSoftware's Inno Setup](http://www.jrsoftware.org/isinfo.php). It is what drives building the official All-in-One installers and what the GnuCash core development team uses to create development environments.

## Requirements

* Windows Vista or later. You must have an account with Administrator privileges.
* Powershell 3.0 or later. Note that Vista and Win7 provided only Powershell 2.0. [Get an upgrade from Microsoft](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-windows-powershell?view=powershell-6).

## Installation

Download [setup-mingw.ps1](https://raw.githubusercontent.com/Gnucash/gnucash-on-windows/master/setup-mingw64.ps1).

Start a Powershell session:
* Click the Start icon and start typing "powershell" until Windows recognizes it and presents a menu item. Click that.

If you need Administrative Privileges:
* Win10, right-click on the Start icon and select ```Windows Powershell (Admin)```
* Win7, click the Start icon and start typing "powershell" until ```Windows PowerShell``` appears in the search dialog. Right-click on it and select ```Run as Administrator```.

If you don't routinely run PowerShell scripts on your computer you will need to first set the [Execution Policy](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-3.0) to **RemoteSigned**. You will need Powershell session with Administrative Privileges for this step:
1. Start Powershell with Admin Privileges
1. Run ```set-executionpolicy -executionpolicy RemoteSigned -scope LocalMachine```
1. Quit Powershell if you plan to run ```setup-mingw64.ps1``` without Administrative Privileges.

In a PowerShell session run ```path/to/setup-mingw64.ps1```; the path will depend on your browser settings but if you have a default setup then it's ```~/Downloads/setup-mingw64.ps1```.

###setup-mingw64 Options
```setup-mingw64.ps1``` takes four optional arguments:
* **-target_dir**: The full path to where the MinGW-W64 environment will be created. **Default**: ```C:\gcdev64```. The default requires Administrative privileges to create. If you use a directory in your home directory instead then you will not require Admin privileges.

* **-download_dir**: The name of the subdirectory in **target_dir** where source tarballs will be downloaded to. **Default**: **target_dir**```\downloads```.

* **-msyw2_root**: The base directory of the MSYS2/MinGW-W64 environment. You can reuse an existing environment, but we don't recommend changing this. **Default**:**target_dir**```\msys2```.

* **-x86_64**: Setting this will build a 64-bit GnuCash. **Default**: Unset, for 32-bit builds able to run on older systems.

It will take a while to complete. When it's done you'll have a new group in your Start Menu named ```MSYS2 64bit``` or ```MSYS2 32bit``` depending on the bitness of your version of Windows. Note that this is independent of whether you set the **-x86_64** option. In that group you'll find 3 selections:
* MSYS2 MSys2
* MSYS2 MingGW 32-bit
* MSYS2 MinGW 64-bit

These create terminal emulation sessions running the Bash shell with the environment configured for different uses. You will nearly always want to use the MinGW with the bitness you selected.

## Building GnuCash

1. Start an MSYS MinGW shell for the selected bitness.
1. Change directories to the installation directory ```cd /c/gcdev64/src/gnucash-on-windows.git```. Substitute the path if you set **-target_dir** to something else. Note that in this shell you'll use ```/c``` instead of ```C:``` for the drive letter.
1. run ```TARGET=gnucash-maint jhbuild -f jhbuildrc build``` to build the ```maint``` branch, substitute ```gnucash-master``` for ```gnucash-maint``` if you want to build the ```master``` branch.

## Developing

Once you've built GnuCash all the way through you can get a build-and-run environment by starting a MinGW shell and running ```TARGET=gnucash-maint jhbuild -f jhbuildrc shell``` from the ```gnucash-on-windows.git``` directory.

```cd $PREFIX/../build/gnucash-git``` to get to the build directory and ```$PREFIX/../src/gnucash-git``` to get to the local repo.

To install the gdb debugger run ```pacman -Su gdb```. You need not be in a jhbuild shell.

## Bundling GnuCash

1. Start a Powershell session.
1. Change to the installation directory ```cd C:\gcdev64\src\gnucash-on-windows.git```
1. run ```bundle-mingw64.ps1 -root_dir C:\gcdev64 -target_dir C:\gcdev64\gnucash\maint -package maint -git_build $true```

That will create a date-stamped and versioned ```gnucash-xxx-setup.exe``` in ```C:\gcdev64\gnucash\maint```. You'll need to adjust paths and versions accordingly if you changed **target_dir** when you ran ```setup-mingw64.ps1``` or built ```master``` instead of maint.

## Buildserver

This repository includes a script, ```buildserver\build_package.ps1``` that combines building and bundling GnuCash and uploading the result to a distribution webserver into a single command. It's intended for automated nightly build scripts.

### build_package.ps1 options
* **branch**: ```maint```, ```master```, or ```release```. The last builds the release configured in gnucash.modules from the release tarball.
* **target_dir**: The **target_dir** configured into ```setup-mingw64.ps1```.
* **hostname**: The upload URI. Optional. If set the script will attempt to scp the gnucash-xxx-setup.exe and the build log to hard-coded subdirectories under this URI. The user running the script must have correctly configured ssh to connect to the URI with a key; there's no provision for password authentication.

## Other files:
* ```jhbuildrc.in``` Template jhbuild configuration file, converted to ```jhbuildrc``` by ```setup-mingw64.ps1``` with the **target_dir**.
* ```gnucash.modules```: The jhbuild moduleset for building GnuCash.
* ```inno_setup/```: Configuration and localization files for building ```gnucash-xxx-setup.exe``` with Inno Setup.
* ```patches/```: Modifications to the source packages required to build in this environment.
* ```extra_dist/```: The Online Quote Installation tool.
* ```exetype.pl```: A perl script for converting the executable type of programs between Windowed and Console. It is sometimes useful to convert the GnuCash executable to Console type (it's built as Windowed) to capture some text output it emits before logging starts.