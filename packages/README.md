# Packaging GnuCash with pacman
This is a collection of MSYS2 packages needed to build GnuCash that aren't supported by the MSYS2 project.
#### Building a package by hand
To build a package enter its directory and issue

    MINGW_ARCH="mingw32 mingw64 clang64 ucrt64" makepkg-mingw -scLf

if you have a GPG signature set up you can

    run gpg --detach-sign --no-armor *.tar.zst

Building packages that have dependencies from this set requires that you build and install the dependencies first. You can use `pacman -U` but that can get tedious; instead you can set up a local repository. For the examples below we'll use /c/gcdev64/repo, so make that directory and edit /etc/pacman.conf to add the following snippet at the bottom:

    [gnc-mingw]
    SigLevel = Optional TrustAll
    Server = file:///c:/gcdev64/repo/

* Now build your first package, one that has no dependencies from this set of packages, say bdwgc. After you've built it you'll have a bunch of files with names like `mingw-w64-xxx-bdwgc-vvvv.tar.zst` and `mingw-w64-xxx-bdwgc-vvvv.tar.zst.sig`. 'xxx' stands for the various architectures and vvvv stands for the bdwgc version. Move them to the repo directory:

    mv mingw*bdwgc*.tar.zst* /c/gcdev64/repo

* Add them to the repo database:

    repo-add /c/gcdev64/repo/gnc-mingw.db.tar.gz /c/gcdev64/repo/*bdwgc*.zst

* Re-sign the database files:

    pushd /c/gcdev64/repo
    for i in gnc-mingw.db gnc-mingw.files gnc-mingw.db.tar.zst gnc-mingw.files.tar.zst; do rm $i.sig; gpg --detach-sign --no-armor $i; done
    popd

* Refresh pacman's indexes so that it will install the package for the
packages that depend on it:

    pacman -Sy

Now you can proceed to build packages that depend on bdwgc. After
building each package copy the package files and signatures to `repo`,
run `repo-add` (specifying the new files), re-sign the repo database
and update pacman's indexes..

###### PKGBUILD notes:
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
