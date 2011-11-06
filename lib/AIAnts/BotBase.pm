package AIAnts::BotBase;

use strict;
use warnings;
use Carp qw(carp croak);

use AIAnts::Map;

=head1 NAME

AIAnts::BotBase

=head1 SYNOPSIS

Base class for AIAnts bot.

=head1 METHODS

=head2 new

Constructor.

=cut

sub new {
    my ( $class, %args ) = @_;

    my $self = {
    	# my ants
    	ants => 0,
    	my_ants => {},
    };
    $self->{ver} = $args{ver} // 1;
    $self->{log_fpath} = $args{log_fpath} // 0;
    $self->{log} = $self->{log_fpath} ? 1 : 0;
    $self->{map_args} = $args{map} // {};

    bless $self, $class;
}

=head2 map

Return map objects (instance of AIAnts::Map).

=cut

sub map {
	$_[0]->{m}
}

=head2 setup

Called once, after the game parameters are parsed and game is 'ready'.

=cut

sub setup {
    my ( $self, %config ) = @_;

	$self->{m} = new AIAnts::Map(
		cols => $config{cols},
		rows => $config{rows},
		viewradius2 => $config{viewradius2},
		%{ $self->{map_args} }
	);
	$self->log( '', 1 ) if $self->{log};
	#$self->log( $self->{m}->dump(1) );
}

=head2 init_turn

Called before new turn params are parser and set_* methods called.

=cut

sub init_turn {
	my ( $self ) = @_;
}

=head2 set_water

Called when 'water' position parsed.

=cut

sub set_water {
	my ( $self, $x, $y ) = @_;
	return $self->{m}->set( 'water', $x, $y );
}

=head2 set_food

Called when 'food' position parsed.

=cut

sub set_food {
	my ( $self, $x, $y ) = @_;
	return $self->{m}->set( 'food', $x, $y );
}

=head2 set_ant

Set map position to 'water', 'food' or 'corpse'.

=cut

sub set_ant {
	my ( $self, $x, $y, $owner ) = @_;

	if ( $owner eq '0' ) {
		$self->{ants}++;
		my $ants = $self->{ants};
		$self->{my_ants}{ $ants } = [ $x, $y ];

	} else {
		$self->{my_ants}{ $owner } = [] unless exists $self->{my_ants}{ $owner };
		push @{ $self->{my_ants}{ $owner } }, [ $x, $y ];
	}

	return 1;
}

=head2 set_hive

Called when 'hive' position parsed.

=cut

sub set_hive {
	my ( $self, $x, $y, $owner ) = @_;
	return 1;
}


=head2 orders

Return array of array refs with commands (ants movements).

 return ( [ 1, 1, 'E' ], [ 1, 2, 'S' ] ); # move ant [1,1] east (y++) and ant [1,2] south (x++)

=cut

sub orders {
    my $self = shift;

	#use Data::Dumper;  print Dumper( $self->{my_ants} );

	# ( [ 1, 1, 'W' ] );
	return ();
}

=head2 game_over

Called when game ends.

=cut

sub game_over {
	my ( $self ) = @_;
	$self->log( $self->{m}->dump(1) . "\n\n" ) if $self->{log};
}

=head2 log

Append string to log file.

 $self->log('',1); # empty (truncate) log file
 $self->log( "text\n" ); # append line with string 'text' to log file

=cut

sub log {
	my ( $self, $str, $truncate ) = @_;

	open(my $fh, '>>:utf8', $self->{log_fpath} )
		|| croak "Can't open '$self->{log_fpath}' for write: $!\n";
	truncate($fh, 0) if $truncate;
	print $fh $str;
	close $fh;
}


=head1 AUTHOR

Michal Jurosz, mj@mj41.cz

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut

1;
