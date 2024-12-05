#!/bin/bash

# Fri May 12 15:03:43 CEST 2017
# spd@daphne.cps.unizar.es

# Script to set permissions for a workspace/SpacesStore node
# Status: working against alfresco-5.1.e with CSRF protection enabled (default)

# Note: By now this script won't duplicate an existing permission, but
# also won't replace or delete existing ones.
# TODO: add options to edit/delete permissions.

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
  echo "    -n path       , file/folder full name"
  echo "    -i id         , node id"
  echo
}

# intended to be replaced in command script
function __show_command_arguments() {
  echo "  command arguments:"
  echo "    user:role [user:role]..."
  echo
}

# intended to be replaced in command script
function __show_command_explanation() {
  echo "  command explanation:"
  echo "    the alfSetPermissions.sh command set permisions for a node."
  echo
  echo "  usage examples:"
  echo
  echo "  ./alfSetPermissions.sh -i \"d79695df-d5fe-4a43-853d-9d92de1290fd\" user1:SiteConsumer user2:SiteManager"
  echo "  ./alfSetPermissions.sh -s My_Site -n Foo/Bar user1:SiteConsumer user2:SiteManager"
  echo
  
}


# command local options
ALF_CMD_OPTIONS="${ALF_GLOBAL_OPTIONS}s:i:n:"
ALF_SITE_SHORT_NAME=""
ALF_FILE_NAME=""
ALF_NODE_ID=""


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
    path name:       $ALF_FILE_NAME
EOF
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
	"${URL}" 2>/dev/null |\
	$ALF_JSHON -e properties -e cmis:objectId -e value -u 2>/dev/null`

	if [ "_$ALF_NODE_ID" = "_" ]
	then
		echo "#### ERROR: Non-existing path" >&2
		exit 2
	fi
	ALF_NODE_ID="workspace/SpacesStore/${ALF_NODE_ID}"

else
	ALF_NODE_ID="workspace/SpacesStore/${ALF_NODE_ID}"
fi

if $ALF_VERBOSE
then
  echo "  node id: $ALF_NODE_ID" >&2
fi

ALF_PATH="alfresco/s/slingshot/doclib/permissions/${ALF_NODE_ID}"




ALF_JSON=`echo '{}' | $ALF_JSHON -n false -i isInherited -n '[]' -i permissions`

for arg in $@
do
	user=`echo $arg | sed -e 's/:.*//'`
	role=`echo $arg | sed -e 's/.*://'`

ALF_JSON=`echo "$ALF_JSON" |\
	$ALF_JSHON -e permissions \
	-n "{}" \
	-s "$user" -i "authority" \
	-s "$role" -i "role" \
	-n "true" -i "remove" \
	-i append -p |\
	$ALF_JSHON -e permissions \
	-n "{}" \
	-s "$user" -i "authority" \
	-s "$role" -i "role" \
	-i append -p`
done


echo "$ALF_JSON" |\
curl $ALF_CURL_OPTS \
-u"$ALFTOOLS_USER:$ALFTOOLS_PASSWORD" \
-H 'Content-Type:application/json' \
-d@- -X POST \
$ALF_SERVER/$ALF_PATH 2>&1


# on success the server returns json describing permissions


exit $?

