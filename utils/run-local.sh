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
rm game_logs/*

# MyBot.pm vs. MyBot.pm
if [ "$2" == "two" ]; then

    echo > ../../aiants/temp/game-out.txt
    echo > ../../aiants/temp/game-outB.txt
    echo > game_logs/0.bot0.error
    echo > game_logs/0.bot1.error

    ./playgame.py --turns $TURNS --player_seed 42 \
      --turntime=100 --loadtime=1000 --end_wait=0.25 \
      --verbose --log_dir game_logs -R -S -I -O -E \
      --map_file maps/maze/maze_02p_02.map \
      'perl ../../aiants/MyBot.pl temp/game-out.txt' \
      'perl ../../aiants/MyBot.pl temp/game-outB.txt'

    cd ../../aiants/

    echo "Bot 2 tail of output:"
    tail -n 150 temp/game-outB.txt

    echo "Bot 1 output:"
    cat temp/game-out.txt

    echo
    echo "Bot 2 error output:"
    cat ../aichallenge/ants/game_logs/0.bot1.error
    echo

    echo
    echo "Bot 1 error output:"
    cat ../aichallenge/ants/game_logs/0.bot0.error
    echo


# Perl vs. Python
else

    echo > ../../aiants/temp/game-out.txt
    echo > game_logs/0.bot0.error

    ./playgame.py --turns $TURNS --player_seed 42 \
      --turntime=100 --loadtime=1000 --end_wait=0.25 \
      --verbose --log_dir game_logs -R -S -I -O -E \
      --map_file maps/maze/maze_02p_02.map \
      'perl ../../aiants/MyBot.pl temp/game-out.txt' \
      'python dist/sample_bots/python/GreedyBot.py'

    cd ../../aiants/
    echo "Bot 1 output:"
    cat temp/game-out.txt

    echo "Bot 1 error output:"
    cat ../aichallenge/ants/game_logs/0.bot0.error
    echo
fi

