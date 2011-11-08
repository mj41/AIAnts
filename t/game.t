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
    in_fpath => 't/data/game-small.txt',
);

my @out;
no warnings 'redefine';
*AIAnts::Game::my_say = sub { 
    shift @_;
    push @out, [ @_ ];
};

my $game = new AIAnts::Game( %game_conf );
$game->run;

my %game_config = $game->config;
is( $game_config{rows}, 3, 'config rows' );
is( $game_config{cols}, 4, 'config cols' );

my $dp = $game->bot->map->dump(1,0);
is(
    $dp, 
      ". % % .\n"
    . ". a a .\n"
    . ". f . .\n",
    'map dump'
);

is_deeply( 
    \@out,
    [
        [ 'go' ],
        [ 'go' ],
        [ 'go' ],
    ],
    'output'
);

done_testing();
