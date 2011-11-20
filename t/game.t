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
    in_fpath => 't/data/game-small.txt',
);
$game->run;

my %game_config = $game->config;
is( $game_config{rows}, 3, 'config rows' );
is( $game_config{cols}, 4, 'config cols' );

my $dp = $game->bot->map->dump(1,0);
is(
    $dp,
      "o % % .\n"
    . "o a b .\n"
    . "o f 2 .\n",
    'map dump'
);

is_deeply(
    $game->get_output,
    "go\ngo\n",
    'output'
);

done_testing();
