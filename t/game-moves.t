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
    viewradius2 4
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

=pod

Map

. o f o . .
o % o o f .
o o a f h .
. o o o . .
. . % . . .

Part of map ants see

. . f . . .
. % o o . .
o o a f h .
. o o o . .
. . % . . .

=cut

# So game should send (in clock order)
$game->set_input(q(
    a 2 2 0
    f 0 2
    f 2 3
    h 2 4 0
    w 4 2
    w 1 1
));
$bot->set_next_changes({
    # $Nx,$Ny => [ $ant_num, $x, $y, $dir, $Nx, $Ny ]
    '2,1'     => [        1,  2,  2,  'W',   2,   1 ]
});

# Do turn 2. We moved on 2,2 and next stop is 1,2.
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
. o f o . . . . . .
o % o o o . . . . .
o o a f h . . . . .
. o o o . . . . . .
. . % . . . . . . .
. . . . . . . . . .
. . . . . . . . . .
. . % . . . . . . .
MAP_END


# One turn data after turn 2.
is_deeply(
    $map_obj->{otd}{food},
    {
        '0,2' => [ 0, 2 ],
        '2,3' => [ 2, 3 ],
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
    [ 2,3 ],
    'get_nearest_free_food'
);

is_deeply(
    [ $map_obj->get_nearest_free_food( 2,2, { "2,3" => 1 } ) ],
    [ 0,2 ],
    'get_nearest_free_food 2'
);



# Prepare turn 3 game output and bot orders. Receive info about position 1,2
# where ant just moved.

=pod

Game engine phases: move, attack, raze, gather, spawn

Map

. f o o o . . . . .
o % o o f o . . . .
f a o o a o f . . h
o o o o o o . . . .
. % % . % . . . . .

Part of map ants see

. f o . o . . . . .
o % o o f o . . . .
f a o o a o f . . h
o o o o o o . . . .
. % . . % . . . . .

=cut

$game->set_input(q(
    a 2 1 0
    w 1 1
    f 0 1
    w 4 1
    f 2 0
    h 2 9 1
    a 2 4 0
    f 1 4
    f 2 6
    w 4 4
));
$bot->set_next_changes({
    # $x,$y   => [ $ant_num, $x, $y ]
    '2,1'     => [        1,  2,  1 ],
    '2,4'     => [        2,  2,  4 ],
});

# Do turn 3. We moved on 2,1 and set we will stay there.
$game->do_turn;

is_deeply(
    $map_obj->{otd}{ant},
    { '2,1' => [ 2, 1, 0 ], '2,4' => [ 2, 4, 0 ] },
    'turn 3 - otd ant'
);

is( $game->bot->map->dump(1), <<MAP_END, 'turn 3' );
. f o o o . . . . .
o % o o f o . . . .
f a o o a o f . . h
o o o o o o . . . .
. % % . % . . . . .
. . . . . . . . . .
. . . . . . . . . .
. . % . . . . . . .
MAP_END


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



my $dist_cch = $map_obj->vis_cache_on_map( $map_obj->{dist_cch}{4}, %vis_conf );
is( $map_obj->dump_map( $dist_cch, 'x' ), <<MAP_END, 'dist_cch' );
. . . . . . .
. . x . x . .
. x . . . x .
. . . . . . .
. x . . . x .
. . x . x . .
. . . . . . .
MAP_END


done_testing();
