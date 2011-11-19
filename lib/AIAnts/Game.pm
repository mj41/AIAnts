package AIAnts::Game;

use strict;
use warnings;
use Carp qw(croak);

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

    $self->{turn_num}++;
    $self->init_turn( $self->{turn_num} );
    my ( $last_cmd, $turn_data ) = $self->parse_turn();
    return 0 if $last_cmd eq 'end';
    $self->turn( $self->{turn_num}, $turn_data );
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
        ant => {},
        food => {},
        corpse => {},
        hill => {},
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
                $turn_data->{ant}{"$x,$y"} = [ $x, $y, $owner ];
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
                $turn_data->{hill}{"$x,$y"} = [ $x, $y, $owner ];
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

=head2 turn

This method is called each turn to generate orders. Call orders method on bot object.

=cut

sub turn {
    my ( $self, $turn_num, $turn_data ) = @_;
    my ( @orders ) = $self->{bot}->turn( $turn_num, $turn_data );
    foreach my $order ( @orders ) {
        $self->issue_order( @$order );
    }
    $self->my_say('go');
    return 1;
}

=head2 issue_order

Method to issue an order to the server.

=cut

sub issue_order {
    my ( $self, $x, $y, $direction ) = @_;
    $self->my_say(
        sprintf( 'o %d %d %s', $x, $y, $direction )
    );
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
