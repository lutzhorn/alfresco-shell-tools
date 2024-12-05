#!/bin/bash
#set -x

# Thu May  3 12:41:18 CEST 2018
# spd@daphne.cps.unizar.es
# Delete a user from a given site. Tested only against Alfresco 5.2

# param section

# source function library

ALFTOOLS_BIN=`dirname "$0"`
. $ALFTOOLS_BIN/alfToolsLib.sh

# intended to be replaced in command script by a command specific output
function __show_command_options() {
  echo "  command options:"
  echo "    no command specific options"

}

# intended to be replaced in command script
function __show_command_arguments() {
  echo "  command arguments:"
  echo "    ALF_USER_ID       the unique user name of an Alfresco user. Use - to read the user id from stdin."
  echo "    SHORT_NAME        the sites short name".
}

# intended to be replaced in command script
function __show_command_explanation() {
  echo "  command explanation:"
  echo "    the alfDeleteUserFromSite.sh command deletes a user from Alfresco"
  echo
  echo "  usage examples:"
  echo
  echo "  ./alfDeleteUserFromSite.sh someuserid somesite"
  echo "     --> deletes the user 'someuserid' from 'somesite'"
  echo
  echo
}


# command local options

__process_options $@

# shift away parsed args
shift $((OPTIND-1))

# command arguments, read first line from stdin if argument is -
ALF_USER_DEL=$1
if [[ "$ALF_USER_DEL" == "-" ]]
then
  read line
  ALF_USER_DEL=$line
fi

SHORT_NAME=$2
if [[ "_$SHORT_NAME" == "_" ]]
then
  __show_command_explanation
  exit 1
fi

ALF_SERVER=`echo "$ALF_SHARE_EP" | sed -e 's,/share,,'`
ALF_SITE_SHORT_NAME=$SHORT_NAME

if $ALF_VERBOSE
then
  ALF_CURL_OPTS="$ALF_CURL_OPTS -v"
  echo "connection params:"
  echo "  user: $ALF_UID"
  echo "  endpoint: $ALF_EP"
  echo "  curl opts: $ALF_CURL_OPTS"
  echo "  alf user: $ALF_USER_DEL"
fi

if [[ "$ALF_USER_DEL" == "" ]]
then
  echo "missing alfresco user id"
  exit 1
fi


__encode_url_param $ALF_USER_DEL
ENC_UID=$ENCODED_PARAM

#URL="${ALF_EP}/service/api/people/${ENC_UID}/sites/${SHORT_NAME}"
URL=${ALF_SERVER}/alfresco/api/-default-/public/alfresco/versions/1
URL=${URL}/sites/${SHORT_NAME}/members/${ENC_UID}

curl $ALF_CURL_OPTS -u $ALF_UID:$ALF_PW -X DELETE "$URL"

