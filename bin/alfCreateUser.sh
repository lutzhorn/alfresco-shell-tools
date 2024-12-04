#!/bin/bash
# set -x

# Wed Dec  4 10:46:12 CET 2024
# Changes: CSRF
# spd@daphne.cps.unizar.es
# Script to create local users in alfresco.
# Status: Working against alfresco-5.1.e with CSRF protection enabled (default)

# param section

# source function library

ALFTOOLS_BIN=`dirname "$0"`
. $ALFTOOLS_BIN/alfToolsLib.sh

function __show_command_options() {
  echo "  command options:"
  echo "    -n UNAME      , user name"
  echo "    -p PASS       , Users password"
  echo "    -f FIRST_NAME , Users first name"
  echo "    -l LAST_NAME  , Users last name"
  echo "    -e MAIL       , Users e-mail"
  echo "    -g GROUP      , A group name this user will become a member of."
  echo "                    Can occur multiple times"
  echo 
}

# intended to be replaced in command script
function __show_command_explanation() {
  echo "  command explanation:"
  echo "    the alfCreateUser.sh creates a local user in Alfresco."
  echo "    It returns a JSON dump of the newly created user object"
  echo
  echo "  usage examples:"
  echo
  echo "  ./alfCreateUser.sh \\"
  echo "     -n lothar -p pw123 \\"
  echo "     -f Lothar -l Maerkle \\"
  echo "     -e lothar.maerkle@ecm4u.de \\"
  echo "     -g GroupA -g GroupB"
  echo "     --> creates an account for Lothar Maerkle"
  echo "         with email lothar.maerkle@ecm4u.de."
  echo "         The user name will be lothar with password"
  echo "         pw123 and will become a member of the"
  echo "         groups GroupA and GroupB."
  echo
}

ALF_CMD_OPTIONS="${ALF_GLOBAL_OPTIONS}n:p:f:l:e:g:"
ALF_USERNAME=""
ALF_FIRST_NAME=""
ALF_LAST_NAME=""
ALF_EMAIL=""
ALF_PASSWD=""
ALF_GROUPS=()

function __process_cmd_option() {
  local OPTNAME=$1
  local OPTARG=$2

  case $OPTNAME
  in
    n)
      ALF_USERNAME=$OPTARG;;
    f)
      ALF_FIRST_NAME=$OPTARG;;
    l)
      ALF_LAST_NAME=$OPTARG;;
    e)
      ALF_EMAIL=$OPTARG;;
    p)
      ALF_PASSWD=$OPTARG;;
    g)
      ALF_GROUPS=("${ALF_GROUPS[@]}" $OPTARG);;
  esac
}

__process_options "$@"

# shift away parsed args
shift $((OPTIND-1))

if $ALF_VERBOSE
then
  ALF_CURL_OPTS="$ALF_CURL_OPTS -v"
  echo "connection params:"
  echo "  user: $ALF_UID"
  echo "  endpoint: $ALF_EP"
  echo "  curl opts: $ALF_CURL_OPTS"
  echo "  user name: $ALF_USERNAME"
  echo "  first name: $ALF_FIRST_NAME"
  echo "  last name: $ALF_LAST_NAME"
  echo "  email: $ALF_EMAIL"
fi

if [[ "$ALF_USERNAME" == "" ]]
then
  echo "an Alfresco user name is required"
  exit 1
fi

if [[ "$ALF_FIRST_NAME" == "" ]]
then
  echo "a first name is required"
  exit 1
fi

if [[ "$ALF_LAST_NAME" == "" ]]
then
  echo "a last name is required"
  exit 1
fi

if [[ "$ALF_PASSWD" == "" ]]
then
  echo "a password is required"
  exit 1
fi

if [[ "$ALF_EMAIL" == "" ]]
then
  echo "an email is required"
  exit 1
fi

#
# First should we tell if this is an existing user
#
ALF_EUSER=`$ALFTOOLS_BIN/alfGetUser.sh ${ALF_USERNAME} 2>/dev/null`

if [ $? -eq 0 ]
then
    # Existing user
	echo "ERROR: Existing user ${ALF_USERNAME}"
	exit 1
fi

ALF_JSON=`echo '{"groups":[]}' |\
	$ALF_JSHON \
	-s "$ALF_LAST_NAME" -i lastName \
	-s "$ALF_FIRST_NAME" -i firstName \
	-s "$ALF_USERNAME" -i userName \
	-s "$ALF_EMAIL" -i email \
	-s "$ALF_PASSWD" -i password \
	-n 'false' -i disableAccount`

# set groups if any
for GRP in ${ALF_GROUPS[*]}
do
	ALF_AUTHORITY="GROUP_${GRP}"
	ALF_JSON=`echo $ALF_JSON |\
		$ALF_JSHON \
		-e groups -s "$ALF_AUTHORITY" -i append -p`  	
done

#echo $ALF_JSON

echo $ALF_JSON |\
curl $ALF_CURL_OPTS \
	-u $ALF_UID:$ALF_PW \
	-H 'Content-Type:application/json' \
	-d@- -X POST $ALF_EP/service/api/people


# {"userName":"lodda","password":"test","firstName":"Lothar","lastName":"Maerkle","email":"lothar.maerkle@ecm4u.de","disableAccount":false,"quota":-1,"groups":[]}
# http://localhost:8080/share/proxy/alfresco/api/people

