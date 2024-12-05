#
# tools library
#
# collection of shell functions useful for all commands
#
#

# Fri Oct  2 11:46:27 CEST 2015
# spd@daphne.cps.unizar.es
#
# fixes in __get_share_session_id
#

function __show_global_options() {
  echo "  global options:"
  echo "    -h   help       shows this help screen"
  echo "    -v   verbose    displays information while executing"
  echo 
  echo "    -E   endpoint   Alfresco endpoint"
  echo "    -S   share endpoint Alfresco share endpoint"
  echo "    -U   user       Alfresco user id used in authentication"
  echo "    -P   password   password used for authenticaiton"
  echo
  echo "    -C   curl opts  any additional options pass to curl"
}

# intended to be replaced in command script by a command specific output
function __show_command_options() {
  echo "  command options:"
  echo "    no command specific options"
  echo 
}

# intended to be replaced in command script
function __show_command_arguments() {
  echo "  command arguments:"
  echo "     no command arguments"
}


# intended to be replaced in command script
function __show_command_explanation() {
  echo "  command explanation:"
  echo
  echo "    this command has no explanation so far"
}

function help() {
  echo "usage: $0 [global options] [command specific options] arguments"
  __show_global_options
  echo
  __show_command_options
  __show_command_arguments
  echo
  __show_command_explanation
  echo
  echo "  The Alfresco shell tools are created by"
  echo "    lothar.maerkle@ecm4u.de"
  echo "    http://www.ecm4u.de - http://www.ecm-market.de"
  echo "    This fork:"
  echo "    https://github.com/fsckawk/alfresco-shell-tools"
  echo "    Anybody jumps in?"
}

#
# does url encoding, treats all parameters as a single one
#
function __encode_url_param() {
# see here for credits http://stackoverflow.com/questions/296536/urlencode-from-a-bash-script
  local string=$@
  local strlen=${#string}
  local encoded=""

  for (( pos=0 ; pos<strlen ; pos++ )); do
     c=${string:$pos:1}
     case "$c" in
        [-_.~a-zA-Z0-9] ) o="${c}" ;;
        * )               printf -v o '%%%02x' "'$c"
     esac
     encoded+="${o}"
  done
#  echo "${encoded}"    # You can either set a return variable (FASTER) 
  ENCODED_PARAM="${encoded}"   #+or echo the result (EASIER)... or both... :p
}

function __htd() {
	perl -pe 's/\%([A-Fa-f0-9]{2})/pack("C", hex($1))/seg;'
}

function __recode() {
  local string=$@

  if echo "$string" | recode utf8..latin1 > /dev/null 2>&1
  then
  	# string uses utf8
	echo "$string"
  else
	echo "$string" | recode latin1..utf8
  fi
}

function __encode_url_path() {
# see here for credits http://stackoverflow.com/questions/296536/urlencode-from-a-bash-script
  local string=$@
  local strlen=${#string}
  local encoded=""

  for (( pos=0 ; pos<strlen ; pos++ )); do
     c=${string:$pos:1}
     case "$c" in
        [/-_.~a-zA-Z0-9] ) o="${c}" ;;
        * )               printf -v o '%%%02x' "'$c"
     esac
     encoded+="${o}"
  done
#  echo "${encoded}"    # You can either set a return variable (FASTER) 
  ENCODED_PATH="${encoded}"   #+or echo the result (EASIER)... or both... :p
}

function __is_noderef() {
  local alfUrl=$@
  local regex="^[a-zA-Z]+://[a-zA-Z0-9]+/.*$" 

  if [[ $alfUrl =~ $regex ]]
  then
    true
  else
   false
  fi
}

function __split_noderef() {
  local nodeRef=$@

  UUID=$(echo $nodeRef | perl -pe 's|^[^:]+://[^/]+/||')
  PROTOCOL=${nodeRef%%:*}
  STORE=`echo $nodeRef | perl -pe 's|^[^:]+://([^/]+)/.*|$1|'`
}

function __process_cmd_option() {
  local OPTNAME=$1
  local OPTARG=$2

  echo "cmd opts: $OPTNAME=$OPTARG"
}

function __get_share_session_id() {
  # get a valid share session id
  ALF_SHARE_SESSIONID=`curl -k -f -sS -q -i \
  	--data "username=$ALF_UID" \
	--data "password=$ALF_PW" \
	-X POST $ALF_SHARE_EP/page/dologin |\
	grep Set-Cookie | sed -e 's/.*Cookie: //' -e 's/; .*//' | tr \\\\012 \; |\
	sed -e 's/JSESSIONID=//' -e 's/[;]*$//' -e 's/;/; /g'`
}


function __process_options() {
  while getopts $ALF_CMD_OPTIONS OPTNAME
  do
#  echo "OPTARG=$OPTARG OPTIND=$OPTIND OPTNAME=$OPTNAME"

  case $OPTNAME
  in
    h)
      help
      exit;;
    U)
      ALF_UID=$OPTARG;;
    P)
      ALF_PW=$OPTARG;;
    E)
      ALF_EP=$OPTARG;;
    S)
      ALF_SHARE_EP=$OPTARG;;
    C)
      ALF_CURL_OPTS=$OPTARG;;
    v)
      ALF_VERBOSE=true;;
    ?)
      __process_cmd_option "$OPTNAME" "$OPTARG"
  esac
  done

  # caller needs to shift away parsed arguments
}


# global options
ALF_GLOBAL_OPTIONS=":vhE:U:P:C:S:"
ALF_CMD_OPTIONS=$ALF_GLOBAL_OPTIONS

# jshon tool location, defaults to jshon
ALF_JSHON=${ALFTOOLS_JSHON:-jshon}

# read environment vars
ALF_UID=$ALFTOOLS_USER
ALF_PW=$ALFTOOLS_PASSWORD
ALF_EP=$ALFTOOLS_ENDPOINT
ALF_SHARE_EP=$ALFTOOLS_SHARE_ENDPOINT
ALF_VERBOSE=false
ALF_CURL_OPTS=$ALFTOOLS_CURL_OPTS




# init curl options. Note: -f is important to signal communication errors
if [[ "$ALF_CURL_OPTS" == "" ]]
then
  ALF_CURL_OPTS="-s -S -k -f"
fi



