use strict;
use warnings;

use Test::More;

use lib 'lib';
use AIAnts::Map;

my $mp;

$mp = new AIAnts::Map(
	cols => 3,
	rows => 2,
	viewradius2 => 4,
	attackradius2 => 3,
	spawnradius2 => 2,
);
is( ref $mp, 'AIAnts::Map', 'new' );

my $dp = $mp->dump(0,1);
is(
	$dp,
	  "00 00 00\n"
	. "00 00 00\n", 
	'dump'
);

done_testing();
