#!/bin/sh
# set -x
# param section

# This version: Tue Mar 24 11:29:20 CET 2020
# spd@daphne.cps.unizar.es

# Script to get list of active sessions for a site
# Status: working

# Requires alfToolsLib.sh
# Requires jshon
# Requires recode
# Requires ootbee-support-tools installed on server
# https://github.com/OrderOfTheBee/ootbee-support-tools/

# source function library

ALFTOOLS_BIN=`dirname "$0"`
. $ALFTOOLS_BIN/alfToolsLib.sh

function __show_command_options() {
	echo "  command options:"
	echo "    -t optional, terse output. Default raw json output"
	echo "    -n print total number of sessions only"
	echo
}

# intended to be replaced in command script
function __show_command_explanation() {
  echo "  command explanation:"
  echo "    alfWho.sh lists active sessions"
  echo
}

# command local options
ALF_CMD_OPTIONS="${ALF_GLOBAL_OPTIONS}nt"
ALF_SITE_SHORT_NAME=""
ALF_TERSE=false
ALF_NUMBER=false

function __process_cmd_option() {
  local OPTNAME=$1
  local OPTARG=$2

  case $OPTNAME
  in
    n)
      ALF_NUMBER=true;;
    t)
      ALF_TERSE=true;;
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
else
  ALF_CURL_OPTS="$ALF_CURL_OPTS -s"
fi


if $ALF_TERSE
then
	filter()
	{
		DATA="$1"
		count=`echo "$DATA"| jshon -e users -l`

		if $ALF_NUMBER
		then
			echo $count
		else
			n=0
			(
				while [ $n -lt $count ]
				do
					echo "$DATA" |\
						jshon -Q \
							-e users -e $n \
							-e userName -u -p \
							-e firstName -u -p \
							-e lastName -u -p \
							-e email -u
					n=`expr $n + 1`
				done
			) | ( while read user
			do
				read fn
				read ln
				read email
				echo "$user:$email:$fn $ln"
			done 
			) | recode --force utf8..ascii
		fi
	}

else
	filter()
	{
		DATA="$1"
		count=`echo "$DATA"| jshon -e users -l`

		if $ALF_NUMBER
		then
			echo "#### Total active sessions: $count"
		else
			echo "$1"
		fi
	}
fi


OUTPUT=`curl \
	-s -u "$ALF_UID":"$ALF_PW" \
	$ALF_EP/s/ootbee/admin/active-sessions/users`

filter "$OUTPUT"

exit $?



