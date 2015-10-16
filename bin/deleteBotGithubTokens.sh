#!/bin/bash



export BOT_NAME=$1
export BOT_PASS_FILE=$2

if [ ! -f "$BOT_PASS_FILE" ]; then
  echo "usage: $(basename $0) <bot_account_name> <bot_pass_file>"
  echo "  bot_account_name: github account name of the bot"
  echo "  bot_pass_file: file that contains only the password for the bot account"
  exit 1
fi


for i in $(curl -s -u $BOT_NAME:$(cat $BOT_PASS_FILE) https://api.github.com/authorizations 2>&1 | grep "\"id\"" | sed 's/.* //' | sed 's/,$//'); do
  curl -X DELETE -u $BOT_NAME:$(cat $BOT_PASS_FILE) https://api.github.com/authorizations/$i;
  echo "Deleted token id: $i"
  sleep 1
done

