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
        corpses => undef,
        ants => undef,
        config => undef,

    };
    bless $self, $class;

    $self->{fh} = $self->get_input_fh( %args );
    $self->{bot} = $args{bot};
	return $self;
}


=head2 get_input_fh

Return initialized file handle for input reading.

=cut

sub get_input_fh {
	my ( $self, %args ) = @_;

	return $args{fh} if defined $args{fh};

	if ( $args{in_fpath} ) {
		my $fh;
		open($fh, '<', $args{in_fpath} )
			|| croak "Can't open '$args{in_fpath}' for read: $!\n";
		return $fh;
	}

    return \*STDIN;
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

	$self->parse_setup();
	$self->setup();

	while (1) {
		$self->init_turn();
		my $last_cmd = $self->parse_turn();
		last if $last_cmd eq 'end';
		$self->turn();
	}

	$self->game_over();
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

    my $fh = $self->{fh};
    while (1) {
        my $line = <$fh>;
        chomp( $line );
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

=head2 init_turn

Call init_turn on your bot.

=cut

sub init_turn {
    my $self = shift;
    $self->{bot}->init_turn();
}

=head2 parse_turn

Parse game turn.

=cut

sub parse_turn {
    my $self = shift;

    my $fh = $self->{fh};
    my $line;
    while (1) {
        $line = <$fh>;
        chomp( $line );
        last if $line eq 'go' || $line eq 'end';
        next unless $line;

        my ( $cmd, $x, $y, $owner ) = split( /\s/, $line );

		# water
        if ( $cmd eq 'w' ) {
        	$self->{bot}->set_water( $x, $y );

		# food
        } elsif ( $cmd eq 'f' ) {
        	$self->{bot}->set_food( $x, $y );

		# ant
        } elsif ( $cmd eq 'a' ) {
        	$self->{bot}->set_ant( $x, $y, $owner );

		# hive (ant hill)
        } elsif ( $cmd eq 'h' ) {
        	$self->{bot}->set_hive( $x, $y, $owner );

		# dead ant (corpse)
        } elsif ( $cmd eq 'd' ) {
        	$self->{bot}->set_corpse( $x, $y, $owner );
        }
	}

	return $line;
}

=head2 turn

This method is called each turn to generate orders. Call orders method on bot object.

=cut

sub turn {
    my $self = shift;
    my @orders = $self->{bot}->orders();
    foreach my $order ( @orders ) {
    	$self->issue_order( @$order );
    }

    $self->my_say('go');
}

=head2 issue_order

Method to issue an order to the server.

=cut

sub issue_order {
    my ($self, $x, $y, $direction) = @_;
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
