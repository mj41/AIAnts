use strict;
use warnings;

use Test::More;

use lib 'lib';
use AIAnts::BotBase;
use AIAnts::Game;

my $bot = AIAnts::BotBase->new(
	map => {
		o_utf8 => 0,
	},
);
my %game_conf = (
	bot => $bot,
	in_fpath => 't/data/game-web.txt',
);

no warnings 'redefine';
*AIAnts::Game::my_say = sub {};

my $game = new AIAnts::Game( %game_conf );
$game->run;

my $map_dump = $game->bot->map->dump(1,0);

my $ok_map = <<DATA_END;
. . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . .
. . . . . f . . . . . . . . . . . . . .
. . . . . . % . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . .
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
