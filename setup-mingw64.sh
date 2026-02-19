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

sed -i 's/^# ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
echo "" > /etc/pacman.d/gnucash-ignores.pacman
sed -i 's/^\[options\]/\[options\]\nInclude = \/etc\/pacman.d\/gnucash-ignores.pacman\n/' /etc/pacman.conf

make-unix-path "$USERPROFILE/Downloads"
downloads_dir=$unix_path
signing_keyfile="jralls_public_signing_key.asc"
keyfile_path="$downloads_dir/$signing_keyfile"
key_id="C1F4DE993CF5835F"
pacman-key --add "$keyfile_path"
pacman-key --lsign-key  "$key_id"

pacman -Syu --noconfirm

toolchain="binutils cmake crt gcc gdb headers libmangle libtool libwinpthread ninja tools winpthreads winstorecompat"
deps="appstream-glib boost docbook-xsl gettext-tools gtest icu pdcurses swig zlib"
our_repo_deps="aqbanking guile3 libdbi-drivers libofx webkitgtk3"

make-pkgnames  "msys/" base-devel git
msys_devel=$pkgnames
pacman -S $msys_devel --noconfirm --needed

if [ "x$MINGW_ARCH" == "x" ]; then
    MINGW_ARCH="ucrt64"
fi
for arch in $MINGW_ARCH; do
    case $arch in
        mingw32)
            mingw_arch_code=i686
            ;;
        mingw64)
            mingw_arch_code=x86_64
            ;;
        clang64)
            mingw_arch_code=clang-x86_64
            ;;
        ucrt64)
            mingw_arch_code=ucrt-x86_64
            ;;
        *)
            echo "unsupported MINGW architecture $arch"
            mingw_arch_code=
            ;;
    esac
    sed -i "/^# SigLevel = Never/a [gnc-$arch]\nSigLevel = Optional TrustAll\nServer = file:///$arch/repo/\n" /etc/pacman.conf
    pacman -Sy --noconfirm
    mingw_arch_long="mingw-w64-$mingw_arch_code"
    mingw_prefix="$mingw_arch_long-"

    for _deps in "$toolchain" "$deps" "$our_repo_deps"; do
        make-pkgnames $mingw_prefix $_deps
        pacman -S $pkgnames --noconfirm --needed
    done
done
gpgconf --homedir /etc/pacman.d/gnupg --kill all
exit
