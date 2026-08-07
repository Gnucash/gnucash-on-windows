# Packaging GnuCash with pacman
This is a collection of MSYS2 packages needed to build GnuCash that
aren't supported by the MSYS2 project. Each directory contains a
PKGBUILD for the current version of the package included in the
GnuCash setup program for windows along with any patches needed to
build it. There are also packages to build GnuCash itself and its
documentation.

Since the MSYS2 project has deprecated the very old msvcrt-based
architectures mingw32 and mingw34 and has stopped building several
packages that GnuCash requires, the packages in this directory support
only the ucrt-based architectures ucrt64 and clang64. Building for
clang64-arm might work but hasn't yet been tested.

Once each package is built you must install it. To install it directly
run
```
pacman -U mingw-w64-ucrt-x86-64-foo-1.2-1.pkg.zst
```
substituting the actual package name and version for
`foo-1.2-1`. Alternatively you can make a local pacman repository and
add the packages to that with
[repo-add](https://man.archlinux.org/man/repo-add.8). Assuming that
you put the repo in `C:\gcdev64\repo\ucrt64` and named it `gnc-ucrt64`
then adding the following to the end of `/etc/pacman.conf` will make
the package available to pacman; building or installing other
packages that depend on it will install it.

    [gnc-ucrt64]
    SigLevel = Optional TrustAll
    Server = file:///c:/gcdev64/repo/ucrt64/
You must run

    pacman -Syu

to update pacman's in-memory database after each repository change.

### Building a package
Before you start you'll need to have installed some basic packages:

    pacman -S basic-devel git mingw-w64-ucrt-x86_64-toolchain

Repeating toolchain for each architecture you plan to build.

To build a package start an MSYS2 shell (NOT one of the architecture
shells!), enter its directory and issue

    MINGW_ARCH="ucrt64" makepkg-mingw -scLf --noconfirm

Substituting the architecture(s) you want to build for "ucrt64". You
of course must have set up the corresponding repository to supply the
package's dependencies; `makepkg-mingw` will take care of installing
anything you need.

You can install the package immediately after the build completes with e.g.

    pacman -U mingw-w64-ucrt-x86_64-foo.5.6.7-1-any.pkg.tar.zst

#### Adding the package to the repository

Copy or move the tarballs to the repo and add them to the repo database:

    cp mingw-w64-ucrt-x86_64-foo.5.6.7-1-any.pkg.tar.zst* /path/to/repo/
    repo-add -R --include-sigs /ucrt64/repo/gnc-ucrt64.db.tar.gz /ucrt64/repo/mingw-w64-ucrt-x86_64-foo.5.6.7-1-any.pkg.tar.zst

Refresh pacman's indexes so that it will install the package for the
packages that depend on it:

    pacman -Syu

### Maintenance:
* Periodically review the package versions and update `PKGCONFIG`
  accordingly.
* If you encounter build or runtime failures write a patch, add it to
  `PKGBUILD`, and commit both the patch and the updated `PKGBUILD`.

#### Dependency Tree:
* gnucash-docs
* gnucash
  * aqbanking
    * gwnhywfar
    * libchipcard
      * gwenhywfar
  * guile3
  * libdbi-drivers
    * libdbi
  * libofx
    * OpenSP
  * swig (We can't use the MSYS2 package because we need to patch the
    Guile module for Guile3)

Each `PKGBUILD` contains all of the dependemcies for its target, so
building each package in the list from the bottom up and adding it to
a repo should result in a ready to use or bundle GnuCash.

### PKGBUILD notes:
  * If you need to customize a particular build there are a couple of
  useful environment variables to test for in PKGBUILD:
  * CARCH reports the current architecture, viz. i686, x86_64, or
    arm64
  * MSYSTEM is the current MSYS2 environment, i.e. MINGW32, MINGW64,
    CLANG64, or UCRT64
  * MSYSTEM_PREFIX is the root directory for the MSYSTEM tree,
    e.g. /mingw32 for MINGW32.
  * The packages are configured to build debug symbols (`debug`) and
    separate them into debug packages (`strip`). makepkg-mingw's
    --sign parameter will sign only the debug packages. Leave it off
    and sign the packages separately as noted aboce.
  * The `-s`flag to makepkg tells it to use pacman to install the
    dependencies before building. pacman uses the sig files and the
    keychain to verify each file. If pacman declares a package invalid
    or corrupt it means that either the key wasn't in the keychain or
    the stored hash of the package file was wrong. It's dumb, so it
    might reject a valid package if one of that package's dependencies
    signature fails. Try running `pacman -Syyu` to update everything.

### Guile3
[Guile](https://codeberg.org/guile/guile) doesn't yet support
64-bit Windows because guile relies on `long` and `void*` being the
same type so the `PKGCONFIG` points to a
[fork](https://codeberg.org/jralls/guile) that does support it. The
Lilypond developers have taken a different approach and have proposed
PRs to complete it so we hope to be able to drop the fork and use
upstream at some point.

### Further Reading:
https://www.msys2.org/wiki/Creating-Packages/
https://www.msys2.org/wiki/Signing-packages/
https://www.msys2.org/docs/package-naming/#avoiding-writing-long-package-names
https://man.archlinux.org/man/pacman.8
https://man.archlinux.org/man/makepkg.8
https://man.archlinux.org/man/PKGBUILD.5
