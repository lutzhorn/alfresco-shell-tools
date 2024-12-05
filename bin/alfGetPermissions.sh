#!/bin/bash

# Tue May 23 13:12:49 CEST 2017
# spd@daphne.cps.unizar.es

# Script to get permissions for a workspace/SpacesStore node
# Status: working against alfresco-5.1.e with CSRF protection enabled (default)

# Requires alfToolsLib.sh
# Requires jshon

# param section

# source function library

ALFTOOLS_BIN=`dirname "$0"`
. $ALFTOOLS_BIN/alfToolsLib.sh

# intended to be replaced in command script by a command specific output
function __show_command_options() {
  echo "  command options:"
  echo "    -s SHORT_NAME , the sites short name"
  echo "    -i id         , node id"
  echo "    -n path       , file/folder full name"
  echo "    -t            , terse output (direct entries, name:role)"
  echo
}

# intended to be replaced in command script
function __show_command_arguments() {
  echo "  command arguments:"
  echo "    NONE"
  echo
}

# intended to be replaced in command script
function __show_command_explanation() {
  echo "  command explanation:"
  echo "    the alfGetPermissions.sh command get permisions for a node."
  echo
  echo "  usage examples:"
  echo
  echo "    alfGetPermissions.sh -i d79695df-d5fe-4a43-853d-9d92de1290fd"
  echo "    alfGetPermissions.sh -s My_Site -n Foo/Bar"
  echo
  
}


# command local options
ALF_CMD_OPTIONS="${ALF_GLOBAL_OPTIONS}s:i:n:t"
ALF_SITE_SHORT_NAME=""
ALF_FILE_NAME=""
ALF_NODE_ID=""
ALF_TERSE=false


function __process_cmd_option() {
  local OPTNAME=$1
  local OPTARG=$2

  case $OPTNAME
  in
    s)
      ALF_SITE_SHORT_NAME=$OPTARG;;
    i)
      ALF_NODE_ID="$OPTARG";;
    n)
      ALF_FILE_NAME="$OPTARG";;
    t)
      ALF_TERSE=true;;
  esac
}

__process_options "$@"

# shift away parsed args
shift $((OPTIND-1))

# command arguments,

if $ALF_VERBOSE
then
  ALF_CURL_OPTS="$ALF_CURL_OPTS -v"
  cat >&2 <<-EOF
  connection params:
    user:            $ALF_UID
    endpoint:        $ALF_EP
    curl opts:       $ALF_CURL_OPTS
    site short name: $ALF_SITE_SHORT_NAME
    file name:       $ALF_FILE_NAME
EOF
fi

if $ALF_TERSE
then
	filter()
	{
	DATA="$1"

	t=`echo "$DATA"|$ALF_JSHON -e direct -l`
	n=1
	( while [ $n -le $t ]
	do
		echo "$DATA" |\
		$ALF_JSHON -e direct \
			-e $n -e authority -e name -u -p -p -e role -u
		n=`expr $n + 1`
	done ) | while read u
	do
		read r
		echo "$u:$r"
	done
	}

else
	filter()
	{
		echo "$1"
	}
fi


ALF_SERVER=`echo "$ALF_SHARE_EP" | sed -e 's,/share,,'`

if [ "_$ALF_SITE_SHORT_NAME" != "_" ]
then
	#
	# I got random failures using alfresco/service/slingshot/search API
	# so we'll use CMIS API here
	#
	#ALF_NODE_ID=`alfPath2NodeRef.sh "/app:company_home/st:sites/cm:${ALF_SITE_SHORT_NAME}/cm:documentLibrary/cm:${ALF_FILE_NAME}" | sed -e 's,://,/,'`

	URL=$ALF_SERVER/alfresco/api/-default-/public/cmis/versions
	URL=${URL}/1.1/browser/root/Sites/${ALF_SITE_SHORT_NAME}
	URL=${URL}/documentLibrary/${ALF_FILE_NAME}?cmisSelector=object

	ALF_NODE_ID=`curl $ALF_CURL_OPTS \
	-u"$ALFTOOLS_USER:$ALFTOOLS_PASSWORD" \
	"${URL}" | $ALF_JSHON -e properties -e cmis:objectId -e value -u`
	ALF_NODE_ID="workspace/SpacesStore/${ALF_NODE_ID}"

else
	ALF_NODE_ID="workspace/SpacesStore/${ALF_NODE_ID}"
fi

if $ALF_VERBOSE
then
	echo "    node id:         $ALF_NODE_ID" >&2
fi

ALF_PATH="alfresco/s/slingshot/doclib/permissions/${ALF_NODE_ID}"



OUTPUT=`curl $ALF_CURL_OPTS \
-u"$ALFTOOLS_USER:$ALFTOOLS_PASSWORD" \
$ALF_SERVER/$ALF_PATH`

filter "$OUTPUT"


# on success the server returns json describing permissions


exit $?

