#!/bin/bash

if [ -z "$1" ]; then
  echo "Select one of example bots (the first parameter)."
  echo "Example usage: ./utils/use-exmple.bot.sh bots/02-random.pm"
  echo
  echo "Available bots:" 
  ls -1 bots/*
  exit
fi
BOT_FPATH="$1"


if [ -e MyBot.pm ]; then
    GITST="$(git st --porcelain MyBot.pm)"
    if [ ! -z "$GITST" ]; then
        echo "Found MyBot.pm modifications:"
        echo "git status -- MyBot.pm"
        echo
        git status -- MyBot.pm
        echo
        echo "Commit changes, remove them or remove the whole file:"
        echo "  git commit -m \"My MyBot.pm\" -- MyBot.pm"
        echo "  git checkout -- MyBot.pm"
        echo "  rm MyBot.pm"
        exit;
    fi
fi

echo "Copying $BOT_FPATH to MyBot.pm"
cp $BOT_FPATH MyBot.pm
echo ""

./utils/run-test.sh
