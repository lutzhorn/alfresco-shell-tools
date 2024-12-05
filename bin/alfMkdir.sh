#!/bin/bash

# Mon May 18 11:09:01 CEST 2020
# spd@daphne.cps.unizar.es

# Script to create a folder
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
  echo "    -d PARENT     , parent folder name"
  echo "    -N FOLDER     , folder name"
  echo "    -T TITLE      , folder title"
  echo "    -D DESC       , folder description"
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
  echo "    the alfMkdir.sh command creates a folder."
  echo
  echo "  usage examples:"
  echo
  echo "  ./alfMkdir.sh -s my_site -d \"Parent Directory\" -n \"Foo Bar\""
  echo
  
}


# command local options
ALF_CMD_OPTIONS="${ALF_GLOBAL_OPTIONS}s:d:N:T:D:"
ALF_SITE_SHORT_NAME=""
ALF_FOLDER_NAME=""
ALF_PARENT_NAME=""
ALF_FOLDER_TITLE=""
ALF_FOLDER_DESC=""


function __process_cmd_option() {
  local OPTNAME=$1
  local OPTARG=$2

  case $OPTNAME
  in
    s)
      ALF_SITE_SHORT_NAME=$OPTARG;;
    d)
      ALF_PARENT_NAME="$OPTARG";;
    N)
      ALF_FOLDER_NAME="$OPTARG";;
    T)
      ALF_FOLDER_TITLE="$OPTARG";;
    D)
      ALF_FOLDER_DESC="$OPTARG";;
  esac
}

__process_options "$@"

# shift away parsed args
shift $((OPTIND-1))

# command arguments,

if $ALF_VERBOSE
then
  ALF_CURL_OPTS="$ALF_CURL_OPTS -v"
  echo "connection params:"
  echo "  user: $ALF_UID"
  echo "  endpoint: $ALF_EP"
  echo "  curl opts: $ALF_CURL_OPTS"
  echo "  site short name: $ALF_SITE_SHORT_NAME"
  echo "  parent folder: $ALF_PARENT_NAME"
fi


ALF_PATH="alfresco/s/api/site/folder/$ALF_SITE_SHORT_NAME/documentLibrary"

if [ "_$ALF_PARENT_NAME" != "_" ]
then
	ALF_PATH="$ALF_PATH/$ALF_PARENT_NAME"
fi

ALF_SERVER=`echo "$ALF_SHARE_EP" | sed -e 's,/share,,'`


# craft json body
ALF_JSON=`echo '{}' |\
$ALF_JSHON \
-s "$ALF_FOLDER_NAME" -i name \
-s "$ALF_FOLDER_TITLE" -i title \
-s "$ALF_FOLDER_DESC" -i description \
-s "cm:folder" -i type`

if $ALF_VERBOSE
then
	echo "$ALF_JSON"
fi

echo "$ALF_JSON" |\
curl $ALF_CURL_OPTS \
-u"$ALFTOOLS_USER:$ALFTOOLS_PASSWORD" \
-H "Content-Type: application/json; charset=UTF-8" \
-d@- -X POST \
$ALF_SERVER/$ALF_PATH 2>&1


# on success the server returns something like:
#
#{
# "nodeRef": "workspace://SpacesStore/760ccc23-9dc2-46ec-bed1-378310e05609",
# "site": "S-Comision",
# "container": "documentLibrary",
#}

exit $?

