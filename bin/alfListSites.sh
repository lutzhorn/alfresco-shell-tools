#!/bin/bash
#set -x
# param section

# source function library

ALFTOOLS_BIN=`dirname "$0"`
. $ALFTOOLS_BIN/alfToolsLib.sh


function __show_command_options() {
  echo "  command options:"
  echo "    -j    optional, switch to enable raw json output"
  echo "    -p    optional, dump also title and admins"
  echo
}

# intended to be replaced in command script
function __show_command_explanation() {
  echo "  command explanation:"
  echo "    the alfListSites.sh command lists all sites in Alfresco"
  echo
}


# command local options
ALF_CMD_OPTIONS="${ALF_GLOBAL_OPTIONS}jp"
ALF_JSON_OUTPUT=false
ALF_PW_OUTPUT=false

function __process_cmd_option() {
  local OPTNAME=$1
  local OPTARG=$2

  case $OPTNAME
  in
    j)
      ALF_JSON_OUTPUT=true;;
    p)
      ALF_PW_OUTPUT=true;;
  esac
}


__process_options $@

# shift away parsed args
shift $((OPTIND-1))

if $ALF_VERBOSE
then
  ALF_CURL_OPTS="$ALF_CURL_OPTS -v"
  echo "connection params:"
  echo "  user: $ALF_UID"
  echo "  endpoint: $ALF_EP"
  echo "  curl opts: $ALF_CURL_OPTS"
fi

curl $ALF_CURL_OPTS -u $ALF_UID:$ALF_PW "$ALF_EP/service/api/sites" |(
if $ALF_JSON_OUTPUT
then
	cat
else
	DATA=`cat`
	t=`echo "$DATA"|$ALF_JSHON -l`
	n=1
	while [ $n -le $t ]
	do
		DATAN=` echo "$DATA" | $ALF_JSHON -e $n`
		echo "$DATAN" |\
		$ALF_JSHON -e shortName -u -p -e title -u
		ADMIN=`echo "$DATAN" | $ALF_JSHON -e siteManagers`
	
		ta=`echo "$ADMIN" |$ALF_JSHON -l` 
		m=1
		while [ $m -le $ta ]
		do
			echo "$ADMIN" |$ALF_JSHON -e $m | tr \\012 ,
			m=`expr $m + 1`
		done
		echo

		n=`expr $n + 1`
	done | (
		while read site
		do
			read title
			read admins
			if $ALF_PW_OUTPUT
			then
				echo "$site:$title:$admins"
			else
				echo "$site"
			fi
		done
	) | sed -e 's/,$//'
fi
)
