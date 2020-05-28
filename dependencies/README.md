MSYS2 Packaging sources for dependencies that we provide via pacman instead of
building every time with jhbuild.

To build you'll need a working MSYS2 environment including:
  base-devel
  msys2-devel
and one or both of
  mingw-w64-i686-toolchain
  mingw-w64-x86_64-toolchain
If you're building for download you should have both toolchains installed. Note when installing toolchains that you don't need the ada, fortran, or objective-c compilers.

Start an MSYS2 (not Mingw32/Mingw64!) shell and cd to the directory of the package you want to build. Edit PKGBUILD in that directory as needed for new versions and release number. Run
   makepkg-mingw -sCLf

If you want to build for only one architecture you can set MINGW_INSTALLS=mingw32 or MINGW_INSTALLS=mingw64 as appropriate.

More procedure details may be found at https://www.msys2.org/wiki/Creating-Packages.

If you're building packages for others to install with pacman then you'll need to sign the packages and put your public key in the repository so that others can download and install it to verify the packages you build. Instructions for setting this up are at https://www.msys2.org/wiki/Signing-packages.
