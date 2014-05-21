rem This is the Windows Batch Script for the periodic builds.
rem It simply calls the actual MSYS Shell script to perform
rem the periodic build and then the tag builds.
rem Typically this is called from a timed command on Windows.
rem On the GnuCash build server this timed command is run daily which the comments below suggest.

cd c:\gcdev\gnucash-on-windows.git\

rem Development build (daily)
c:\gcdev\mingw\msys\1.0\bin\sh.exe --login c:\gcdev\gnucash-on-windows.git\buildserver\build_periodic.sh
rem Tags build for 2.6.99 and newer (daily -- only tags that weren't built yet)
c:\gcdev\mingw\msys\1.0\bin\sh.exe --login c:\gcdev\gnucash-on-windows.git\buildserver\build_tags.sh
rem maintenance branch build (weekly)
c:\gcdev-maint\mingw\msys\1.0\bin\sh.exe --login c:\gcdev-maint\gnucash-on-windows.git\buildserver\periodic_build.sh weekly