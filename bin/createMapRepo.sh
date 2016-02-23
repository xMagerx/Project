#!/bin/bash

## Scans the current folder for any zip files. For each one, normalized 
## the name, creates a folder to host the github repo, extracts the zip 
## into a map folder inside of teh hosting folder. The script then copies 
## in and configures the Git support files, it also then remotely 
## configures GitHub.com and Travis.org.

## todo -- accept bot token, use it to create repo and do everything
##      -- use the admin token just for the team management stuff
##      -- Read the bot, admin tokens and bot password from a property file rather than as args


clear 


export bold=$(tput bold)
export normal=$(tput sgr0)
NC='\033[0m'
PURPLE='\033[0;35m'
BLUE='\033[0;34m'

ORG_NAME=triplea-maps
BOT_ACCOUNT=tripleabuilderbot
MAP_ADMIN_TEAM_NAME="MapAdmins"
SCRIPT_NAME=$(basename "$0")


function usage() {
  echo "Usage: ./$SCRIPT_NAME -a <admin_token_file> -b <bot_token_file> -p <bot_password_file>"
  echo "Usage: ./$SCRIPT_NAME -d"
  echo "Usage: ./$SCRIPT_NAME -m <MAP>"
  echo "  admin_token_file = file with one line, an an organization owner"
  echo "  bot_token_file = personal access token of the github account"
  echo "  bot_password_file =  file containing the password of the bot account"
  echo " -d = use defaults:"
  echo "     -a ~/.github/token"
  echo "     -b ~/.github/bot_token"
  echo "     -p ~/.github/bot_password"
  exit 1
}


if [ $# == 0 ]; then
  usage
fi

while [[ $# -gt 1 ]]
do
  key="$1"
  case $key in
    -a|--admin-token)
      ADMIN_TOKEN_FILE="$2"
      shift 2
      ;;
    -b|--bot-token)
      BOT_TOKEN_FILE="$2"
      shift 2
      ;;
    -p|--bot-account-password)
      BOT_PASSWORD_FILE="$2"
      shift 2
      ;;
    -m|--map)
      MAP="$2"
      shift 2
      ;;
    *)
      echo "${bold}Unrecognized argument: $key${normal}"
      usage
      ;;
  esac
done


################


function printTitle() {
  COLOR=$2
  echo -e "${COLOR}${bold}$1${NC}"
}

function printBlueTitle() {
  printTitle "$1" "${BLUE}"  
}

function printGreenTitle() {
  printTitle "$1" "${PURPLE}"  
}


function die() {
  printTitle "Script Error $1"
  exit 1
}


function verifyDependency() {
  local DEPENDENCY=$1
  hash "$DEPENDENCY" 2> /dev/null || { echo "expect not installed"; exit 1; }
}

function printZipFilesFound() {
  echo
  printBlueTitle "<<Starting>>"
  printTitle "Found $(find . -maxdepth 1 -name '*zip' | wc -l) File(s)"
  find . -maxdepth 1 -name '*zip' | sed 's|^./||' | sort
  echo
}

function checkFileExists() {
  local FILE_TO_CHECK=$1
  if [ ! -f "$FILE_TO_CHECK" ]; then
   die "Did not find file: $FILE_TO_CHECK"
  fi
}

function checkNotEmpty() {
  local TOKEN=$1
  if [ -z "$TOKEN" ]; then
    die "empty token found in the password or token file supplied as parameters"
  fi
}

function checkValidCredentials() {
  printTitle "Verifying GitHub credentials"
  local token=$1
  local botAccount=$2
  local botPassword=$3
  
  DEAD=0
  echo -n "Admin -"
  curl --silent -u "${token}:x-oauth-basic" https://api.github.com/user | grep login || \
     { echo "Failed to authenticate against GitHub with the admin token provided."; DEAD=1; }
  echo -n "Bot   -"
  curl --silent -u "${botAccount}:${botPassword}" https://api.github.com/user | grep login || \
     { echo "Failed to authenticate against GitHub with bot password token."; DEAD=1; }
  if [ "$DEAD" != 0 ]; then
   die
  fi
  echo
}


function normalizeName() {
  local mapZip=$1
     # normalization will:
     #  - strip the zip sufix
     #  - insert an underscore between lower case and upper case letter to break up camel casing
     #  - lower case everything
     #  - replace spaces with underscores 
     #  - remove leading period (can get that from input source of ls)
  local normalized=$(echo "$mapZip" | sed 's/.zip$//' | \
                sed 's/\([a-z]\)\([A-Z]\)/\1_\2/g' | tr '[:upper:]' '[:lower:]' | \
                sed "s/  */_/g" | sed 's|^\./||')
  
  echo "$normalized"
}

function extractMapToNormalizedFolder() {
  local mapZip=$1
  local targetFolder=$2

  echo "Extracting: $mapZip into: $targetFolder (from $(pwd))"
    ## in the zip and folder name, remove the leading "./"
  printTitle "Extracting zip"
  
  mkdir -p "$targetFolder"
  UNZIP_COUNT=$(unzip -n "$mapZip" -d "${targetFolder}" 2>&1 | wc -l)
  echo "Extracted $((UNZIP_COUNT-1)) files from '${mapZip//.\//}'"
  echo ""
}

function removeSpacesFromFileNames() {
  local repoName=$1
  printTitle "Removing spaces from filenames"
  while read xmlName; do
    local fixedName=$(echo $xmlName | tr ' ' '_')
    mv "$xmlName" "$fixedName"
  done < <(find "$repoName" -type f | grep " ")
  echo
}

function formatXmlFiles() {
  local repoName=$1
  printTitle "Format XML files"
  while read xmlName; do
    xmllint --format "$xmlName" > "$xmlName.linted"
    mv "$xmlName.linted" "$xmlName"
  done < <(find "$repoName" -type f | grep ".xml$")
  echo
}

function normalizeMapProperty() {
  local repoName=$1
  printTitle "Normalizing XML map property name"

  while read xmlFile; do
       xargs sed -i "s|name=\"mapName\" value=\".*\" editable|name=\"mapName\" value=\"$repoName\" editable|" "$xmlFile";
  done < <(find "$repoName/map/games" -type f -name "*.xml")
  echo
}

function curFolder() {
(
    local NEW_FOLDER=$(dirname "$0")
    cd "$NEW_FOLDER"
    pwd
  )
}

function deleteBotGitHubToken() {
  local botPassword=$1
  local tokenName=$2
  
  local botAuth="$BOT_ACCOUNT:$botPassword"
  
  echo "Deleting token $tokenName"
  curl --silent -u "$botAuth" "$githubAuthUrl" 2>&1 | grep -i -B3 "\"name\": \"$tokenName\"" 
  
  local oldTokenId=$(curl --silent -u "$botAuth" "$githubAuthUrl" 2>&1 | grep -i -B3 "\"name\": \"$tokenName\"" | grep id | sed 's|.*: ||g' | sed 's|,$||');
  if [ ! -z "$oldTokenId" ]; then
    curl -X DELETE -u "$botAuth" --silent "https://api.github.com/authorizations/$oldTokenId"
  fi
}


function resetTravisBotToken() {
  local botPassword=$1
  local tokenName=$2
  deleteBotGitHubToken "$botPassword" "$tokenName"
  
  local botAuth="$BOT_ACCOUNT:$botPassword"

  local newBotToken=$(curl --silent -d "{\"note\":\"$tokenName\", \"scopes\": [\"public_repo\"] }" \
       -u "$botAuth" "$githubAuthUrl" 2>&1 | grep  "\"token\": " | sed 's|.*: "||' | sed 's|",$||');
  echo "Updating GITHUB_PERSONAL_ACCESS_TOKEN_FOR_TRAVIS"
  travis env set GITHUB_PERSONAL_ACCESS_TOKEN_FOR_TRAVIS "$newBotToken"
}

function initTravis() {
  printTitle "Verify logged in to travis"
  travis whoami || die "Not logged in to travis"
  
  printTitle "--Setting up Travis--"
  export mapRepo=$1
  local botPassword=$2
  (
   cd "$mapRepo"
   printTitle "Travis: sync"
   travis sync

   echo
   printTitle "Travis: Setting Environment Values"
   local tokenName="automatic releases for ${ORG_NAME}/$mapRepo (tag pushes)"
   local travisValues=$(travis env -R "$ORG_NAME/$mapRepo" --org list)

   if [ -f .travis.yml ]; then
     echo "Skipped: Travis Init and Enable"
     echo
   else
     echo
     printTitle "Travis Init and Enable"
     "$FILES_FOLDER/expect_scripts/travis_init.expect" "$ORG_NAME/$mapRepo"
   fi
     
     ## set the tokens only if they do not already exist
   echo "$travisValues" | grep "GITHUB_PERSONAL" || resetTravisBotToken "$botPassword" "$tokenName"
   echo "$travisValues" | grep "REPO_NAME" || travis env set -P REPO_NAME "$mapRepo"
   echo "$travisValues" | grep "MAP_VERSION" || travis env set -P MAP_VERSION 0

   echo
  
   local releasesConfigured=$(grep -c "secure" .travis.yml)
   if [ "$releasesConfigured" == 0 ]; then
     printTitle "Travis: Setup Releases" 
     echo "Delete the old token"
     deleteBotGitHubToken "$botPassword" "automatic releases for $ORG_NAME/$mapRepo"
     sleep 5
     echo "run travis setup releases with expect"
     "$FILES_FOLDER/expect_scripts/travis_releases.expect" "$ORG_NAME/$mapRepo" "$BOT_ACCOUNT" "$botPassword" | tail -n +2
     echo
     printTitle "Travis: copy api key into template and commit"
     local newKey="$(grep secure .travis.yml)"
     sed "s|.*secure:.*|$newKey|" "$TRAVIS_TEMPLATE_FILE" > .travis.yml
     git add .travis.yml
     git commit .travis.yml -m 'Add map build configuration file: .travis.yml' | grep "^.master" 
   else
     printTitle "Travis: Skipped Setup Releases, already configured, .travis.yml contains a secure token" 
   fi
  )
  echo
}


function createRemoteGitHubRepo() {
  local REPO_NAME=$1
  printTitle "Creating GitHub repository"

  local repoUrl="https://api.github.com/orgs/$ORG_NAME/repos"
  EXISTS_COUNT=$(curl --silent -H "${GITHUB_AUTH}" "${repoUrl}"?"${GITHUB_PAGE_ARGS}" |  grep -c "\"name\": \"$REPO_NAME\",$")
  
  if [ "$EXISTS_COUNT" == 0 ]; then
    echo -n "Creating "
    curl --silent -H "${GITHUB_AUTH}" ${repoUrl} -d "{ \"name\": \"$REPO_NAME\", \"private\": false}" | egrep -i "full_name|error|message" | sed 's/"//g' | sed 's/,$//g' | sed 's|^ *||'
  else
     echo "Skipped: repo already exists"
  fi
  echo
}

function initRepo() {
  local repoName=$1
  printTitle "Initializing local repo"
  (
   cd "$repoName"
   if [ ! -d ".git" ]; then
     git init
   else
     echo "Skipped: .git already exist"
   fi
 
   REMOTE_COUNT=$(git remote -v | grep -c "origin")
   if [ "$REMOTE_COUNT" == 0 ]; then
     REMOTE_ORIGIN="git@github.com:${ORG_NAME}/$repoName.git"
     git remote add origin "$REMOTE_ORIGIN"
     echo "Added remote origin ${REMOTE_ORIGIN}"
   else
     echo "Skipped: remote origin already exists"
   fi
   git fetch origin
   curl -s -H "${GITHUB_AUTH}" https://api.github.com/repos/${ORG_NAME}/"${repoName}"/branches 2>&1 | \
     grep -q "\"master\"" && git checkout master && git branch --set-upstream-to=origin/master master 
   git pull --rebase origin master
  )
  echo
}

function createReadme() {
  printTitle "Repository init with readme file"
  local repoName=$1
  if [ ! -f "$repoName/README.md" ]; then
   (
    cd "$repoName"
    echo "## $repoName" >> README.md
    git add README.md
    git commit -m 'Initial commit' 2>&1 | egrep -i "file changed"
    git push origin -u master 2>&1
   )
  else
    echo "Skipped: README.md already exists"
  fi
  echo
}
 
function addMapAdminTeam() {
  printTitle "Adding map admin"
  local mapRepo=$1


  local MAP_ADMIN_ID=$(curl -s -H "${GITHUB_AUTH}" https://api.github.com/orgs/triplea-maps/teams 2>&1 | grep -A1 "$MAP_ADMIN_TEAM_NAME" | grep id | sed 's/.*: //g' | sed 's/,$//g')
 
  if [[ ! "$MAP_ADMIN_ID" =~ [0-9]+ ]]; then
     die "Failed to correctly parse map admin ID, value parsed is: $MAP_ADMIN_ID"
     curl -s -H "${GITHUB_AUTH}" https://api.github.com/orgs/triplea-maps/teams 2>&1 | grep -C3 "$MAP_ADMIN_TEAM_NAME"
  fi
  local MAP_ADMIN_TEAM_ADDED=$(curl -s -H "${GITHUB_AUTH}" "https://api.github.com/teams/${MAP_ADMIN_ID}/repos" 2>&1 | grep -c "name\": \"$mapRepo\"")


  if [ "$MAP_ADMIN_TEAM_ADDED" == 0 ]; then
    curl -X PUT -d "{\"permission\": \"push\"}" -H "${ADMIN_GITHUB_AUTH}" -H "Accept: application/vnd.github.ironman-preview+json" "https://api.github.com/teams/$MAP_ADMIN_ID/repos/${ORG_NAME}/$mapRepo"
    echo "Map admin team added to repository"
  else
    echo "Skipping: map admin teams already added to the repository"
  fi
  echo
}

function copyStaticFile() {
  local file=$1
  local repoName=$2
  cp "${FILES_FOLDER}/static/$file" "$repoName"
  (
   cd "$repoName"
   git add "$file"
   git commit "$file" -m "Add project support file $file" | grep "^.master"
  )   

}

function copyStaticFiles() {
  printTitle "Copying static project files"
  local repoName=$1

  for fileName in $(ls -a "${FILES_FOLDER}/static/" | egrep -v "^..?$"); do
    if [ ! -f "$repoName/$fileName" ]; then
       copyStaticFile "$fileName" "$repoName"
    else
       echo "Skipped: file already exists $fileName"
    fi
  done;

  echo
}

function runOptiPng() {
  local mapRepo=$1
  printTitle "Running optiPng ($(find "$mapRepo" -name "*.png" | wc -l) files)"
  parallel optipng -nx {} 2>&1 < <(find "$mapRepo" -name "*.png") | grep -i "error"
  echo "Done"
  echo
}

function commitAndPushMapFiles() {
  local mapRepo=$1
  printTitle "Commit map files and push"
  (
   cd "$mapRepo"
   git add map
   git commit map -m 'add map files' | grep master
   git push origin master
  )
  echo
}

###########

 ## todo
githubAuthUrl="https://api.github.com/authorizations?per_page=10000&page=1"

if [ -z "$MAP" ]; then
  printZipFilesFound
else
  printTitle "Processing map folder: $MAP"
fi 


TOKEN_DIR="$(cd ~; pwd)/.github"
ADMIN_TOKEN_FILE="$TOKEN_DIR/token"
BOT_TOKEN_FILE="$TOKEN_DIR/bot_token"
BOT_PASSWORD_FILE="$TOKEN_DIR/bot_password"

echo "using admin token file: $ADMIN_TOKEN_FILE"
echo "using bot token file: $BOT_TOKEN_FILE"
echo "using bot password file: $BOT_PASSWORD_FILE"

checkFileExists "$ADMIN_TOKEN_FILE"
checkFileExists "$BOT_TOKEN_FILE"
checkFileExists "$BOT_PASSWORD_FILE"

verifyDependency "expect"
verifyDependency "parallel"
verifyDependency "travis"
verifyDependency "xmllint"

FILES_FOLDER="$(curFolder)/files"

checkFileExists "${FILES_FOLDER}/static/build.gradle"
checkFileExists "${FILES_FOLDER}/static/.gitignore"

TRAVIS_TEMPLATE_FILE="${FILES_FOLDER}/templates/.travis.yml"
checkFileExists "$TRAVIS_TEMPLATE_FILE"
checkFileExists "${FILES_FOLDER}/expect_scripts/travis_init.expect"
checkFileExists "${FILES_FOLDER}/expect_scripts/travis_releases.expect"


ADMIN_TOKEN=$(head -1 "$ADMIN_TOKEN_FILE")
checkNotEmpty "$ADMIN_TOKEN"

BOT_TOKEN=$(head -1 "$BOT_TOKEN_FILE")
checkNotEmpty "$BOT_TOKEN"

GITHUB_AUTH="Authorization: token $BOT_TOKEN"
ADMIN_GITHUB_AUTH="Authorization: token $ADMIN_TOKEN"

GITHUB_PAGE_ARGS="page=1&per_page=10000"

BOT_PASSWORD=$(head -1 "$BOT_PASSWORD_FILE")
checkNotEmpty "$BOT_PASSWORD"
checkValidCredentials "$ADMIN_TOKEN" "$BOT_ACCOUNT" "$BOT_PASSWORD"

echo

export -f printTitle
export -f extractMapToNormalizedFolder

printTitle "Do Travis Login"
travis login -g "$BOT_TOKEN"

COUNT=0


MAP_LIST=/tmp/tmp.$(date +%s)
if [ -z "$MAP" ]; then
 find . -name "*.zip" > $MAP_LIST
 MAP_COUNT=$(find . -maxdepth 1 -name "*zip" | wc -l)
else
  echo "$MAP" > $MAP_LIST
  MAP_COUNT=1
fi

echo before loop using $MAP_LIST
cat $MAP_LIST | while read zipFile; do
 START_TIME=$(date +%s)
 COUNT=$((COUNT+1)) 
 NORMALIZED_NAME=$(normalizeName "$zipFile")
 mkdir -p $NORMALIZED_NAME 
 printGreenTitle "Processing Map ($COUNT of $MAP_COUNT): $NORMALIZED_NAME"

 createRemoteGitHubRepo "$NORMALIZED_NAME"
 initRepo "$NORMALIZED_NAME"
 createReadme "$NORMALIZED_NAME"

 if [ -z "$MAP" ]; then
   extractMapToNormalizedFolder "$zipFile" "$NORMALIZED_NAME/map"
 fi
 removeSpacesFromFileNames "$NORMALIZED_NAME"
 formatXmlFiles "$NORMALIZED_NAME"
 normalizeMapProperty "$NORMALIZED_NAME"
 printTitle "Cleaning up line endings"
 find "$NORMALIZED_NAME" -type f -name "*.txt" -name "*.xml" | \
       grep -v "^$NORMALIZED_NAME/.git/" | xargs dos2unix 2>&1 | egrep -o "converting|not a regular file|No such file" | sort | uniq -c
 echo

 addMapAdminTeam "$NORMALIZED_NAME"
 initTravis "$NORMALIZED_NAME" "$BOT_PASSWORD"
 copyStaticFiles "$NORMALIZED_NAME"
 if [ -z "$MAP" ]; then
   runOptiPng "$NORMALIZED_NAME"
 fi
 commitAndPushMapFiles "$NORMALIZED_NAME" &
 END_TIME=$(date +%s)
 printBlueTitle "<$NORMALIZED_NAME processed in $((END_TIME-START_TIME))s>"
done

printBlueTitle "<<Done>>"

exit 0

