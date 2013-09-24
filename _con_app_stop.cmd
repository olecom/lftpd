@echo off
set CYGWIN=nodosfilewarning
set APPSTART=console
bin\sh.exe -c "/etc/init.d/lftp_rdir_syncd+.sh ./app.conf stop"
pause
