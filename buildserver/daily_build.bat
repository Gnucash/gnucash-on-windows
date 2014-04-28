rem This is the Windows Batch Script for the daily builds.
rem It simply calls the actual MSYS Shell script to perform
rem the daily build and then the tag builds.

cd c:\gcdev\gnucash-on-windows.git\

rem Development build (daily)
c:\gcdev\mingw\msys\1.0\bin\sh.exe --login c:\gcdev\gnucash-on-windows.git\buildserver\daily_build.sh
rem Tags build for 2.6.99 and newer (daily -- only tags that weren't built yet)
c:\gcdev\mingw\msys\1.0\bin\sh.exe --login c:\gcdev\gnucash-on-windows.git\buildserver\build_tags.sh
rem maintenance branch build (weekly)
rem c:\gcdev-maint\mingw\msys\1.0\bin\sh.exe --login c:\gcdev-maint\gnucash-on-windows.git\buildserver\weekly_build.sh