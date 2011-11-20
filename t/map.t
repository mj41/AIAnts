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
is( ref $mp, 'AIAnts::Map', 'new' );

my $dp = $mp->dump(0,1);
is(
    $dp,
      "  0   0   0\n"    # ---> y  [0,0] [0,1] [0,2]
    . "  0   0   0\n",   # |       [1,0] [1,1] [1,2]
    'dump'            # v
);                    # x

my ( $x, $y );

( $x, $y ) = $mp->pos_plus( 0, 0, 1, 1 );
is ( $x, 1, 'pos_plus in x' );
is ( $y, 1, 'pos_plus in y' );

( $x, $y ) = $mp->pos_plus( 1, 1, 2, 2 );
is ( $x, 1, 'pos_plus max x' );
is ( $y, 0, 'pos_plus max y' );

( $x, $y ) = $mp->pos_plus( 1, 1, -3, -3 );
is ( $x, 0, 'pos_plus min x' );
is ( $y, 1, 'pos_plus min y' );



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


# dir_from_to
is_deeply [ $mp->dir_from_to( 0,0, 0,0 ) ], [], 'dir_from_to none';
is_deeply [ $mp->dir_from_to( 0,0, 1,0 ) ], [ 'S',1,0 ], 'dir_from_to x';
is_deeply [ $mp->dir_from_to( 1,0, 0,0 ) ], [ 'N',0,0 ], 'dir_from_to op x';
is_deeply [ $mp->dir_from_to( 0,1, 0,2 ) ], [ 'E',0,2 ], 'dir_from_to y';
is_deeply [ $mp->dir_from_to( 0,2, 0,1 ) ], [ 'W',0,1 ], 'dir_from_to op y';

is_deeply [ $mp->dir_from_to( 0,1, 1,2 ) ], [ 'S',1,1 ], 'dir_from_to x=y, x';
is_deeply [ $mp->dir_from_to( 1,2, 0,1 ) ], [ 'N',0,2 ], 'dir_from_to op x=y, x';

is_deeply [ $mp->dir_from_to( 0,2, 0,0 ) ], [ 'E',0,0 ], 'dir_from_to y over';
is_deeply [ $mp->dir_from_to( 0,0, 0,2 ) ], [ 'W',0,2 ], 'dir_from_to op y over';

done_testing();
