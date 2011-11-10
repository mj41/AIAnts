use strict;
use warnings;

use Test::More;

use lib 'lib';
use lib 't/lib';
use AIAnts::TestBotHash;
use AIAnts::TestGame;

my $bot = AIAnts::TestBotHash->new();
my $game = new AIAnts::TestGame(
    bot => $bot,
    in_fpath => 't/data/game-small.txt',
);
$game->run;

my $dp = $game->bot->map->dump(1,0);
is(
    $dp,
      ". % % .\n"
    . ". o . .\n"
    . ". . . .\n",
    'map dump'
);

is_deeply(
    $game->get_output,
    "go\ngo\ngo\n",
    'output'
);

done_testing();
