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
    loadtime 300
    turntime 100
    rows 8
    cols 10
    turns 50
    viewradius2 5
    attackradius2 3
    spawnradius2 1
    player_seed 42
    ready
));
$game->do_setup;
is( $game->bot->map->dump(1), <<MAP_END, 'setup' );
. . . . . . . . . .
. . . . . . . . . .
. . . . . . . . . .
. . . . . . . . . .
. . . . . . . . . .
. . . . . . . . . .
. . . . . . . . . .
. . . . . . . . . .
MAP_END

=pod

. f . . . . . . . .
. . a . . . . . . .
. . h . w . . . . .
. f . . w w . . . .
. . . w w . . . f .
. . . . w . . h . .
. . . . . . . a . .
. . . . . . . . f .

=cut

# prepare turn 1 game output and bot orders
$game->set_input(q(
    a 1 2 0
    w 1 1
    w 7 2
    h 1 4 1
    f 2 2
));
$bot->set_next_changes({
    # $Nx,$Ny => [ $ant_num, $x, $y, $dir, $Nx, $Ny ]
    '3,2'     => [        1,  1,  2,  'S',   2,   2 ]
});

# Do turn 1. Bot is going to process prepared data (receive input and send 'changes').
# Ant is on position 1,2 and will prepare move 'S' to 2,2.
$game->do_turn;

# Check bot and map state after turn 1 - new ant on position 1,2
is( $game->bot->map->dump(1), <<MAP_END, 'turn 1' );
. o o o . . . . . .
o % a o h . . . . .
. o f o . . . . . .
. . o . . . . . . .
. . . . . . . . . .
. . . . . . . . . .
. . . . . . . . . .
. . % . . . . . . .
MAP_END


# Prepare turn 2 game output and bot orders. Receive info about position 2,2
# where ant just moved.
$game->set_input(q(
    a 2 2 0
    f 2 0
    w 4 2
    f 1 4
    h 2 4 0
));
$bot->set_next_changes({
    # $x,$y   => [ $ant_num, $x, $y ]
    '3,2'     => [        1,  2,  2 ]
});

# Do turn 2. We moved on 2,2 and send we will stay there.
$game->do_turn;

my $map_obj = $game->bot->map;

# Checks after turn 2 - ant on position 2,2.
my $m_new = $map_obj->vis_cache_on_map( $game->bot->{m_new}, padding=>1 );
is( $map_obj->dump_map( $m_new, 'x' ), <<MAP_END, 'm_new' );
. . . . . . .
. . . . . . .
x . . . x . .
. x . x . . .
. . x . . . .
. . . . . . .
. . . . . . .
MAP_END


is( $game->bot->map->dump(1), <<MAP_END, 'turn 2' );
. o o o . . . . . .
o % o o f . . . . .
f o a o h . . . . .
. o o o . . . . . .
. . % . . . . . . .
. . . . . . . . . .
. . . . . . . . . .
. . % . . . . . . .
MAP_END


# one turn data
is_deeply(
    $map_obj->{otd}{food},
    {
        '2,0' => [ 2, 0 ],
        '1,4' => [ 1, 4 ],
    },
    'otd food'
);
is_deeply(
    $map_obj->{otd}{hive},
    { '2,4' => [ 2, 4, 0 ] },
    'otd hive'
);
is_deeply(
    $map_obj->{otd}{ant},
    { '2,2' => [ 2, 2, 0 ] },
    'otd ant'
);


is_deeply(
    [ $map_obj->get_nearest_free_food( 2,2, {} ) ],
    [ 2,0 ],
    'get_nearest_free_food'
);

is_deeply(
    [ $map_obj->get_nearest_free_food( 2,2, { "2,0" => 2 } ) ],
    [ 1,4 ],
    'get_nearest_free_food 2'
);


# Test bot->map internals.

my %vis_conf = ( negative=>1, padding=>1 );
my $m_cch = $map_obj->vis_cache_on_map( $game->bot->map->{vr}{m_cch}, %vis_conf );
$vis_conf{size} = $#$m_cch;
is( $map_obj->dump_map( $m_cch, 'x' ), <<MAP_END, 'm_cch' );
. . . . . . .
. . . x . . .
. . x x x . .
. x x x x x .
. . x x x . .
. . . x . . .
. . . . . . .
MAP_END


my $m_cch_move_a = $map_obj->vis_cache_on_map( $map_obj->{vr}{m_cch_move}{E}{a}, %vis_conf );
is(  $map_obj->dump_map( $m_cch_move_a, 'a' ), <<MAP_END, 'm_cch_move-E-a' );
. . . . . . .
. . . . a . .
. . . . . a .
. . . . . . a
. . . . . a .
. . . . a . .
. . . . . . .
MAP_END

my $m_cch_move_r = $map_obj->vis_cache_on_map( $map_obj->{vr}{m_cch_move}{E}{r}, %vis_conf );
is( $map_obj->dump_map( $m_cch_move_r, 'r' ), <<MAP_END, 'm_cch_move-E-r' );
. . . . . . .
. . . r . . .
. . r . . . .
. r . . . . .
. . r . . . .
. . . r . . .
. . . . . . .
MAP_END


done_testing();
