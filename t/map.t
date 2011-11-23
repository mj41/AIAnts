use strict;
use warnings;

use Test::More;

use lib 'lib';
use AIAnts::Map;

my $mp;

$mp = new AIAnts::Map(
    rows => 2,  # x (vertical)   m_x+1
    cols => 3,  # y (horizontal) m_y+1
    viewradius2 => 4,
    attackradius2 => 3,
    spawnradius2 => 2,
);
isa_ok($mp, 'AIAnts::Map', 'isa' );
isa_ok($mp, 'AI::Pathfinding::AStar', 'isa parent');

my $dp = $mp->dump(0,1);
is(
    $dp,
      "  0   0   0\n"    # ---> y  [0,0] [0,1] [0,2]
    . "  0   0   0\n",   # |       [1,0] [1,1] [1,2]
    'dump'            # v
);                    # x

my ( $x, $y );

( $x, $y ) = $mp->pos_plus( 0, 0, 1, 1 );
is ( $x, 1, 'pos_plus x 0 +1' );
is ( $y, 1, 'pos_plus y 0 +1' );

( $x, $y ) = $mp->pos_plus( 1, 1, 2, 2 );
is ( $x, 1, 'pos_plus x 1 +2' );
is ( $y, 0, 'pos_plus y 1 +2' );

( $x, $y ) = $mp->pos_plus( 0, 0, -1, -1 );
is ( $x, 1, 'pos_plus min x 0 -1' );
is ( $y, 2, 'pos_plus min y 0 -1' );

( $x, $y ) = $mp->pos_plus( 1, 1, -3, -3 );
is ( $x, 0, 'pos_plus min x 1 -3' );
is ( $y, 1, 'pos_plus min y 1 -3' );


#   N
# W   E
#   S

( $x, $y ) = $mp->pos_dir_step( 0, 2, 'N' );
is ( $x, 1, 'pos_dir_step N x' );
is ( $y, 2, 'pos_dir_step N y' );
( $x, $y ) = $mp->pos_dir_step( 1, 2, 'N' );
is ( $x, 0, 'pos_dir_step N x' );
is ( $y, 2, 'pos_dir_step N y' );

( $x, $y ) = $mp->pos_dir_step( 0, 2, 'S' );
is ( $x, 1, 'pos_dir_step S x' );
is ( $y, 2, 'pos_dir_step S y' );
( $x, $y ) = $mp->pos_dir_step( 1, 2, 'S' );
is ( $x, 0, 'pos_dir_step S x' );
is ( $y, 2, 'pos_dir_step S y' );

( $x, $y ) = $mp->pos_dir_step( 0, 2, 'W' );
is ( $x, 0, 'pos_dir_step W x' );
is ( $y, 1, 'pos_dir_step W y' );
( $x, $y ) = $mp->pos_dir_step( 0, 0, 'W' );
is ( $x, 0, 'pos_dir_step W x' );
is ( $y, 2, 'pos_dir_step W y' );

( $x, $y ) = $mp->pos_dir_step( 0, 2, 'E' );
is ( $x, 0, 'pos_dir_step E x' );
is ( $y, 0, 'pos_dir_step E y' );
( $x, $y ) = $mp->pos_dir_step( 0, 0, 'E' );
is ( $x, 0, 'pos_dir_step E x' );
is ( $y, 1, 'pos_dir_step E y' );


# ---> y  [0,0] [0,1] [0,2]
# |       [1,0] [1,1] [1,2]
# v
# x

is_deeply [ $mp->dist( 0,0, 0,0 ) ],  [ 0,0, 0,0 ], 'dist 0';

is_deeply [ $mp->dist( 0,0, 1,0 ) ],  [ 1,1, 0,0 ], 'dist x';
is_deeply [ $mp->dist( 0,0, 0,1 ) ],  [ 0,0, 1,1 ], 'dist y';
is_deeply [ $mp->dist( 0,0, 1,1 ) ],  [ 1,1, 1,1 ], 'dist x,y';

is_deeply [ $mp->dist( 1,0, 0,0 ) ],  [ 1,-1,  0,0 ],  'dist op x';
is_deeply [ $mp->dist( 0,1, 0,0 ) ],  [ 0,0,   1,-1 ], 'dist op y';
is_deeply [ $mp->dist( 1,1, 0,0 ) ],  [ 1,-1,  1,-1 ], 'dist op x,y';

is_deeply [ $mp->dist( 0,0, 0,2 ) ],  [ 0,0,   1,-1 ], 'dist y over';
is_deeply [ $mp->dist( 0,2, 0,0 ) ],  [ 0,0,   1, 1 ], 'dist op y over';


# dir_from_to_easy
is_deeply [ $mp->dir_from_to_easy( 0,0, 0,0 ) ], [], 'dir_from_to_easy none';
is_deeply [ $mp->dir_from_to_easy( 0,0, 1,0 ) ], [ 'S',1,0 ], 'dir_from_to_easy x';
is_deeply [ $mp->dir_from_to_easy( 1,0, 0,0 ) ], [ 'N',0,0 ], 'dir_from_to_easy op x';
is_deeply [ $mp->dir_from_to_easy( 0,1, 0,2 ) ], [ 'E',0,2 ], 'dir_from_to_easy y';
is_deeply [ $mp->dir_from_to_easy( 0,2, 0,1 ) ], [ 'W',0,1 ], 'dir_from_to_easy op y';

is_deeply [ $mp->dir_from_to_easy( 0,1, 1,2 ) ], [ 'S',1,1 ], 'dir_from_to_easy x=y, x';
is_deeply [ $mp->dir_from_to_easy( 1,2, 0,1 ) ], [ 'N',0,2 ], 'dir_from_to_easy op x=y, x';

is_deeply [ $mp->dir_from_to_easy( 0,2, 0,0 ) ], [ 'E',0,0 ], 'dir_from_to_easy y over';
is_deeply [ $mp->dir_from_to_easy( 0,0, 0,2 ) ], [ 'W',0,2 ], 'dir_from_to_easy op y over';


# pos_step_to_dir - for map 6 x 6
is $mp->pos_step_to_dir( 0,2, 0,3 ), 'E', 'pos_step_to_dir 0,2 -> 0,3 E';
is $mp->pos_step_to_dir( 0,3, 0,2 ), 'W', 'pos_step_to_dir 0,3 -> 0,2 W';

is $mp->pos_step_to_dir( 0,0, 0,1 ), 'E', 'pos_step_to_dir 0,0 -> 0,1 E';
is $mp->pos_step_to_dir( 0,1, 0,0 ), 'W', 'pos_step_to_dir 0,1 -> 0,0 W';

is $mp->pos_step_to_dir( 0,0, 0,5 ), 'W', 'pos_step_to_dir 0,0 -> 0,5 W';
is $mp->pos_step_to_dir( 0,5, 0,0 ), 'E', 'pos_step_to_dir 0,5 -> 0,0 E';


is $mp->pos_step_to_dir( 2,0, 3,0 ), 'S', 'pos_step_to_dir 2,0 -> 3,0 S';
is $mp->pos_step_to_dir( 3,0, 2,0 ), 'N', 'pos_step_to_dir 3,0 -> 2,0 N';

is $mp->pos_step_to_dir( 0,0, 1,0 ), 'S', 'pos_step_to_dir 0,0 -> 1,0 S';
is $mp->pos_step_to_dir( 1,0, 0,0 ), 'N', 'pos_step_to_dir 1,0 -> 0,0 N';

is $mp->pos_step_to_dir( 0,0, 5,0 ), 'N', 'pos_step_to_dir 0,0 -> 5,0 N';
is $mp->pos_step_to_dir( 5,0, 0,0 ), 'S', 'pos_step_to_dir 5,0 -> 0,0 S';


# str_path_from_to
is_deeply $mp->str_path_from_to( 0,0, 0,0 ), [], 'str_path_from_to 0,0 -> 0,0';

is_deeply $mp->str_path_from_to( 0,0, 0,1 ), ['0,1'], 'str_path_from_to 0,0 -> 0,1';
is_deeply $mp->str_path_from_to( 0,0, 0,2 ), ['0,2'], 'str_path_from_to 0,0 -> 0,2';
is_deeply $mp->str_path_from_to( 0,0, 1,0 ), ['1,0'], 'str_path_from_to 0,0 -> 1,0';

is_deeply $mp->str_path_from_to( 0,1, 0,0 ), ['0,0'], 'str_path_from_to 0,0 <- 0,1';
is_deeply $mp->str_path_from_to( 0,2, 0,0 ), ['0,0'], 'str_path_from_to 0,0 <- 0,2';
is_deeply $mp->str_path_from_to( 1,0, 0,0 ), ['0,0'], 'str_path_from_to 0,0 <- 1,0';


# dirs_path_from_to
is_deeply $mp->dirs_path_from_to( 0,0, 0,0 ), [], 'dirs_path_from_to 0,0 -> 0,0';

is_deeply $mp->dirs_path_from_to( 0,0, 0,1 ), [ ['E',0,1] ], 'dirs_path_from_to 0,0 -> 0,1';
is_deeply $mp->dirs_path_from_to( 0,0, 0,2 ), [ ['W',0,2] ], 'dirs_path_from_to 0,0 -> 0,2';
is_deeply $mp->dirs_path_from_to( 0,0, 1,0 ), [ ['S',1,0] ], 'dirs_path_from_to 0,0 -> 1,0';

is_deeply $mp->dirs_path_from_to( 0,1, 0,0 ), [ ['W',0,0] ], 'dirs_path_from_to 0,0 <- 0,1';
is_deeply $mp->dirs_path_from_to( 0,2, 0,0 ), [ ['E',0,0] ], 'dirs_path_from_to 0,0 <- 0,2';
is_deeply $mp->dirs_path_from_to( 1,0, 0,0 ), [ ['N',0,0] ], 'dirs_path_from_to 0,0 <- 1,0';


done_testing();
