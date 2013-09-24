#!/bin/sh
#нелья копировать и запускать с папками не на латинке!!!
# v000 2012-07-10,11,12 `lftpd` a kind of master<->slave file sync daemon
# v001 2012-07-12 testing loop

set -e
#exec 1>>"log" 2>&1 && set -x && echo "$*" #debug

[ "$*" -a "$2" ] || { echo "
Usage: $0"' file.conf [&|] { start, stop, stat }
   (script, config file,     commands)
Managing of `lftpd` remote directories sync daemon under "cygwin" or "linux-gnu" OSes
'
exit 77
}

trap 'echo "
Unexpected Script Error! Use /bin/sh -x $0 to trace it.
"
set +e
trap "" 0
exit 0
' 0

_err() {
printf '%b' '\033[0;1;41m[error] '"$*"'\033[0;40m
' >&2
#exit
}

[ -e "$1" ] || {
_err "No Config file $1 is there."
exit 1
}

_exit() {
trap "" 0
exit "$1"
}

case "$OSTYPE" in
*cygwin*) # OSTYPE=cygwin in `bash`
	LD_LIBRARY_PATH='/bin:/bin.w32'
	PATH="/bin:/bin.w32:$PATH"
	_start(){
	cmd /C start "$@"
	}
;;
*linux_gnu* | *)
	OSTYPE=linux-gnu
	LD_LIBRARY_PATH="/usr/local/bin:$LD_LIBRARY_PATH"
	case "$PATH" in
	  *"/usr/local/bin"*) ;;
	  *) PATH="/usr/local/bin:$PATH" ;;
	esac
	_start(){
	"$@"
	}
;;
esac

# including config here; make \r\n -> \n trasformation
sed 's/\r//g' "$1" >"$1".cr
/bin/sh -c ". ${1}.cr"
. "${1}.cr"
rm -f "${1}.cr"
APP_CFG=$1
shift 1
#

export PATH LD_LIBRARY_PATH

_date() { # ISO date
date -u '+%Y-%m-%dT%H:%M:%SZ'
}

_con(){
printf "$@" >&7
}

[ 'console' = "$APPSTART" ] && { echo "
Managing daemon under \"$OSTYPE\"..."
CHB='\033[1m'
CHE='\033[0m'
CB='\033[0;1;41m'
CE='\033[0;40m'
}
[ -d "$APPLOGS" ] || {
	mkdir -p "$APPLOGS"
	[ 'console' = "$APPSTART" ] && echo "Created logs dir: $APPLOGS"
}

#### ====  main sync stuff ==== ####
do_sync(){
set +e
SPWD=$PWD
trap "echo 'unexpected script error' > error
	rm -f ../pid.$APP
" 0
trap "
set +e
trap '' 0
rm -f \"${SPWD}pid.$APP\"
_con 'Teminating \`lftpd\`
'
exit 0" 0
	[ -d "$DDIR" ] || mkdir -p "$DDIR"

	_lftpd(){
#$1 -- 2's power = number of connections; $2 -- 'local' if upsync
#debug 777 -o debug.txt
		opt='
set cmd:interactive false
set net:timeout 4
set cmd:long-running 4
set net:max-retries 4
set net:reconnect-interval-base 4
set net:reconnect-interval-multiplier 1
set xfer:disk-full-fatal true
set xfer:clobber on'
		if [ 'local' = "$2" ]
		then con="
repeat --until-ok -d $SYNCTIME put -E go && echo put_ok
rm go
!sh ../etc/rename_files_pre.sh $DATAEXT $PREEXT || exit
mput -c -E *$DATAEXT$PREEXT
source rename_remote_norm.lftp
!rm rename_remote_norm.lftp
"
echo '#exec 2>put_debug
set -e -x
{
for f in *$1
do case $f in
	"*"*) # no DATAEXT files, list DATAEXT PREEXT prefixed, if any
		for f in *$1$2
		do  case $f in
			"*"*) exit 1;;
			*) echo "mv $f ${f%$2}";;
			esac
		done
		exit
	;;
	*)	mv "$f" "$f$2"
		echo "mv $f$2 $f"
	;;
	esac
done
[ -e og ] || echo loop>og
echo "put og;!rm og"
}>rename_remote_norm.lftp
'>'../etc/rename_files_pre.sh'
		else con="
repeat --until-ok -d $SYNCTIME get -c og && echo get_ok
!rm og
repeat --until-ok -d $SYNCTIME mget -c -E *$DATAEXT
rm og
!sh ../../etc/run.sh $LAPP
" #  ;   DDIR=$IDIR !!testing
#!sh start\ ../../_start_stop_status.wsf
#!sh $LAPP
		fi
		i=$1
		while [ "$i" -gt 0 ] # a kind of keep alive
		do i=$(($i-1)) ; con=$con$con
		done
		while [ -e "${SPWD}pid.$APP" ] && sleep 1
		do lftp -e "$opt$con" -u "$RDIRLOGIN" "$RDIRHOSTN$DDIR" || _con "lftp error code: $?
"
		done 1>&2 #!debug
	}
	cd "$DDIR" && _con "cd $DDIR
"
	_lftpd 4 local & # local to remote `mput`
	cd "$SPWD"
	cd "$IDIR" && _con "cd $IDIR
"
	#set -x +e || : debug
	_lftpd 4 & # remote to local `mget`
	while sleep 77
	do echo "running $2" # just keep pid.$APP active
	done
}
##### ==== start stop manager ==== ####
while [ "$*" ] # run one `app` per config
do if [ 'console' = "$APPSTART" ]
then exec   8>>"$APPLOGS/${APP}.log" 7>&1
	_con 7>&8 "
@[`_date`] console cmd=$1 app=$APP
"
else case "$1" in
 'stat') exec 7>/dev/null 8>&7 ;;
 *) exec 7>>"$APPLOGS/${APP}.log" 8>&7 ;;
 esac
fi
	_con "
@[`_date`] cmd=$1 app=$APP "
	case "$1" in
'start')# =========
     _con "is starting...
"
	[ -f "pid.$APP" ] && {
		[ 'console' == "$APPSTART" ] || _exit 2
		_err "
pid.$APP file is here, must 'stop' process first
"
		_con "stop and start(y/n)?"
		read YES && {
			[ 'y' == "$YES" ] && {
				set -- '' 'stop' "$@"
			} || {
				_con "
cancel '$1'
"
				_exit 0
			}
		} || _exit 2
	} || {
		do_sync 1>&7 2>&8 8>&- &
		CHPID=$!
		echo "$CHPID" >"pid.$APP"
		_con "$CHB
$CHPID is pid of running daemon, saved in file: pid.$APP$CHE

${CB}Окно не закрывать до выполнения 'stop'a!!!$CE
"
	}
;;
'stop')# =========

	[ -f "pid.$APP" ] || {
		[ 'console' == "$APPSTART" ] || _exit 3
		_err "

No file pid.$APP found, nothing to 'stop', clearing 'lftp' anyway.
"
		opt=`ps -W -s | sed -n '
/lftp[[:blank:]]*$/s/^[[:blank:]]*\([[:digit:]]*\).*$/\1/p
'`
		if [ "$opt" ]
		then _con "lftp to kill: $opt
"
			while [ -e "$DDIR/go" -o -e "$IDIR/og" ]
			do _con "
waitng for 'go' to be done
" && sleep 1
			done
			kill -TERM -- $opt || :
		fi
		_exit 3
	}
	read CHPID < "pid.$APP" && rm -f "pid.$APP"

	if [ 'console' = "$APPSTART" ]
	then _con "\033[1m
Hey!
About to kill pid.$APP=$CHPID, continue (y/n)? \033[0m"
		read YES || _exit 4
	else YES='y'
	fi
	if [ 'y' == "$YES" ]
	then kill $CHPID || :
		opt=`ps -W -s | sed -n '
/lftp[[:blank:]]*$/s/^[[:blank:]]*\([[:digit:]]*\).*$/\1/p
'`
		if [ "$opt" ]
		then _con "lftp to kill: $opt
"
			while [ -e "$DDIR/go" -o -e "$IDIR/og" ]
			do _con "
waitng for 'go' and 'og' to be done
" && sleep 1
			done
			kill -TERM -- $opt || :
		fi
	else _exit 0
	fi
;;
'stat')# =========
	_con "
"
[ -f "pid.$APP" ] && {
	read CHPID < "pid.$APP" && {
		kill -0 "$CHPID" && {
			 _con "
$CHPID is running OK

"
		} || _exit 5
	} || _exit 6
} || _exit 7
;;# =========
'tailog' | 'devstart')# =========
_con "not implemented
"
_exit 11
;;# =========
	esac
exec 7>&- 8>&-

shift 1
done # while "$*"
exec 1>&- 2>&-
_exit 0

# lftp_rdir_syncd+.sh ends here #
olecom
