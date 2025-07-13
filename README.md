# Building GnuCash on Windows

This repository provides a simple, repeatable means to build GnuCash
on Microsoft Windows using
[MSYS2](https://www.msys2.org/)/[MinGW-W64](https://mingw-w64.org),
[Gnome's jhbuild](https://gnome.pages.gitlab.gnome.org/jhbuild/), and
[JRSoftware's Inno Setup](http://www.jrsoftware.org/isinfo.php). It is
what drives building the official All-in-One installers and what the
GnuCash core development team uses to create Microsoft Windows
development environments.

## Requirements

* Windows 10 or later. You must have an account with Administrator privileges.
* Powershell 3.0 or later.

## Installation

Download [setup-mingw.ps1](https://github.com/Gnucash/gnucash-on-windows/raw/refs/heads/master/setup-mingw64.ps1)

Start a Powershell session:
* Click the Start icon and start typing "powershell" until Windows recognizes it and presents a menu item. Click that.

If you need Administrative Privileges:
* Right-click on the Start icon and select ```Windows Powershell (Admin)```

If you don't routinely run PowerShell scripts on your computer you will need to first set the [Execution Policy](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-3.0) to **RemoteSigned**. You will need Powershell session with Administrative Privileges for this step:
1. Start Powershell with Admin Privileges
1. Run ```set-executionpolicy -executionpolicy RemoteSigned -scope LocalMachine```
1. Quit Powershell if you plan to run ```setup-mingw64.ps1``` without Administrative Privileges.

In a PowerShell session run ```path/to/setup-mingw64.ps1```; the path will depend on your browser settings but if you have a default setup then it's ```~/Downloads/setup-mingw64.ps1```.

### setup-mingw64 Options

```setup-mingw64.ps1``` takes four optional arguments:
* **-target_dir**: The full path to where the MinGW-W64 environment will be created. **Default**: ```C:\gcdev64```. The default requires Administrative privileges to create. If you use a directory in your home directory instead then you will not require Admin privileges.

* **-download_dir**: The name of the subdirectory in **target_dir** where source tarballs will be downloaded to. **Default**: **target_dir**```\downloads```.

* **-msys2_root**: The base directory of the MSYS2/MinGW-W64 environment. You can reuse an existing environment, but we don't recommend changing this. **Default**:**target_dir**```\msys2```.

* **-x86_64**: Setting this will build a 64-bit GnuCash. **Default**: Unset, for 32-bit builds able to run on very old systems. This is how we're currently building GnuCash distributions. The Mingw-w64 project is [dropping 32-bit builds of packages](https://www.msys2.org/news/#2023-12-13-starting-to-drop-some-32-bit-packages); they've already done for a few that GnuCash uses. `setup-mingw64.ps1` works around this.

It will take a while to complete. When it's done you'll have a new group in your Start Menu named ```MSYS2 64bit``` or ```MSYS2 32bit``` depending on the bitness of your version of Windows. Note that this is independent of whether you set the **-x86_64** option. In that group you'll find 3 selections:
* MSYS2 MSYS2
* MSYS2 MINGW32 (32-bit MSVCRT runtime, GCC Toolchain)
* MSYS2 MINGW64 (64-bit MSVCRT runtime, GCC Toolchain)
* MSYS2 CLANG64 (64-bit Universal runtime, Clang/LLVM Toolchain)
* MSYS2 UCRT64  (64-bit Universal runtime, GCC Toolchain)

These create terminal emulation sessions running the Bash shell with
the environment configured for different uses. GnuCash is tested only
with the MSVCRT runtime.

## Building GnuCash

1. Start an MSYS MinGW shell for the selected bitness.
1. Change directories to the installation directory ```cd /c/gcdev64/src/gnucash-on-windows.git```. Substitute the path if you set **-target_dir** to something else. Note that in this shell you'll use ```/c``` instead of ```C:``` for the drive letter.
1. run ```TARGET=gnucash-stable jhbuild -f jhbuildrc build``` to build the ```stable``` branch. Substitute ```gnucash-releases``` for ```gnucash-stable``` to build the latest release from the tarball. In the run-up to a major release there will be an unstable branch for beta testing; to build that use ```gnucash-unstable```. 

## Developing

Once you've built GnuCash all the way through you can get a build-and-run environment by starting a MinGW shell and running ```TARGET=gnucash-maint jhbuild -f jhbuildrc shell``` from the ```gnucash-on-windows.git``` directory.

```cd $PREFIX/../build/gnucash-git``` to get to the build directory and ```cd $PREFIX/../src/gnucash-git``` to get to the local repo.

To install the gdb debugger run ```pacman -S mingw-w64-<arch>-gdb```,
substituting `i686` or `x86_64` for `<arch>` depending on the MinGW
environment you're using. You need not be in a jhbuild shell.

## Bundling GnuCash

1. Start a Powershell session.
1. Change to the installation directory ```cd C:\gcdev64\src\gnucash-on-windows.git```
1. run
```
bundle-mingw64.ps1 -root_dir C:\gcdev64 -target_dir C:\gcdev64\gnucash\stable -package gnucash -git_build $true
```

That will create a date-stamped and versioned ```gnucash-xxx-setup.exe``` in ```C:\gcdev64\gnucash\stable```. You'll need to adjust paths and versions accordingly if you changed **target_dir** when you ran ```setup-mingw64.ps1```.

### bundle-mingw64.ps1 Parameters

All Parameters are required and have no defaults.
* **-root_dir** The root directory of the installation, corresponds to **target_dir** for ```setup-mingw64.ps1```.
* **-target_dir** The directory where the source, build, and installation directories are. This is normally **target_dir**```\gnucash\branch``` with branch being either ```master```, ```maint```, or ```release```.
* **-package**: The thing we're bundling. Always ```gnucash```.
* **-git_build**: ```$true``` if GnuCash was built from git, ```$false``` otherwise. Only use ```$false``` for release builds.

## Buildserver

This repository includes a script, ```buildserver\build_package.ps1``` that combines building and bundling GnuCash and uploading the result to a distribution webserver into a single command. It's intended for automated nightly build scripts.

### build_package.ps1 options
* **-branch**: ```maint```, ```master```, or ```release```. The last builds the release configured in gnucash.modules from the release tarball.
* **-target_dir**: The **target_dir** configured into ```setup-mingw64.ps1```.
* **-hostname**: The upload URI. Optional. If set the script will attempt to rsync the gnucash-xxx-setup.exe and the build log to hard-coded subdirectories under this URI. The user running the script must have correctly configured ssh to connect to the URI with a key; there's no provision for password authentication.

## Other files:
* ```jhbuildrc.in``` Template jhbuild configuration file, converted to ```jhbuildrc``` by ```setup-mingw64.ps1``` with the **target_dir**.
* ```gnucash.modules```: The jhbuild moduleset for building GnuCash.
* ```inno_setup/```: Configuration and localization files for building ```gnucash-xxx-setup.exe``` with Inno Setup.
* ```patches/```: Modifications to the source packages required to build in this environment.
* ```extra_dist/```: The Online Quote Installation tool.
* ```exetype.pl```: A perl script for converting the executable type of programs between Windowed and Console. It is sometimes useful to convert the GnuCash executable to Console type (it's built as Windowed) to capture some text output it emits before logging starts.
