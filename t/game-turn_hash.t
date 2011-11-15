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

my $dp = $game->bot->map->dump(1,1);
is(
    $dp,
      ". % % .   00 02 02 00\n"
    . ". a a .   00 17 16 00\n"
    . ". f . .   00 04 00 00\n",
    'map dump'
);

is_deeply(
    $game->get_output,
    "go\ngo\n",
    'output'
);

done_testing();
