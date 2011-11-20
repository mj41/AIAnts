use strict;
use warnings;

use Test::More;

use lib 'lib';
use lib 't/lib';
use AIAnts::TestBotHash;
use AIAnts::TestGame;

my $bot = AIAnts::TestBotHash->new();
my $game = new AIAnts::TestGame( bot => $bot );

$game->set_input(q(
    turn 0
    loadtime 500
    turntime 100
    rows 3
    cols 5
    turns 50
    viewradius2 1
    attackradius2 1
    spawnradius2 1
    player_seed 42
    ready
));
$game->do_setup;

# . o . o .
# f a o a %
# . o . o .


# Prepare turn 1 game output and bot orders.
$game->set_input(q(
    a 1 1 0
    h 1 1 0
    f 1 0
    a 1 3 0
    h 1 3 0
    w 1 4
));
#                         $x, $y, $dir, $Nx, $Ny
$bot->test_prepare_test_order(  1,  1,  'S',   2,   1 );
$bot->test_prepare_test_order(  1,  3,  'S',   2,   3 );

$bot->test_set_turntime_alarm(12);
$game->do_turn;
$bot->test_set_turntime_alarm(0);


# Check bot and map state after turn 1 - new ant on position 1,2
is( $game->bot->map->dump(1), <<MAP_END, 'turn 1' );
. o . o .
f a o a %
. o . o .
MAP_END

is(
    $game->get_output,
    join( "\n", 'go', 'o 1 1 S', 'go' ) . "\n",
    'output'
);

done_testing();
