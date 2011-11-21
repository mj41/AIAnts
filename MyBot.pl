#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;

use lib "$FindBin::Bin";
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/bots";

use AIAnts::Game;

BEGIN {
    my $bot_impl = $ARGV[0] || '';
    if ( $bot_impl ne '' ) {
        require $bot_impl;
    } else {
        require 'MyBot.pm';
    }
}


my $log_fpath = $ARGV[1] || undef;  # log file path
my $ver = $ARGV[2] // 1;            # verbose level
my $in_fpath = $ARGV[3];            # input (game commands) file path



# make unbuffered
select STDIN; $| = 1;
select STDERR; $| = 1;
select STDOUT; $| = 1;

if ( $ver >= 1 ) {
    binmode(STDOUT, ":utf8"); # utf8 output (usefull for debug mode)
}

if ( $ver >= 5 ) {
    print "input file: $in_fpath\n";
    print "verbose level: $ver\n";
    print "log to file: $log_fpath\n";
}


my $bot = MyBot->new(
    ver => $ver,
    log_fpath => $log_fpath,
    map => {
        o_utf8 => 0,
    },
);

my %game_conf = (
    bot => $bot,
    ver => $ver,
    in_fpath => $in_fpath,
    control_turntime => 1,
);

my $game = new AIAnts::Game( %game_conf );
$game->run;

if ( $ver >= 5 ) {
    print $game->bot->map->dump(1);
}

