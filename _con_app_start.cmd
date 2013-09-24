@echo off
set CYGWIN=nodosfilewarning
set APPSTART=console
cmd /K bin\sh.exe -c "/etc/init.d/lftp_rdir_syncd+.sh ./app.conf start"
pause
