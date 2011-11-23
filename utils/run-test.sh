#!/bin/bash

BOT="$1"
if [ -z "$BOT" ]; then
    BOT="MyBot.pm"
fi

if [ ! -f "$BOT" ]; then
    echo "Can't find bot file '$BOT'."
    echo
    echo "Usage:"
    echo "  ./utils/run-test.sh MyBot.pm"
    echo "  ./utils/run-test.sh bots/RandomBot.pm"
    echo
    echo "Bots:"
    echo "MyBot.pm"
    ls -1 bots/*
    exit
fi

echo "Running $BOT simple test:" \
&& echo "  perl MyBot.pl $BOT temp/output-log.txt 10 t/data/game-web.txt > temp/bot-output.txt 2>&1" \
&& echo "" \
&& perl MyBot.pl $BOT temp/output-log.txt 10 t/data/game-web.txt > temp/bot-output.txt 2>&1 \
&& echo "Input data t/data/game-web.txt" \
&& cat t/data/game-web.txt \
&& echo "" \
&& echo "" \
&& echo "Bot log" \
&& cat temp/output-log.txt \
&& echo ""

echo "Bot output temp/bot-output.txt" \
&& cat temp/bot-output.txt \
&& echo ""
