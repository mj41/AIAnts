#!/bin/bash

echo "Running MyBot.pm simple test:" \
&& echo "  perl MyBot.pl temp/output-log.txt 10 t/data/game-web.txt > temp/bot-output.txt 2>&1" \
&& echo "" \
&& perl MyBot.pl temp/output-log.txt 10 t/data/game-web.txt > temp/bot-output.txt 2>&1 \
&& echo "Input data t/data/game-web.txt" \
&& cat t/data/game-web.txt \
&& echo "" \
&& echo "" \
&& echo "Bot log" \
&& cat temp/output-log.txt \
&& echo "" \
&& echo "Bot output temp/bot-output.txt" \
&& cat temp/bot-output.txt \
&& echo ""
