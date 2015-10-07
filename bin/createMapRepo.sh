#!/bin/bash

WORK="$(basename "$0").tmp.$(date +%s)"
mkdir "$WORK"


bold=$(tput bold)
normal=$(tput sgr0)
#RED='\033[0;31m'
#GREEN='\033[0;31m'
#NC='\033[0m'

function usage() {

cat << EOF

${bold}Summary:${normal} Scans the current folder for any zip files. For each zip 
   file, will create a github repository and extracts the contents of the zip file 
   into a "map" folder. The script then finishes setting up the local git repo,
   web configuration on github, and web configuration for Travis builds.
 
${bold}Usage:${normal} ./$(basename "$0") -g {token} -p {password}${normal}
    token = github personal access token of an admin
    password = github tripleabuilderbot account password

${bold}Security Note:${normal} The bot account password will be displayed on standard 
    out in plain text occasionally while this script is running. Be careful the screen
    is locked if this script is left running anattended.

${bold}Security Note:${normal} Sensitive information entered in on command line will
    appear in your history. To avoid this, instead save your token value 
    to: "~/personal_access_token" and password to: "~/bot_password".
    Then run with: \$(basename "$0") -g \$(cat ~/personal_access_token) -p \$(cat ~/bot_password)

${bold}Sequence of events:${normal}

Staging:
- Create a folder whose name matches the zip
- Normalize the name.

GitHub:
- create github repository
- assign mapadmin team to the repository
- start a travis sync in the background

Local Git Setup:
- Create a folder for the repo
- Run git init inside of the folder
- Create a readme and commit it
- copy in support files: build.gradle, .gitattributes, .gitignore, commit and push
- unzip the map into a map folder
- run dos2unix and optipng
- commit and push map folder

Travis:
- enable travis web project
- create builder access token for the tag push
- update travis web environment variables
- copy in boilerplate .travis.yml
- setup github releases with an expect script
- fix up travis.yml file, commit and push
EOF
exit 1
}

if [ $# == 0 ]; then
  usage
fi

while [[ $# -gt 1 ]]
do
  key="$1"
  case $key in
    -g|--github-admin-token)
      ADMIN_TOKEN="$2"
      shift 2
      ;;
    -p|--bot-account-password)
      BOT_PASSWORD="$2"
      shift 2
      ;;
    *)
      echo "Unrecognized argument: $key"
      usage
      ;;
  esac
done


function printTitle() {
  echo -e "${bold}$1${normal}"
}

function die() {
  printTitle "Script Error"
  exit 1
}

function verifyExpectInstalled() {
  hash expect 2> /dev/null || { echo "expect not installed"; exit 1; }
}

function checkValidCredentials() {
  printTitle "Verifying Parameters are Valid Credentials"
  local token=$1
  local botPassword=$2
  
  DEAD=0
  echo -n "Admin -"
  curl --silent -u "${token}:x-oauth-basic" https://api.github.com/user | grep login || \
     { echo "Failed to authenticate against GitHub with the admin token provided."; DEAD=1; }
  echo -n "Bot   -"
  curl --silent -u "tripleabuilderbot:${botPassword}" https://api.github.com/user | grep login || \
     { echo "Failed to authenticate against GitHub with bot password provided."; DEAD=1; }
  if [ "$DEAD" != 0 ]; then
   die
  fi
}


verifyExpectInstalled
checkValidCredentials "$ADMIN_TOKEN" "$BOT_PASSWORD"

printTitle "Script Complete"
rm -rf "$WORK"

