# Building GnuCash on Windows

This repository provides a simple, repeatable means to build and bundleGnuCash
on Microsoft Windows using
[MSYS2](https://www.msys2.org/)/[MinGW-W64](https://mingw-w64.org) and
[JRSoftware's Inno Setup](http://www.jrsoftware.org/isinfo.php). It is
what drives building the official All-in-One installers and what the
GnuCash core development team uses to create Microsoft Windows
development environments.

## Requirements

* Windows 11 or later. You must have an account with Administrator privileges.
* Powershell 3.0 or later.

## Installation

Download
[setup-mingw.ps1](https://github.com/Gnucash/gnucash-on-windows/raw/refs/heads/master/setup-mingw64.ps1)
and [setup-mingw.sh](https://github.com/Gnucash/gnucash-on-windows/raw/refs/heads/master/setup-mingw64.sh)

Start a Powershell session:
* Click the Start icon and start typing "powershell" until Windows recognizes it and presents a menu item. Click that.

If you need Administrative Privileges:
* Right-click on the Start icon and select ```Terminsl (Admin)```

If you don't routinely run PowerShell scripts on your computer you
will need to first set the [Execution
Policy](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-3.0)
to **RemoteSigned**. You will need a Powershell session with Administrative Privileges for this step:
1. Start Powershell with Admin Privileges
1. Run ```set-executionpolicy -executionpolicy RemoteSigned -scope LocalMachine```
1. Quit Powershell if you plan to run ```setup-mingw64.ps1``` without Administrative Privileges.

In a PowerShell session run ```path\to\setup-mingw64.ps1```; the path will depend on your browser settings but if you have a default setup then it's ```~\Downloads\setup-mingw64.ps1```.

### setup-mingw64 Options

```setup-mingw64.ps1``` takes four optional arguments:
* **-target_dir**: The full path to where the MinGW-W64 environment
  will be created. ```setup-mingw64.ps1``` needs to switch between
  itself and a bash shell under MSYS2 and paths with spaces don't work
  well so they're best avoided. **Default**: ```C:\gcdev64```. The
  default requires Administrative privileges to create. If you use a
  directory in your home directory instead then you will not require
  Admin privileges but Windows often creates home directory paths with
  spaces.

* **-mingw_arch**: One of the supported MSYS2 Intel architectures. We
  don't support Arm processors at this time. **Default**:ucrt64
* **-msys2_root**: The base directory of the MSYS2/MinGW-W64 environment. You can reuse an existing environment, but we don't recommend changing this. **Default**:**target_dir**```\msys2```.
* **-repo_dir**: Setup-mingw64 will download and install a private
  pacman repository for GnuCash dependencies that aren't supported in
  Mingw64. This option specifies the location of that repository. It
  should be an MSYS2 style path; Absolute paths that don't begin with
  a drive letter (e.g. /c/ for C:) are homed under
  **target_dir**/msys2. **Default**:**/mingw_arch**/repo.

```setup-mingw64.ps1``` will set up a full toolchain with all of
GnuCash's dependencies installed via MSYS2's
[pacman](https://man.archlinux.org/man/pacman.8.en) package manager
for the selected MinGW architecture. It will take a while to
complete. When it's done you'll have a new group in your Start Menu
named ```MSYS2 64bit``` Note that this is independent of the MinGW
architecture you selected. In that group you'll find 5 selections:

* MSYS2 MSYS2
* MSYS2 MINGW32 (32-bit MSVCRT runtime, GCC Toolchain)
* MSYS2 MINGW64 (64-bit MSVCRT runtime, GCC Toolchain)
* MSYS2 CLANG64 (64-bit Universal runtime, Clang/LLVM Toolchain)
* MSYS2 UCRT64  (64-bit Universal runtime, GCC Toolchain)

These create terminal emulation sessions running the Bash shell with
the environment configured for the specified MinGW architecture.

If you want to install toolchains and GnuCash dependencies for more
architectures open an MSYS2 terminal, define MINGW_ARCH with the
architectures you want, and run `setup-mingw64.sh``` (note
**sh**). For example
```
MINGW_ARCH="mingw32 mingw64" bash setup-mingw64.sh
```
will set up build environments for the msvcrt runtime in 32- and 64-bit.

## Building GnuCash
Either of these methods will produce a GnuCash executable that you can
run inside the respective Mingw terminal.
#### Git repository
1. Start an MSYS MinGW shell for the architecture you want to build.
2. Clone gnucash and optionally gnucash-docs:
   ```
   git clone https://github.com/gnucash/gnucash
   git clone https://github.com/gnucash/gnucash-docs
   ```
   You can start in any directory you like.
3. Make build directories. These can also be anywhere you like; one
   popular option is to make a hidden build directory in the source
   directory, e.g.
   ```
   mkdir gnucash.git/.build
   ```
4. Change to the build directory and run cmake and ninja as
   usual. `ninja test` is expected to pass all tests.
5. You can then run GnuCash in your terminal session with
   `bin/gnucash`. `ninja install` will install GnuCash to a unix-like
   tree in the directory specified to cmake's
   `CMAKE_INSTALL_PREFIX`.
#### PKGBUILD
Pkgbuild is the package build system for creating ```pacman```
packages. MSYS2 has made a variant for building MinGW packages called
`makepkg-mingw`. This way is able to build for more than one
architecture with a single invocation of `makepkg-mingw`.
1. Open an MSYS2 terminal.
2. Clone **this** repository:
   `git clone https://github.com/gnucash/gnucash-on-windows`
3. Change to the `packages/gnucash` directory
   ```
   cd gnucash-on-windows.git/packages/gnucash
   ```
4. Set the architectures you want in `MINGW_ARCH` and call
   `makepkg-mingw`. You can do so all on one line:
   ```
   MINGW_ARCH="mingw32 mingw64 clang64 ucrt64" makepkg-mingw
   ```
5. This creates packages for each specified architechture that you
   must install to be able to run:
   ```
   pacman -U ./mingw-w64-ucrt-x86_64-gnucash-5.14-1-any.tar.zst
   ```
## Developing

While you can work on GnuCash after using `pkgbuild-mingw` it's a bit
of a pain, so we recommend the `git clone` method.
To install the gdb debugger run
```
pacman -S mingw-w64-<arch>-gdb
```
where '<arch>' is the package specifier for the MinGW
architecture&mdash&it's `clang-x86_64` and `ucrt-x86_64` for `clang64'
and `ucrt64` respectively.


## Bundling GnuCash

This hasn't been worked out yet.
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
* **-hostname**: The upload URI. Optional. If set the script will
  attempt to rsync the gnucash-xxx-setup.exe and the build log to
  hard-coded subdirectories under this URI. The user running the
  script must have correctly configured ssh to connect to the URI with
  a key; there's no provision for password authentication.

## Buildsystem Maintenance

The `packages` directory contains project files for populating the
GnuCash pacman repositories, with a subdirectory for each dependency
library. Each of those directories contains at least a `PKGBUILD`
file; some include patches needed to build the library or for it to
run under MinGW.

These packages need to be updated periodically to remain up to date
and some need to be rebuilt frequently because their dependencies
aren't ABI or API stable. See the README in that directory for details.

## Other files:
* `inno_setup/`: Configuration and localization files for building ```gnucash-xxx-setup.exe` with Inno Setup.
* `extra_dist/`: The Online Quote Installation tool.
* `exetype.pl`: A perl script for converting the executable type of programs between Windowed and Console. It is sometimes useful to convert the GnuCash executable to Console type (it's built as Windowed) to capture some text output it emits before logging starts.
* `packages/` Directories for building GnuCash, GnuCash Docs, and the
  dependencies not supported by MSYS2.

