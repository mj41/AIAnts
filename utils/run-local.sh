#!/bin/bash

if [ ! -d 'aichallenge/ants' ]; then
    echo "No aichallenge/ants directory found."
    echo "Show docs with:"
    echo "  perldoc docs/devel.pod"
    echo "  pod2text docs/devel.pod"
    exit
fi

TURNS=10
if [ ! -z "$1" ]; then
    TURNS="$1"
fi

# todo
# perl -c MyBot.pl || ( echo "Failed checking syntaxt of MyBot.pl"  && exit ) 

cd aichallenge/ants || exit

echo > ../../temp/game-out.txt

./playgame.py --turns $TURNS --player_seed 42 \
  --turntime=100 --loadtime=1000 --end_wait=0.25 \
  --verbose --log_dir game_logs -R -S -I -O -E \
  --map_file maps/maze/maze_02p_02.map \
  'perl ../../MyBot.pl temp/game-out.txt' \
  "python dist/sample_bots/python/GreedyBot.py"

cat game_logs/0.bot0.error

cd ../..
cat temp/game-out.txt

