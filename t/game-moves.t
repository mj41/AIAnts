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


$game->set_input(q(
    a 1 2 0
    w 1 1
    w 7 2
));
$bot->set_next_changes({
    # $Nx,$Ny => [ $ant_num, $x, $y, $dir, $Nx, $Ny ]
    '2,2'     => [        1,  1,  2,  'S',   2,   2 ]
});
$game->do_turn;
is( $game->bot->map->dump(1), <<MAP_END, 'turn 1' );
. o o o . . . . . .
o % o o o . . . . .
. o o o . . . . . .
. . o . . . . . . .
. . . . . . . . . .
. . . . . . . . . .
. . . . . . . . . .
. . % . . . . . . .
MAP_END

#use Data::Dumper; print Dumper( $game->bot );

$game->set_input(q(
    a 2 2 0
    f 0 1
    w 4 2
));
$bot->set_next_changes({
    # $Nx,$Ny => [ $ant_num, $x, $y, $dir, $Nx, $Ny ]
    '3,2'     => [        1,  2,  2,  'S',   3,   2 ]
});
$game->do_turn;
is( $game->bot->map->dump(1), <<MAP_END, 'turn 2' );
. o o o . . . . . .
o % o o o . . . . .
o o o o o . . . . .
. o o o . . . . . .
. . % . . . . . . .
. . . . . . . . . .
. . . . . . . . . .
. . % . . . . . . .
MAP_END

# Test bot->map internals.
my $map_obj = $game->bot->map;

my $m_cch = $map_obj->vis_cache_on_map( $game->bot->map->{vr}{m_cch}, undef, 1 );
my $mx = $#$m_cch;
is( $map_obj->dump_map( $m_cch, 'x' ), <<MAP_END, 'm_cch' );
. . . . . . .
. . . x . . .
. . x x x . .
. x x x x x .
. . x x x . .
. . . x . . .
. . . . . . .
MAP_END

my $m_cch_move_a = $map_obj->vis_cache_on_map( $map_obj->{vr}{m_cch_move}{E}{a}, $mx );
is(  $map_obj->dump_map( $m_cch_move_a, 'a' ), <<MAP_END, 'm_cch_move-E-a' );
. . . . . . .
. . . . a . .
. . . . . a .
. . . . . . a
. . . . . a .
. . . . a . .
. . . . . . .
MAP_END

my $m_cch_move_r = $map_obj->vis_cache_on_map( $map_obj->{vr}{m_cch_move}{E}{r}, $mx );
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
