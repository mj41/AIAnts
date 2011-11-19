#!/bin/bash

if [ ! -d '../aichallenge/ants' ]; then
    echo "No ../aichallenge/ants directory found."
    echo "See documentation:"
    echo "  perldoc docs/devel.pod"
    echo "  pod2text docs/devel.pod"
    exit
fi

TURNS=25
if [ ! -z "$1" ]; then
    TURNS="$1"
fi

# todo
# perl -c MyBot.pl || ( echo "Failed checking syntaxt of MyBot.pl"  && exit ) 

cd ../aichallenge/ants || exit

# MyBot.pm vs. MyBot.pm
if [ "$2" == "two" ]; then

    echo > ../../aiants/temp/game-out.txt
    echo > ../../aiants/temp/game-outB.txt

    ./playgame.py --turns $TURNS --player_seed 42 \
      --turntime=100 --loadtime=1000 --end_wait=0.25 \
      --verbose --log_dir game_logs -R -S -I -O -E \
      --map_file maps/maze/maze_02p_02.map \
      'perl ../../aiants/MyBot.pl temp/game-out.txt' \
      'perl ../../aiants/MyBot.pl temp/game-outB.txt'

    echo "Bot 2 error output"
    cat game_logs/1.bot1.error
    echo

# Perl vs. Python
else

    echo > ../../aiants/temp/game-out.txt

    ./playgame.py --turns $TURNS --player_seed 42 \
      --turntime=100 --loadtime=1000 --end_wait=0.25 \
      --verbose --log_dir game_logs -R -S -I -O -E \
      --map_file maps/maze/maze_02p_02.map \
      'perl ../../aiants/MyBot.pl temp/game-out.txt' \
      'python dist/sample_bots/python/GreedyBot.py'
fi

echo "Bot 1 error output"
cat game_logs/0.bot0.error
echo

cd ../../aiants/
echo "Bot 1 output"
cat temp/game-out.txt
