use strict;
use warnings;

use Test::More;

use lib 'lib';
use AIAnts::Map;

my $mp = new AIAnts::Map(
	cols => 6,
	rows => 6,
	viewradius2 => 4,
	attackradius2 => 3,
	spawnradius2 => 2,
	o_utf8 => 1,
	o_line_prefix => '# ',
);
is( ref $mp, 'AIAnts::Map', 'new' );
binmode(STDOUT, ":utf8");

$mp->set_explored( 2, 2 );

$mp->set( 'food', 5, 5 );

$mp->set( 'water', 5, 4 );
$mp->set( 'water', 5, 3 );

$mp->set_explored( 3, 3 );

print $mp->dump(1);

my $mp_dump = $mp->dump( 1, 0, o_line_prefix=>'' );
is( substr($mp_dump,0,1), chr(0x00B7), 'first char of map utf8 dump' );

done_testing();
