use strict;
use warnings;

use Test::More;

use lib 'lib';
use AIAnts::Map;

my $mp;

$mp = new AIAnts::Map( cols => 3,rows => 2 );
is( ref $mp, 'AIAnts::Map', 'new' );

binmode(STDOUT, ":utf8");

$mp = new AIAnts::Map( 
	cols => 6,
	rows => 6,
	viewradius2 => 4,
	o_line_prefix => '# ',
);
$mp->set_view( 2, 2 );

$mp->set( 'food', 5, 5 );

$mp->set( 'water', 5, 4 );
$mp->set( 'water', 5, 3 );

$mp->set_view( 5, 5 );

print $mp->dump( 1 );

done_testing();
