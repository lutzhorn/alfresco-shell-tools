#!/bin/bash

# Thu Jul 13 10:27:02 CEST 2017
# spd@daphne.cps.unizar.es

# Script to get users for a site
# Status: working against alfresco-5.1.e with CSRF protection enabled (default)

# Requires alfToolsLib.sh
# Requires jshon

# param section

# source function library

ALFTOOLS_BIN=`dirname "$0"`
. $ALFTOOLS_BIN/alfToolsLib.sh

function __show_command_options() {
  echo "  command options:"
  echo "    -s SHORT_NAME , the sites short name"
  echo "    -t    optional, terse output. Default raw json output"
  echo
}



# intended to be replaced in command script
function __show_command_explanation() {
  echo "  command explanation:"
  echo "    alfListUsersSite.sh lists all user names"
  echo "    for a given alfresco site one in a row"
  echo
}

# command local options
ALF_CMD_OPTIONS="${ALF_GLOBAL_OPTIONS}s:t"
ALF_SITE_SHORT_NAME=""
ALF_TERSE=false

function __process_cmd_option() {
  local OPTNAME=$1
  local OPTARG=$2

  case $OPTNAME
  in
    s)
      ALF_SITE_SHORT_NAME=$OPTARG;;
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
fi


if $ALF_TERSE
then
	filter()
	{
	DATA="$1"

	t=`echo "$DATA"|$ALF_JSHON -l`
	n=1
	( while [ $n -le $t ]
	do
		echo "$DATA" |\
		$ALF_JSHON \
			-e $n -e authority -e fullName -u
		n=`expr $n + 1`
	done ) | while read u
	do
		echo "$u"
	done
	}

else
	filter()
	{
		echo "$1"
	}
fi


OUTPUT=`curl $ALF_CURL_OPTS -u $ALF_UID:$ALF_PW "$ALF_EP/service/api/sites/$ALF_SITE_SHORT_NAME/memberships"`

filter "$OUTPUT"

exit $?

