lftpd
=====

The transportation daemon based on `lftp` - Sophisticated file transfer program.

Purpose
======
Two systems e.g. ERP inside the private office network and E-Commerce Shop on the Internet must exchange information.
* Let’s send plain text (XML, JSON, CSV, etc) files back and forth
* Let’s ERP be *master* and Internet Shop be *slave*. I.e. master has transportation program on its side. Slave has file transfer service (ftpd, sftpd or http) on its side. Thus local network (through all possible NATs, proxies, etc) can be simply connected via internet service of the slave.

Thus two systems are connected in such a way that any files being put into master’s local directory by *master* are transferred to the slave (local income). Any files being put into slave’s local (master’s remote) directory are transferred to the master’s income local directory.

Events of incoming data for both systems are non empty local income directories. Successful transfer can be signaled by some external tools or by periodic check for files in corresponded directories by systems themselves.

Internal structure of transferred information is due of agreement of ERP and Shop developers.

All files are guaranteed to be available in whole. Any network problems, continuation of upload or download are handled by `lftp`.

Any of available protocols in `lftp` can be used: ftp, ftps, http, https, hftp, fish, sftp and file.
