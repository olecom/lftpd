#exec 2>put_debug	
set -e -x
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
done >rename_remote_norm.lftp

