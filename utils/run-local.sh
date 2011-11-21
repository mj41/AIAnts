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

SEC_BOT="$2"
if [ ! -f $SEC_BOT ]; then
    echo "Can't find bot file '$SEC_BOT'."
    echo
    echo "Usage:"
    echo "  ./utils/run-local.sh 100 MyBot.pm"
    echo "  ./utils/run-local.sh 100 bots/RandomBot.pm"
    echo
    echo "Bots:"
    echo "MyBot.pm"
    ls -1 bots/*
    exit
    exit;
fi

cd ../aichallenge/ants || exit
rm game_logs/*

# MyBot.pm vs. MyBot.pm
if [ ! -z "$SEC_BOT" ]; then

    echo > ../../aiants/temp/game-out.txt
    echo > ../../aiants/temp/game-outB.txt

    echo "Running 'MyBot.pm' vs. '$SEC_BOT'"

    ./playgame.py --turns $TURNS --player_seed 42 \
      --turntime=100 --loadtime=1000 --end_wait=0.25 \
      --verbose --log_dir game_logs -R -S -I -O -E \
      --map_file maps/maze/maze_02p_02.map \
      "perl ../../aiants/MyBot.pl MyBot.pm temp/game-out.txt" \
      "perl ../../aiants/MyBot.pl $SEC_BOT temp/game-outB.txt"

    cd ../../aiants/

    echo "Bot 2 ($SEC_BOT) tail of output:"
    tail -n 150 temp/game-outB.txt

    echo "Bot 1 (MyBot.pm) output:"
    cat temp/game-out.txt
    echo

    echo "Bot 2 ($SEC_BOT) tail of error output:"
    tail -n 50 ../aichallenge/ants/game_logs/0.bot1.error

    echo
    echo "Bot 1 (MyBot.pm) error output:"
    cat ../aichallenge/ants/game_logs/0.bot0.error
    echo

    echo "Too see bots output use:"
    echo "  less temp/game-out.txt"
    echo "  less temp/game-outB.txt"


# Perl vs. Python
else

    echo > ../../aiants/temp/game-out.txt

    ./playgame.py --turns $TURNS --player_seed 42 \
      --turntime=100 --loadtime=1000 --end_wait=0.25 \
      --verbose --log_dir game_logs -R -S -I -O -E \
      --map_file maps/maze/maze_02p_02.map \
      'perl ../../aiants/MyBot.pl MyBot.pm temp/game-out.txt' \
      'python dist/sample_bots/python/GreedyBot.py'

    cd ../../aiants/
    echo "Bot 1 output:"
    cat temp/game-out.txt

    echo "Bot 1 error output:"
    cat ../aichallenge/ants/game_logs/0.bot0.error
    echo
fi

