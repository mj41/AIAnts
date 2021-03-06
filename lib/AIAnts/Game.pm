package AIAnts::Game;

use strict;
use warnings;

use Carp qw(croak);
use Time::HiRes ();

use base 'AIAnts::Base';


=head1 NAME

AIAnts::Game

=head1 SYNOPSIS

Module for interacting with the Google AI Challenge 2011 "AI Ants" game.

=head1 METHODS

=head2 new

Constructor.

=cut

sub new {
    my ( $class, %args ) = @_;

    my $self = {
        config => undef,
        turn_num => 0,
    };
    bless $self, $class;

    $self->set_input_fh( %args );

    $self->{bot} = $args{bot};
    $self->{turn_as_hash} = $self->{bot}->do_turn_at_once();

    return $self;
}


=head2 set_input_fh

Set initialized file handle for input reading.

=cut

sub set_input_fh {
    my ( $self, %args ) = @_;

    # Use SIG{ALRM} to control/check maximum bot turntime.
    $self->{control_turntime} = $args{control_turntime} // 1;

    if ( defined $args{fh} ) {
        $self->{in_source} = 'fh';
        $self->{fh} = $args{fh};
        return 1;
    }

    if ( $args{in_fpath} ) {
        $self->{in_source} = 'fpath';
        my $fh;
        open($fh, '<', $args{in_fpath} )
            || croak "Can't open '$args{in_fpath}' for read: $!\n";
        $self->{fh} = $fh;
        return 1;
    }

    $self->{in_source} = 'stdin';
    $self->{fh} = \*STDIN;
    return 1;
}

=head2 get_next_input_line

Get next chomped line from filehandle.

=cut

sub get_next_input_line {
    my $self = shift;

    my $fh = $self->{fh};
    my $line = <$fh>;
    chomp( $line );
    return $line;
}

=head2 bot

Return bot object associated with this game.

=cut

sub bot {
    my $self = shift;
    return $self->{bot};
}


=head2 run

Game processing loop.

=cut

sub run {
    my $self = shift;

    $self->do_setup();

    while (1) {
        last unless $self->do_turn();
    }
    $self->game_over();
}

=head2 do_setup

Do all setup steps - parse_setup, setup and let game know you can begin.

=cut

sub do_setup {
    my $self = shift;
    $self->parse_setup();
    $self->setup();
    $self->my_say('go');
}

=head2 parse_setup

Game setup data parsing.

=cut

sub parse_setup {
    my $self = shift;

    my %contig_opts = (
        loadtime => 1,
        turntime => 1,
        rows => 1,
        cols => 1,
        turns => 1,
        viewradius2 => 1,
        attackradius2 => 1,
        spawnradius2 => 1,
        player_seed => 1,
    );

    while (1) {
        my $line = $self->get_next_input_line();
        next unless $line;
        last if $line eq 'ready';

        my ( $key, $value ) = split( /\s/, $line );
        if ( exists $contig_opts{$key} ) {
            $self->{config}{$key} = $value;
        }
    }

    return 1;
}

=head2 config

Return game parameters.

=cut

sub config {
    my $self = shift;
    return undef unless $self->{config};
    return %{ $self->{config} };
}

=head2 setup

Call setup on your bot.

=cut

sub setup {
    my $self = shift;
    $self->{bot}->setup( %{ $self->{config} } );
}

=head2 do_turn

Do one turn init_turn, parse_turn, turn. Return 0 if it was the last turn 1 otherwise.

=cut

sub do_turn {
    my $self = shift;

    my $turn_start_time = Time::HiRes::time();
    $self->{turn_num}++;
    $self->init_turn( $self->{turn_num} );
    my ( $last_cmd, $turn_data ) = $self->parse_turn();
    return 0 if $last_cmd eq 'end';

    if ( $self->{control_turntime} ) {
        $self->turn( $self->{turn_num}, $turn_data, $turn_start_time );
    } else {
        $self->turn_simple( $self->{turn_num}, $turn_data, $turn_start_time );
    }

    return 1;
}

=head2 init_turn

Call init_turn on your bot.

=cut

sub init_turn {
    my ( $self, $turn_num ) = @_;
    $self->{bot}->init_turn( $turn_num );
}

=head2 parse_turn

Parse game turn.

=cut

sub parse_turn {
    my $self = shift;

    my $line;
    my $turn_data = {
        water => {},
        m_ant => {},
        e_ant => {},
        food => {},
        corpse => {},
        m_hill => {},
        e_hill => {},
    };
    LINE: while (1) {
        $line = $self->get_next_input_line();
        next LINE unless $line;
        last LINE if $line eq 'go' || $line eq 'end';

        my ( $cmd, $x, $y, $owner ) = split( /\s/, $line );

        # turn as hash - save each item info to hash and send as turn parameter to bot
        if ( $self->{turn_as_hash} ) {
            if ( $cmd eq 'w' ) {
                $turn_data->{water}{"$x,$y"} = [ $x, $y ];
                next LINE;
            }
            if ( $cmd eq 'a' ) {
                if ( $owner == 0 ) {
                    $turn_data->{m_ant}{"$x,$y"} = [ $x, $y ];
                } else {
                    $turn_data->{e_ant}{"$x,$y"} = [ $x, $y, $owner ];
                }
                next LINE;
            }
            if ( $cmd eq 'f' ) {
                $turn_data->{food}{"$x,$y"} = [ $x, $y ];
                next LINE;
            }
            if ( $cmd eq 'c' ) {
                $turn_data->{corpse}{"$x,$y"} = [ $x, $y, $owner ];
                next LINE;
            }
            if ( $cmd eq 'h' ) {
                if ( $owner == 0 ) {
                    $turn_data->{m_hill}{"$x,$y"} = [ $x, $y ];
                } else {
                    $turn_data->{e_hill}{"$x,$y"} = [ $x, $y, $owner ];
                }
                next LINE;
            }
            next LINE;
        }

        # water
        if ( $cmd eq 'w' ) {
            $self->{bot}->set_water( $x, $y );
            next LINE;
        }

        # food
        if ( $cmd eq 'f' ) {
            $self->{bot}->set_food( $x, $y );
            next LINE;
        }

        # ant
        if ( $cmd eq 'a' ) {
            $self->{bot}->set_ant( $x, $y, $owner );
            next LINE;
        }

        # hill (ant hill)
        if ( $cmd eq 'h' ) {
            $self->{bot}->set_hill( $x, $y, $owner );
            next LINE;
        }

        # dead ant (corpse)
        if ( $cmd eq 'd' ) {
            $self->{bot}->set_corpse( $x, $y, $owner );
            next LINE;
        }
    }

    return ( $line, $turn_data );
}


=head2 turn_simple

Simple implementation of turn_method.

=cut

sub turn_simple {
    my ( $self, $turn_num, $turn_data, $turn_start_time ) = @_;

    $self->{bot}->turn(
        $turn_num,
        $turn_data,
        $turn_start_time+$self->{config}{turntime}/1000
    );
    $self->issue_bot_orders();
    return 1;
}

=head2 turn

This method is called each turn to generate orders.

=cut

sub turn {
    my ( $self, $turn_num, $turn_data, $turn_start_time ) = @_;

    my $remaining_turn_time_us = (
        $self->{config}{turntime}                             # allowed turn time in ms
        - int((Time::HiRes::time() - $turn_start_time)*1000)  # minus time already elapsed in ms
        - 3                                                   # minus miliseconds to process alarm sub
    ) * 1000;                                                 # form miliseconds to microseconds

    if ( $remaining_turn_time_us < 0 ) {
        $self->my_say('go');
        return 1;
    }

    eval {
        local $SIG{ALRM} = sub {
            die "aiants turntime reached";
        };
        # Remove next line to debug turntime ALRM signals. See MyBot.pl __DIE__.
        local $SIG{__DIE__} = 'IGNORE';

        Time::HiRes::ualarm( $remaining_turn_time_us );
        $self->{bot}->turn(
            $turn_num,
            $turn_data,
            $turn_start_time+$self->{config}{turntime}/1000
        );
    };
    Time::HiRes::ualarm(0);
    #$SIG{ALRM} = 'DEFAULT';

    if ( $@ ) {
        my $err = $@;
        if ( $err !~ /aiants turntime reached/ ) {
            $self->{bot}->log( sprintf("--- die %s %0.3f ms\n", $err, (Time::HiRes::time()-$turn_start_time)*1000) ) if $self->{bot}->{log};;
            die $err;
        }
    }

    $self->issue_bot_orders();
    $self->{bot}->log( sprintf("--- go send in %0.3f ms \n\n", (Time::HiRes::time()-$turn_start_time)*1000) ) if $self->{bot}->{log};;
    return 1;
}

=head2 issue_bot_orders

Method to issue an orders to the server prepared in bot object.

=cut

sub issue_bot_orders {
    my ( $self ) = @_;

    my $orders = $self->{bot}->get_orders_fast();
    foreach my $one_order ( @$orders ) {
        my ( $x, $y, $direction ) = @$one_order;
        $self->my_say(
            sprintf( 'o %d %d %s', $x, $y, $direction )
        );
    }
    $_[0]->my_say('go');
    return 1;
}

=head2 my_say

Method to print new line. Overwitten in tests.

=cut

sub my_say {
    shift;
    print @_;
    print "\n";
}

=head2 game_over

You may optionally override setup() in your own bot.

It is called after the initial configuration data is sent from the server.

=cut

sub game_over {
    my $self = shift;
    $self->{bot}->game_over();

    # close input file
    if ( $self->{in_fpath} ) {
        $self->{fh}->close();
    }

    return 1;
}


=head1 AUTHOR

Michal Jurosz, mj@mj41.cz

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut

1;
