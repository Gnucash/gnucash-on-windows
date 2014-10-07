[ "$__SOURCED_FUNCTIONS" ] && return
__SOURCED_FUNCTIONS=1

function set_default() {
    local _varname=$1; shift
    if [ -z "`eval echo '"$'"$_varname"'"'`" ]; then
        eval "$_varname"'="'"$*"'"'  #" help emacs on windows
    fi
}

function block_step() { blocked_steps=("${blocked_steps[@]}" "$@"); }
function reset_steps() { steps=(); blocked_steps=(); }
function add_step() {
    while [ "$1" ]; do
        _is_blocked=
        for blocked in "${blocked_steps[@]}"; do
            if [ "$blocked" = "$1" ]; then
                _is_blocked=yes
                break
            fi
        done
        if [ "$_is_blocked" != "yes" ]; then
            steps=("${steps[@]}" "$1")
            block_step "$1"
        fi
        shift
    done
}

function late_eval() { late_cmds=("${late_cmds[@]}" "$@"); }
function eval_now() {
    for cmd in "${late_cmds[@]}"; do
        eval $cmd
    done
}

function quiet() { "$@" &>/dev/null; }

# c:/dir/sub
function qpushd() { pushd "$@" >/dev/null; }
function qpopd() { popd >/dev/null; }
function win_fs_path() { echo "$*" | sed 's,\\,/,g'; }
function unix_path() { echo "$*" | sed 's,^\([A-Za-z]\):,/\1,;s,\\,/,g'; }

# usage:  wpwd [rel]
# rel can be any relative path
function wpwd() {
    qpushd `unix_path "${1:-.}"`
        pwd -W
    qpopd
}

# usage:  smart_wget URL DESTDIR [DESTFILE]
function smart_wget() {
    _FILE=`basename $1`
    # Remove url garbage from filename that would not be removed by wget
    _UFILE=${3:-${_FILE##*=}}
    _DLD=`unix_path $2`

    # If the file already exists in the download directory ($2)
    # then don't do anything.  But if it does NOT exist then
    # download the file to the tmpdir and then when that completes
    # move it to the dest dir.
    if [ ! -f $_DLD/$_UFILE ] ; then
    # If WGET_RATE is set (in bytes/sec), limit download bandwith
    if [ ! -z "$WGET_RATE" ] ; then
            wget --passive-ftp -c $1 -P $TMP_UDIR --limit-rate=$WGET_RATE $WGET_EXTRA_OPTIONS
        else
            wget --passive-ftp -c $1 -P $TMP_UDIR $WGET_EXTRA_OPTIONS
        fi
    mv $TMP_UDIR/$_FILE $_DLD/$_UFILE
    fi
    LAST_FILE=$_DLD/$_UFILE
}

# usage:  wget_unpacked URL DOWNLOAD_DIR UNPACK_DIR [DESTFILE]
function wget_unpacked() {
    smart_wget $1 $2 $4
    _EXTRACT_UDIR=`unix_path $3`
    _EXTRACT_SUBDIR=
    echo -n "Extracting $_UFILE ... "
    case $LAST_FILE in
        *.zip)
            unzip -q -o $LAST_FILE -d $_EXTRACT_UDIR
            _PACK_DIR=$(zipinfo -1 $LAST_FILE '*/*' 2>/dev/null | head -1)
            ;;
        *.tar.gz|*.tgz)
            tar -xzpf $LAST_FILE -C $_EXTRACT_UDIR
            _PACK_DIR=$(tar -ztf $LAST_FILE 2>/dev/null | head -1)
            ;;
        *.tar.bz2)
            tar -xjpf $LAST_FILE -C $_EXTRACT_UDIR
            _PACK_DIR=$(tar -jtf $LAST_FILE 2>/dev/null | head -1)
            ;;
         *.tar.xz)
             tar -xJpf $LAST_FILE -C $_EXTRACT_UDIR
             _PACK_DIR=$(tar -Jtf $LAST_FILE 2>/dev/null | head -1)
             ;;
        *.tar.lzma)
            lzma -dc $LAST_FILE |tar xpf - -C $_EXTRACT_UDIR
            _PACK_DIR=$(lzma -dc $LAST_FILE |tar -tf - 2>/dev/null | head -1)
            ;;
        *)
            die "Cannot unpack file $LAST_FILE!"
            ;;
    esac

    # Get the path where the files were actually unpacked
    # This can be a subdirectory of the requested directory, if the
    # tarball or zipfile contained a relative path.
    _PACK_DIR=$(echo "$_PACK_DIR" | sed 's,^\([^/]*\).*,\1,')
    if (( ${#_PACK_DIR} > 3 ))    # Skip the bin and lib directories from the test
    then
        _EXTRACT_SUBDIR=$(echo $_UFILE | sed "s,^\($_PACK_DIR\).*,/\1,;t;d")
    fi
    _EXTRACT_UDIR="$_EXTRACT_UDIR$_EXTRACT_SUBDIR"
    echo "done"
}

function setup() {
    echo
    echo "############################################################"
    echo "###  $*"
    echo "############################################################"
}

function die() {
    echo
    [ "$*" ] && echo "!!! $* !!!"
    echo "!!! ABORTING !!!"
    restore_msys
    exit -1
}

# usage: register_env_var NAME SEPARATOR [DEFAULT]
function register_env_var() {
    [ $# -ge 2 -a $# -le 3 ] || die hard
    eval "SEPS_$1"'="'"$2"'"'
    if [ $# -eq 3 ]; then
        eval "$1_BASE=$3"
    else
        eval "$1_BASE"'=$'"$1"
    fi
    eval "$1_ADDS="
    eval export "$1"
    ENV_VARS="$ENV_VARS $1"
}
ENV_VARS=

# usage: add_to_env VALUE NAME
function add_to_env() {
    _SEP=`eval echo '"$'"SEPS_$2"'"'`
    _ENV=`eval echo '"$'"$2"'"'`
    _SED=`eval echo '"s#.*'"${_SEP}$1${_SEP}"'.*##"'`
    _TEST=`echo "${_SEP}${_ENV}${_SEP}" | sed "${_SED}"`
    if [ "$_TEST" ]; then
        if [ "$_ENV" ]; then
            eval "$2_ADDS"'="'"$1${_SEP}"'$'"$2_ADDS"'"'
        else
            eval "$2_ADDS"'="'"$1"'"'
        fi
        eval "$2"'="$'"$2_ADDS"'$'"$2_BASE"'"'
    fi
}

# usage: set_env_or_die VALUE NAME
# like add_to_env, but die if $NAME has been set to a different value
function set_env_or_die() {
    _OLDADDS=`eval echo '"$'"$2_ADDS"'"'`
    add_to_env "$1" "$2"
    _NEWADDS=`eval echo '"$'"$2_ADDS"'"'`
    if [ "$_OLDADDS" != "$_NEWADDS" ]; then
        _BASE=`eval echo '"$'"$2_BASE"'"'`
        if [ "$_BASE" ]; then
            _ENV=`eval echo '"$'"$2"'"'`
            echo "Must not overwrite environment variable '$2' (${_OLDADDS}${_BASE}) by '$1'."
            echo "Try to remove the offending installed software or unset the variable."
            die
        fi
    fi
}

# usage set_env VALUE NAME
# like $NAME=$VALUE, but also reset env tracking variables
function set_env() {
    eval "$2=$1"
    eval "$2_BASE="
    eval "$2_ADDS=$1"
}

function assert_one_dir() {
    counted=$(ls -d "$@" 2>/dev/null | wc -l)
    if [[ $counted -eq 0 ]]; then
        die "Exactly one directory is required, but detected $counted; please check why $@ wasn't created"
    fi
    if [[ $counted -gt 1 ]]; then
        die "Exactly one directory is required, but detected $counted; please delete all but the latest one: $@"
    fi
}

function fix_pkgconfigprefix() {
        _PREFIX=$1
        shift
        perl -pi.bak -e"s!^prefix=.*\$!prefix=$_PREFIX!" $@
   qpopd
}

function dos2unix() {
       perl -pi.bak -e"s!\\r\\n\$!\\n!" $@
}

function configure_msys() {
    # Make sure msys will be using this mingw
    SUFFIX=$1
    _MINGW_WFSDIR=$2
    echo "configuring msys to use $_MINGW_WFSDIR."
    touch /etc/fstab
    cp /etc/fstab /etc/fstab.$SUFFIX
    sed '\,/mingw$, d' /etc/fstab > tmp
    echo "$_MINGW_WFSDIR /mingw" >> tmp
    mv tmp /etc/fstab
}

function restore_msys() {
    SUFFIX=$1
    if [ -f /ect/fstab.$SUFFIX ]; then
      echo "resetting msys to use original mingw."
      rm /etc/fstab
      mv /etc/fstab.$SUFFIX /etc/fstab
    fi
}

function mingw_smart_get () {
    PACKAGE=$1
    VERSION=$2

    # Check if a sensible package name has been given
    [ "$PACKAGE" ] || return

    _MINGW_UDIR=`unix_path $MINGW_DIR`

    # Check if a package has already been installed or not. This is
    # a workaround for mingw-get's unfortunate refusal to upgrade a
    # package when calling mingw-get install on an already installed one
    # or mingw-get upgrade on a package that's not installed

    # Note: awk is used below instead of grep, because the tests
    #       can return without a result. Grep exists with a non-zero
    #       exit value in that case, which will cause the script to
    #       abort (due to set -e being set). Awk does not.
    # Note: mingw-get is deliberately called without a fixed path
    #       this allows the install and dist scripts to use
    #       different versions of the tool (or more precisely different
    #       configurations for the tool).

    COMPONENTS="$(mingw-get show "$PACKAGE" | awk '/Components:/')"
    if [ -n "$COMPONENTS" ]
    then
        # This package has subcomponents, we need to test
        # the install status of the subcomponents instead
        # Since we call mingw-get on the general package name
        # all subcomponents normally get installed together
        # so testing for only one subcomponent should be sufficient
        # This assumption may lead to a situation where manulal
        # intervention is needed in case of errors during mingw-get calls
        # Let's hope that such errors are the exception
        COMPONENT="${COMPONENTS#Components: }"
        COMPONENT="${COMPONENT%%,*}"
        SUBPACKAGE="$PACKAGE-$COMPONENT"
    else
        SUBPACKAGE="$PACKAGE"
    fi

    INSTVERSION="$(mingw-get show "$SUBPACKAGE" | awk '/Installed Version:/')"
    INSTVERSION="${INSTVERSION#Installed Version:  }"
    REPOVERSION="$(mingw-get show "$SUBPACKAGE" | awk '/Repository Version:/')"
    REPOVERSION="${REPOVERSION#Repository Version: }"

    # If a version string is given add add it to the package name
    [ -n "$VERSION" ] && PACKAGE="${PACKAGE}=${VERSION}"

    if [ -z "$INSTVERSION" ]
    then
        # Unknown package
        die "Package $PACKAGE is unknown by mingw."
    elif [ "$INSTVERSION" == "none" ]
    then
        # Package not yet installed
        mingw-get install ${PACKAGE}
    elif [ -n "$VERSION" ] && [ -z "$(echo "$INSTVERSION" | awk "/$VERSION/")" ]
    then
        # Requested version differs from installed version
        mingw-get upgrade ${PACKAGE}
    elif [ -z "$VERSION" ] && [ "$INSTVERSION" != "$REPOVERSION" ]
    then
        # No version requested, but installed version differs from version in repo
        mingw-get upgrade ${PACKAGE}
    else
        echo "Package $PACKAGE is up to date"
    fi
}

# Take a version number in the form M.m.µ-b
# and return the major (M) and minor (m) component in numeric form
# as follows: major*100 + minor
# for example: 2.4.8-1 would yield 204
# If the version entered is not a version in the expected format
# 0 will be returned.
function get_major_minor () {
  local version=${1//[!0-9.-]/}

  local -i version_major=${version%%.*}
  local version_tmp=${version#*.}
  local -i version_minor=${version_tmp%%.*}
  major_minor=$(( $version_major*100 + $version_minor ))
}

### Local Variables: ***
### mode: shell-script ***
### sh-basic-offset: 4 ***
### indent-tabs-mode: nil ***
### End: ***
