#!/bin/bash

export BOT_NAME=$1
export BOT_PASS_FILE=$2

if [ ! -f "$BOT_PASS_FILE" ]; then
  echo "usage: $(basename $0) <bot_account_name> <bot_pass_file>"
  echo "  bot_account_name: github account name of the bot"
  echo "  bot_pass_file: file that contains only the password for the bot account"
  exit 1
fi

githubAuthUrl="https://api.github.com/authorizations?per_page=1000?page=1"

botAuth="$BOT_NAME:$(cat $BOT_PASS_FILE)"


for i in $(curl -s -u "$botAuth" "$githubAuthUrl" 2>&1 | grep \"id\" | sed 's|.*: ||g' | sed 's|,$||'); do
  echo "delete $i"
  curl -X DELETE -u "$botAuth" -silent https://api.github.com/authorizations/$i
done;
