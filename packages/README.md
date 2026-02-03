# Packaging GnuCash with pacman
This is a collection of MSYS2 packages needed to build GnuCash that
aren't supported by the MSYS2 project. Each directory contains a
PKGBUILD for the current version of the package included in the
GnuCash setup program for windows along with any patches needed to
build it. These packages are used to build a private pacman repository
for each of the 4 Intel architectures supported by MSYS2,
i.e. mingw32, mingw64, clang64, and ucrt64.

Sourceforge's file service is too slow to support hosting the
repositories directly there so instead we make a tarball of each
repository and store that [there](https://download.sourceforge.net/project/gnucash/Dependencies/). Unless you want to build all of the
packages from scratch you'll need to download one or more of those
tarballs and unpack it somewhere. Where doesn't really matter; for the
rest of this document we'll assume that you picked
/$MSYSTEM_PREFIX/repo and that MSYS2 is installed in c:/gcdev64/msys2.

The repositories and their contents are signed and the current
maintainer's gpg public key is stored with the tarballs. The current
maintainer's key is jralls_public_signing_key.asc. Download it and in
an MSYS2 shell run

    pacman-key --add jralls_public_signing_key.asc
    pacman-key --lsign-key C1F4DE993CF5835F


After installing one of the repositories you need to tell pacman to
use it so add the following to c:/gcdev64/msys2/etc/pacman.conf:

    [gnc-ucrt64]
    SigLevel = Optional TrustAll
    Server = file:///c:/gcdev64/repo/ucrt64/

Replacing `ucrt64` with the architecture you want to build and
adjusting the URL to match where you installed it. You'll
need a separate entry for each architecture. Put them before the MSYS2
repository entries so that our packages will take precedence over
MSYS2's as there are a couple of cases where we are building otherwise
supported packages with different options or patches. Once the
repositories and signing key are set up tell pacman about them by
running

    pacman -Syu

You'll also need to have installed some basic packages:

    pacman -S basic-devel git mingw-w64-ucrt-x86_64-toolchain

Repeating toolchain for each architecture you plan to build.

### Building a package
To build a package start an MSYS2 shell (NOT one of the architecture
shells!), enter its directory and issue

    MINGW_ARCH="ucrt64" makepkg-mingw -scLf

Substituting the architecture(s) you want to build for "ucrt64". You
of course must have set up the corresponding repository to supply the
package's dependencies; `makepkg-mingw` will take care of installing
anything you need.

You can install the package immediately after the build completes with e.g.

    pacman -U mingw-w64-ucrt-x86_64-foo.5.6.7-1-any.pkg.tar.zst

### Repository Maintenance

In order to maintain the repository you need to be able to sign
packages and the repository indexes, and for that you need a GPG
signing key. [Instructions](https://www.msys2.org/wiki/Signing-packages/).

#### Adding the package to the repository

Sign the package tarball:

    gpg --detach-sign --no-armor mingw-w64-ucrt-x86_64-foo.5.6.7-1-any.pkg.tar.zst

Or if you want to sign several, perhaps because you built more than
one architecture and had debug and strip enabled so that you have
debug tarballs too:

    for i in *.zst; do gpg --detach-sign --no-armor $i; done

Copy or move them to the repo and add them to the repo database:

    cp mingw-w64-ucrt-x86_64-foo.5.6.7-1-any.pkg.tar.zst* /ucrt64/repo/
    repo-add -R --include-sigs /ucrt64/repo/gnc-mingw.db.tar.gz /ucrt64/repo/mingw-w64-ucrt-x86_64-foo.5.6.7-1-any.pkg.tar.zst

Re-sign the database files:

    pushd /ucrt64/repo
    for i in gnc-mingw.db gnc-mingw.files gnc-mingw.db.tar.zst gnc-mingw.files.tar.zst; do rm $i.sig; gpg --detach-sign --no-armor $i; done
    popd

Refresh pacman's indexes so that it will install the package for the
packages that depend on it:

    pacman -Syu

Finally make a tarball and upload it to SourceForge:

    cd /ucrt64/repo
    tar --zstd -cf ../gnc-ucrt64-repo.tar.zst *

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

### Further Reading:
https://www.msys2.org/wiki/Creating-Packages/
https://www.msys2.org/wiki/Signing-packages/
https://www.msys2.org/docs/package-naming/#avoiding-writing-long-package-names
https://man.archlinux.org/man/pacman.8
https://man.archlinux.org/man/makepkg.8
https://man.archlinux.org/man/PKGBUILD.5
