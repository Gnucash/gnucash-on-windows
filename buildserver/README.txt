*- Buildserver -*
-----------------

The build server is a set of scripts written to allow
a Windows pc to repeatedly build the Gnucash
Windows installer starting from the GnuCash sources.

It is meant to set up some nightly builds system and is
currently configured to
- build the gnucash master (development)  branch
- build any new release tag
- optionally build the gnucash maint (stable) branch

Note: whether these scripts really run 'nightly' or at
      another interval depends on how the build server
      is configured (see below).


Setup
-----

Note: if you have already set up a gnucash build environment using
      bootstrap_win_dev.vbs and install.sh you can skip to step 5.

1. Download bootstrap_win_dev.vbs from the gnucash-on-windows
   repository on Github. Direct url:
   https://raw.githubusercontent.com/Gnucash/gnucash-on-windows/master/bootstrap_win_dev.vbs

2. Run this script by double-clicking it and follow the instructions.
   If the script's output window closes before you get to a "Happy hacking"
   message then something went wrong. To figure out what you can instead
   open a Windows command prompt (cmd.exe) and run the script as
   cscript.exe <path\to>\bootstrap_win_dev.vbs
   Be sure to replace <path\to> with the correct path.

Note: by default everything will be installed inside c:\gcdev\
      You could alter this location and some other paths by passing
      some parameters to bootstrap_win_dev.vbs. Which parameters exist can
      be read in the bootstrap script itself. You should take care however that
      mingw/msys and the gnucash-on-windows git repository will be installed
      where the build_periodic.bat script expects them. If not your buildserver
      will fail to work.

3. If this has run successfully open an msys (bash) console. Unless
   you have altered the default paths, you will find this in
   c:\gcdev\mingw\msys\1.0\msys.bat

4. Let's run the script to build gnucash and its dependencies once manually.
   This is mainly necessary to get html help installed which requires human
   interaction. To do so enter the following commands in msys:
   cd /c/gcdev/gnucash-on-windows.git
   ./install.sh

   You can interrupt install.sh after html help is installed if you like.

5. (Optional) The build server scripts have the option to upload the
   Gnucash Windows installer and build log to a remote server. For this
   to work it requires the scp.exe tool to be installed. To do so run
   this command in the msys console:
   mingw-get install msys-openssh

Note: the feature to upload the installer and log are currently still
      using some hard coded parameters:
      - it will only attempt to upload if the build machine is called
        'gnucash-win32'
      - it will always upload to code.gnucash.org:public_html/win32
        as user 'upload'
      So it's currently only useful on the primary build server.

6. The next step is to tell Windows to run the buildserver scripts at
   regular intervals. For this you can set up a "Scheduled Task" via
   the Windows Control Panel. Configure the task as follows:
   - Run: c:\gcdev\gnucash-on-windows.git\buildserver\build_periodic.bat
   - Start in: c:\gcdev\gnucash-on-windows.git
   - Choose a schedule. For nightly builds schedule it to run every day.
     You are free to select other intervals as you see fit.

7. Wait until the next scheduled time has passed and check how it went.
   Note that the first time the build can take a long time. The current
   primary build server takes about 5-6 hours. This is a virtual machine
   running Windows XP. While the build is still running you should see
   a windows console in which the build output is printed as the
   build proceeds. This window closes automatically when the build finishes.

   Upon a succesfull build you should find the newly created Gnucash
   Windows installer in c:\gcdev\output along with the build log.

   If that is not the case you can check the build log to learn what went
   wrong. If there is even no build log that means the build encountered
   an error pretty early in the process (before logging has started). To
   learn what this was you can open a Windows command prompt (cmd.exe) and
   manually run
   c:\gcdev\gnucash-on-windows.git\buildserver\build_periodic.bat
   That should give some indication of what is failing.
