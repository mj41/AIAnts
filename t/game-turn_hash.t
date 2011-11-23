use strict;
use warnings;

use Test::More;

use lib 'lib';
use lib 'lib-ex';
use lib 't/lib';
use AIAnts::TestBotHash;
use AIAnts::TestGame;

my $bot = AIAnts::TestBotHash->new();
my $game = new AIAnts::TestGame(
    bot => $bot,
    in_fpath => 't/data/game-medium.txt',
);
$game->run;

my $dp = $game->bot->map->dump(1,1);


is(
    $dp,
      "% % o o %     3   3   1   1   3\n"
    . "o a b . .     1  41  65   0   0\n"
    . "o f c 2 o     1   5  65  17   1\n"
    . ". . o a o     0   0   1  41   1\n",
    'map dump'
);

is_deeply(
    $game->get_output,
    "go\ngo\n",
    'output'
);

done_testing();
