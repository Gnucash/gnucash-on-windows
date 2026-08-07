function make-pkgnames()
{
    prefix=$1
    pkgnames=""
    shift
    while (( "$#" )) do
          pkgnames+="$prefix$1 "
          shift
    done
}

function make-unix-path()
{
    unix_path=$(echo "$1" | tr \\\\ / | sed -r 's%^([a-zA-Z]):%/\1%')
}

function build-packages()
{
    # Build and install the dependency packages not supported by the MSYS2 project.
    # Dependency order; each line is independant
    # 1. gwenhywfar, libchipcard, aqbanking
    # 2. guile3
    # 3. libdbi, libdbi-drivers
    # 4. OpenSP, libofx
    # 5. swig. Note: We need to build our own Swig because we must patch it for Guile3
    # Each package build will install the package's built dependencies from pacman repos

    MINGW_ARCH=$1
    for pkg in gwenhywfar libchipcard aqbanking guile3 libdbi libdbi-drivers OpenSP libofx swig; do
        pushd packages/$pkg
        makepkg-mingw -sCLf --noconfirm
        for f in mingw-w64-*.pkg.tar.zst; do
            pacman -U --nocofirm $f
        done
        popd
    done
}

function install-group()
{
    mingw_prefix=$1
    group="$2"
    echo $group
    for dep in $group; do
        pacman -S --noconfirm "$mingw_prefix-$dep"
    done
}

function install-deps()
{
    mingw_prefix="mingw-w64-$1"
    toolchain="binutils cmake crt gcc gdb headers libmangle libtool libwinpthread ninja tools winpthreads winstorecompat"
    deps="appstream-glib boost docbook-xsl gettext-tools gtest harfbuzz-icu icu iso-codes pdcurses libsecret webview2-loader zlib"
    our_repo_deps="aqbanking guile3 libdbi-drivers libofx swig"

    install-group $mingw_prefix "$toolchain"
    install-group $mingw_prefix "$deps"
    install-group $mingw_prefix "$our_repo_deps"
}

sed -i 's/^# ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

pacman -Syu --noconfirm

make-pkgnames  "msys/" base-devel git
msys_devel=$pkgnames
pacman -S $msys_devel --noconfirm --needed

if [ "x$MINGW_ARCH" == "x" ]; then
    MINGW_ARCH="ucrt64"
fi

# We maintain a repository as a rolling release in GitHub for ucrt64 so we use that if we can, otherwise we build everything for the selected architecture.
for arch in $MINGW_ARCH; do
    case $arch in
        clang64)
            build-packages $arch
            ;;
        ucrt64)
            arch_repo=$(grep gnc-$arch /etc/pacman.conf)
            if [ -z "$arch_repo" ]; then
              sed -i "/^# SigLevel = Never/a [gnc-$arch]\nSigLevel = Optional TrustAll\nServer = https://github.com/jralls/gnucash-on-windows/releases/download/gnc-ucrt64-repo/\n" /etc/pacman.conf
            fi
            pacman -Sy --noconfirm
            install-deps "ucrt-x86_64"
            ;;
        *)
            echo "unsupported MINGW architecture $arch"
            ;;
    esac
done
exit
