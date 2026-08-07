# Building GnuCash on Windows

This repository provides a simple, repeatable means to build and
bundle GnuCash
on Microsoft Windows using
[MSYS2](https://www.msys2.org/)/[MinGW-W64](https://mingw-w64.org) and
[JRSoftware's Inno Setup](http://www.jrsoftware.org/isinfo.php). It is
what drives building the official All-in-One installers and what the
GnuCash core development team uses to create Microsoft Windows
development environments.

## MSYS2 Project
GnuCash is written as a Unix project and depends on a IEEE 1003
("POSIX") C runtime. Microsoft Windows's C runtimes are not IEEE 1003
compliant so we need a shim layer to manage
that. [MSYS2](https://msys2.org/)based on
[cygwin](https://cygwin.com) and the original [Mingw
project](https://sourceforge.net/projects/mingw/) (Minimalist GNU for
Windows) is  a widely-used runtime shim that we use for this
purpose. The original Mingw and the two Mingw-w64 MSYS2 architectures
`mingw32` and `mingw64` were based on the Microsoft msvcrt C runtime
dating back to the early 1990s. Microsoft released a new Universl C
Runtime, or UCRT, in 2015 for Windows 10. MSYS2's `ucrt64`, `clang64`,
and `clang64-arm` depend on this newer runtime and MSYS2 has
deprecated the older msvcrt-based architectures and is rapidly
dropping supported packages from them. Consequently this version of
GnuCash-on-Windows supports only the newer UCRT architectures.

Note that at present we're building only ucrt64 on github so if you
want to use one of the clang architectures you'll need to build and
install all of the packages in the package directory locally.

## Requirements

* Windows 11 or later is supported though we're not doign anything
  that directly precludes using Windows 10. You will need  an account
  with Administrator privileges to use the default working directory.
* Powershell 5.1 (included with Windows 10 and 11) or later.

## Installation

Download
[setup-mingw.ps1](https://github.com/Gnucash/gnucash-on-windows/raw/refs/heads/master/setup-mingw64.ps1)
and [setup-mingw.sh](https://github.com/Gnucash/gnucash-on-windows/raw/refs/heads/master/setup-mingw64.sh)

Start a Powershell session:
* Right-click on the Start icon and select ```Terminal``` or ```Terminsl
(Admin)``` depending on whether you need admin privilege for the session.

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
  Admin privileges but beware that Windows often creates home
  directory paths with spaces.

* **-mingw_arch**: One of the supported MSYS2 Intel architectures,
  `ucrt64`  and `clang64`. **Default**:ucrt64
* **-msys2_root**: The base directory of the MSYS2/MinGW-W64 environment. You can reuse an existing environment, but we don't recommend changing this. **Default**:**target_dir**```\msys2```.

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
architectures open an MSYS2 (**NOT a shell for the architecture
type!**) terminal, define MINGW_ARCH with the
architectures you want, and run ```setup-mingw64.sh``` (note
**sh**). For example
```
MINGW_ARCH="ucrt64 clang64" bash setup-mingw64.sh
```
will set up build environments for the UCRT runtime with the gcc and
clang toolchains.

If HTML Help Workshop isn't installed, setup-mingw64.ps1 will install
it for you. The installer will raise several approval dialogs, it's OK
to accept the defaults on all of them. HTML Help Workshop is required
to compile the documentation on Windows.

## Building GnuCash
Either of these methods will produce a GnuCash executable that you can
run inside the respective Mingw terminal.
#### Git repository or source tarball
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
   `CMAKE_INSTALL_PREFIX`. You will need to do this if you intend to
   bundle GnuCash (see Bundling Gnucash below),

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
4. Set the architectures you want in `MINGW_ARCH`, the build type you
   want in `GNUCASH_BUILD` (see packages/gnucash/PKGBUILD for possible
   values; note that only `future` will work until GnuCash 6.0 is
   released) and call `makepkg-mingw -sCLf --nodeps`. You can do so
   all on one line:

   ```
   MINGW_ARCH="ucrt64" GNUCASH_BUILD=future makepkg-mingw -sCLf --nodeps
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

Just run `bundle-mingw64.ps1` with the following options.

### bundle-mingw64.ps1 Parameters

All Parameters are required and have no defaults.
* **-mingw_prefix** The path to the mingw arch root, default c:\gcdev64\msys2\ucrt64.
* **-gnc_build_dir** The path to the GnuCash build directory, used to
  retrieve version information. Default is c:\gcdev64\gnucash-build
* **-prefix**: The path provided to CMAKE_INSTALL_PREFIX when
  configuring GnuCash and GnuCash-Docs. The installer program will be
  written here.
* **-git_build**: ```$true``` if GnuCash was built from git,
  ```$false``` otherwise. Only use ```$false``` for release
  builds. Default ```$true```.

Note that we need to copy the message catalogs we need out of
`$mingw_prefix\share\locale` to the corresponding directories in
`$prefix\share\locale` to prevent installing a bunch of extraneous
catalogs so using the same directory for both prefixes won't work well
and that precludes building GnuCash with its `PKGBUILD` because that
would install into `$mingw_prefix`.

## Buildsystem Maintenance

The `packages` directory contains project files for building the
GnuCash dependencies that MSYS2 doesn't package, with a subdirectory
for each dependency library. Each of those directories contains at
least a `PKGBUILD` file; some include patches needed to build the
library or for it to run under MinGW.

These packages need to be updated periodically to remain up to
date. There are GitHub workflows on this project that maintains a
pacman repository of the dependencies at
https://github.com/gnucash/gnucash-on-windows/releases/download/gnc-ucrt64-repo/.
You can use this repository instead of building and installing the
packages yourself by making the following changes to
`/etc/pacman.conf` in your MSYS2 installation:
* Find the line
```
# SigLevel = Never
```
and replace it with
```
[gnc-ucrt64]
SigLevel = Optional TrustAll
Server = "https://github.com/gmucash/gnucash-on-windows/releases/download/gnc-ucrt64-repo/"
```
## Other files:
* `inno_setup/`: Configuration and localization files for building ```gnucash-xxx-setup.exe` with Inno Setup.
* `extra_dist/`: The Online Quote Installation tool.
* `exetype.pl`: A perl script for converting the executable type of programs between Windowed and Console. It is sometimes useful to convert the GnuCash executable to Console type (it's built as Windowed) to capture some text output it emits before logging starts.
* `packages/` Directories for building GnuCash, GnuCash Docs, and the
  dependencies not supported by MSYS2.

