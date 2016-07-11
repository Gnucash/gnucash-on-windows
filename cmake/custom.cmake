# Note: All directories must be without spaces!
#
# set (REPOS_URL "git@github.com:Gnucash/gnucash.git")
# set (SF_MIRROR "http://switch.dl.sourceforge.net/sourceforge")
# set (DISABLE_OPTIMIZATIONS yes)
set (GLOBAL_DIR /c/gcdev)  # all directories will use this
# set (WGET_RATE 50k)         #limit download bandwith to 50KB/s
# set (NO_SAVE_PROFILE yes)   # don't save env settings to /etc/profile.d
# set (QTDIR c:/Qt/4.2.3)
# set (CROSS_COMPILE yes)
#EXTRA_CFLAGS="-fno-builtin-dgettext -fno-builtin-towupper -fno-builtin-iswlower"
set (GLOBAL_BUILD_DIR /c/gcdev)
set (MINGW_DIR=${GLOBAL_BUILD_DIR}/mingw)
set (MSYS_DIR ${MINGW_DIR}/msys/1.0)
set (TMP_DIR c:/gcdev/tmp)
set (DOWNLOAD_DIR=${GLOBAL_DIR}/downloads)
set (GIT_DIR ${GLOBAL_DIR}/git-1.9.4)
set (REPOS_TYPE git)
set (GC_WIN_REPOS_URL ssh://code.gnucash.org/gnucash-on-windows)
set (GC_WIN_REPOS_DIR ${GLOBAL_BUILD_DIR}/gnucash-on-windows)
set (REPOS_URL ssh://code.gnucash.org/gnucash)
set (REPOS_DIR ${GLOBAL_BUILD_DIR}/gnucash.git)

