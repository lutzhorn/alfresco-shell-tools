#!/bin/bash

# Tue Jul 18 10:16:15 CEST 2017
# Changes: Use jshon instead of awk
# Changes: Detect locked users
# Changes: Unlock users
# spd@daphne.cps.unizar.es

# Script to invite user to alfresco site.
# Status: Working against alfresco-5.1.e with CSRF protection enabled (default)
# Verified with external users.
# Verified with existing users.

# Requires alfGetUser.sh, alfToolsLib.sh
# Requires jshon

# param section

# source function library

ALFTOOLS_BIN=`dirname "$0"`
. $ALFTOOLS_BIN/alfToolsLib.sh

# intended to be replaced in command script by a command specific output
function __show_command_options() {
  echo "  command options:"
  echo "    -s SHORT_NAME , the sites short name"
  echo "    -f FIRST_NAME , first name"
  echo "    -l LAST_NAME  , last name"
  echo "    -m MAIL       , e-mail"
  echo "    -r ROLE       , Collaborator|Consumer|Contributor|Manager"
  echo "    -F            , force invitation and unlock account"
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
  echo "    the alfInviteUser.sh command let you invite a user to a site."
  echo
  echo "  usage examples:"
  echo
  echo "  ./alfInviteUser.sh -s my_site -f Lothar -l Maerkle -m lm@example.com -r Collaborator"
  echo
  
}


# command local options
ALF_CMD_OPTIONS="${ALF_GLOBAL_OPTIONS}s:f:l:m:r:F"
ALF_SITE_SHORT_NAME=""
ALF_USER_FIRST_NAME=""
ALF_USER_LAST_NAME=""
ALF_USER_MAIL=""
ALF_USER_ROLE=""
ALF_FORCE=false


function __process_cmd_option() {
  local OPTNAME=$1
  local OPTARG=$2

  case $OPTNAME
  in
    s)
      ALF_SITE_SHORT_NAME=$OPTARG;;
    f)
      ALF_USER_FIRST_NAME="$OPTARG";;
    l)
      ALF_USER_LAST_NAME="$OPTARG";;
    m)
      ALF_USER_MAIL=$OPTARG;;
    r)
      ALF_USER_ROLE="Site$OPTARG";;
    F)
      ALF_FORCE=: ;;
  esac
}

__process_options "$@"

# shift away parsed args
shift $((OPTIND-1))

# command arguments,

case "_${ALF_USER_ROLE}" in
	_SiteCollaborator|_SiteConsumer|_SiteContributor|_SiteManager)
		:
		;;
	*)
		echo "ERROR: Incorrect role $ALF_USER_ROLE" >&2
		__show_command_options
		exit 1
		;;
esac

if $ALF_VERBOSE
then
  ALF_CURL_OPTS="$ALF_CURL_OPTS -v"
  echo "connection params:"
  echo "  user: $ALF_UID"
  echo "  endpoint: $ALF_EP"
  echo "  curl opts: $ALF_CURL_OPTS"
  echo "  user: $ALF_USER_FIRST_NAME $ALF_USER_LAST_NAME <${ALF_USER_MAIL}>"
  echo "  role: $ALF_USER_ROLE"
  echo "  site short name: $ALF_SITE_SHORT_NAME"
fi

#
# First should we tell if this is an existing user
#

ALF_USERNAME=`echo "${ALF_USER_MAIL}" | sed -e 's/@.*//'`
ALF_EUSER=`$ALFTOOLS_BIN/alfGetUser.sh ${ALF_USERNAME} 2>/dev/null`

if [ $? -eq 0 ]
then
	# Existing user
	echo "Existing user ${ALF_USERNAME}"
	ALF_USER="${ALF_USERNAME}"
	#ALF_USER_FIRST_NAME=`echo "$ALF_EUSER" |\
	#	awk -F\" '/^[ 	]*"firstName":/ {print $4}'`
	#ALF_USER_LAST_NAME=`echo "$ALF_EUSER" |\
	#	awk -F\" '/^[ 	]*"lastName":/ {print $4}'`

	ALF_USER_FIRST_NAME=`echo "$ALF_EUSER" | $ALF_JSHON -e firstName -u`
	ALF_USER_LAST_NAME=`echo "$ALF_EUSER" | $ALF_JSHON -e lastName -u`

	echo "user:${ALF_USERNAME}:${ALF_USER_FIRST_NAME}:${ALF_USER_LAST_NAME}:${ALF_USER_MAIL}"

	#ALF_LOCKED=`echo "$ALF_EUSER" |\
	#	awk -F'[ :,]' '/^[ 	]*"enabled":/ {print $3}'`

	ALF_LOCKED=`echo "$ALF_EUSER" | $ALF_JSHON -e enabled -u`
		
	if [ _"$ALF_LOCKED" = "_false" ]	
	then
		if $ALF_FORCE
		then
			echo "#### WARNING: ${ALF_USERNAME} exists but is locked" >&2
			alfUpdateUser.sh -a false -n ${ALF_USERNAME}
		else
			echo "#### ERROR: ${ALF_USERNAME} exists but is locked" >&2
			exit 1
		fi
	fi

else
	# Invite new user
	echo " New user ${ALF_USERNAME}"
	ALF_USER=""
fi

# get a valid share session id
__get_share_session_id
#ALF_SESSIONID=`echo "$ALF_SHARE_SESSIONID" | tr -d ' '`
ALF_SESSIONID="$ALF_SHARE_SESSIONID"


# craft json body
ALF_JSON=`echo '{}' |\
$ALF_JSHON \
-s "NOMINATED" -i invitationType \
-s "${ALF_USER}" -i inviteeUserName \
-s "${ALF_USER_ROLE}" -i inviteeRoleName \
-s "${ALF_USER_FIRST_NAME}" -i inviteeFirstName \
-s "${ALF_USER_LAST_NAME}" -i inviteeLastName \
-s "${ALF_USER_MAIL}" -i inviteeEmail \
-s "${ALF_SHARE_EP}/" -i serverPath \
-s "page/accept-invite" -i acceptURL \
-s "page/reject-invite" -i rejectURL`


ALF_CSRF=`curl $ALF_CURL_OPTS -v \
-H "Content-Type: application/json; charset=UTF-8" \
-e $ALF_SHARE_EP/page/site/${ALF_SITE_SHORT_NAME}/add-users \
--cookie JSESSIONID="$ALF_SESSIONID" \
$ALF_SHARE_EP/page/site/${ALF_SITE_SHORT_NAME}/add-users 2>&1 |\
sed -e '/Set-Cookie.*Alfresco-CSRFToken/!d' -e 's/^.*Token=//' -e 's/; .*//g'`


ALF_CSRF_DECODED=`echo "$ALF_CSRF" | __htd`

ALF_SERVER=`echo "$ALF_SHARE_EP" | sed -e 's,/share,,'`

echo "$ALF_JSON" |\
curl $ALF_CURL_OPTS \
-H "Content-Type: application/json; charset=UTF-8" \
-H "Alfresco-CSRFToken: $ALF_CSRF_DECODED" \
-e $ALF_SHARE_EP/page/site/${ALF_SITE_SHORT_NAME}/add-users \
--cookie JSESSIONID="${ALF_SESSIONID};Alfresco-CSRFToken=$ALF_CSRF" \
-d@- \
-X POST \
$ALF_SERVER/share/proxy/alfresco/api/sites/${ALF_SITE_SHORT_NAME}/invitations \
> /dev/null


exit $?

