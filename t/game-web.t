use strict;
use warnings;

use Test::More;

use lib 'lib';
use lib 't/lib';
use AIAnts::TestBotSimple;
use AIAnts::TestGame;

my $bot = AIAnts::TestBotSimple->new();
my $game = new AIAnts::TestGame(
    bot => $bot,
    in_fpath => 't/data/game-web.txt',
);
$game->run;

my ( $map_dump, $ok_map );

$map_dump = $game->bot->map->dump(1,0,show_explored=>0);
$ok_map = <<DATA_END;
. . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . .
. . h . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . .
. . . . . f . . . . . . . . . . . . . .
. . . . . . % . . a . . h . . . . . . .
. . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . .
. . . . . . . . a a . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . .
DATA_END

is( $map_dump, $ok_map, 'map dump' );

done_testing();
