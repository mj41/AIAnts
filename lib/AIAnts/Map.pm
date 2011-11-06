package AIAnts::Map;

use strict;
use warnings;

use utf8;

=head1 NAME

AI::Game

=head1 SYNOPSIS

Module for interacting with the Google AI Challenge 2011 "AI Ants" game.

=head1 METHODS

=head2 new

Constructor.

=cut

sub new {
    my ( $class, %args ) = @_;
    
    my $self = {
    	mx => $args{rows}-1,
    	my => $args{cols}-1,
    	m => [],
    };
    bless $self, $class;

	$self->init_map();
    $self->init_viewradius( $args{viewradius2} // 16 );

	$self->{o_bits} = {
		unknown  => 0,    #  0
		explored => 2**0, #  1
		water    => 2**1, #  2
		food     => 2**2, #  4
		hive     => 2**3, #  8
		ant      => 2**4, # 16
	};

	$self->{o_utf8} = $args{o_utf8} // 1;
	$self->{o_line_prefix} = $args{o_line_prefix} // '';
	$self->{o_chars} = {
		unknown  => [ '.', chr(0x00B7)  ],
		explored => [ 'o', chr(0x2022)  ],
		water    => [ '%', chr(0x25A0)  ],
		food     => [ 'f', chr(0x2740)  ],
		hive     => [ 'h', chr(0x27D0)  ],
		ant      => [ 'a', chr(0x10312) ],
	};
	
    return $self;
}

=head2 init_map

Initialize map to zeros.

=cut

sub init_map {
	my ( $self ) = @_;

	foreach my $x ( 0..$self->{mx} ) {
		# todo - optimize - better syntax?
		foreach my $y ( 0..$self->{my} ) {
			$self->{m}[$x][$y] = 0;
		}
	}
	return 1;
}

=head2 init_viewradius

Init helper parameter for computation with viewradius.

=cut

sub init_viewradius {
	my ( $self, $vr2 ) = @_;

	my $vm_distance = int sqrt( $vr2 );
	return 1 unless $vm_distance;
	
	my $vr_map = [
		[0,0]
	];
	foreach my $x ( 0..$vm_distance ) {
		foreach my $y ( 0..$vm_distance ) {
			next if $x == 0 && $y == 0;
			if ( ($x*$x + $y*$y) < $vr2 ) {
				push @$vr_map, [ +$x, +$y ];
				push @$vr_map, [ -$x, +$y ];
				push @$vr_map, [ +$x, -$y ];
				push @$vr_map, [ -$x, -$y ];
			}
		}
	}

	$self->{vr2} = $vr2;
	$self->{vr_map} = $vr_map;
	return 1;
}

=head2 new

Return map dumped to ascii/utf8.

 print $map->dump(1,0); # will dump normal ascii/utf8
 print $map->dump(0,1); # dump internal values of map

=cut

sub dump {
	my ( $self, $normal, $view ) = @_;
	
	my $out = '';
	my ( $x, $y );
	foreach $x ( 0..$self->{mx} ) {
		$out .= $self->{o_line_prefix};
		if ( $normal ) {
			my $char_pos = ( $self->{o_utf8} ) ? 1 : 0;
			my $o_bits = $self->{o_bits};
			my $o_chars = $self->{o_chars};
			foreach $y ( 0..$self->{my} ) {
				my $val = $self->{m}[$x][$y];

				$out .= ' ' if $y;
				if ( $val & $o_bits->{ant} ) {
					$out .= $o_chars->{ant}[$char_pos];

				} elsif ( $val & $o_bits->{hive} ) {
					$out .= $o_chars->{hive}[$char_pos];

				} elsif ( $val & $o_bits->{food} ) {
					$out .= $o_chars->{food}[$char_pos];

				} elsif ( $val & $o_bits->{water} ) {
					$out .= $o_chars->{water}[$char_pos];

				} elsif ( $val & $o_bits->{explored} ) {
					$out .= $o_chars->{explored}[$char_pos];

				} else {
					$out .= $o_chars->{unknown}[$char_pos];
				}
			}
		}

		if ( $view ) {
			$out .= '   ' if $normal;
			foreach $y ( 0..$self->{my} ) {
				my $val = $self->{m}[$x][$y];
				$out .= ' ' if $y;
				$out .= sprintf( "%02d", $self->{m}[$x][$y] );
			}
		}

		$out .= "\n";
	}
	return $out;
}

=head2 set

Set position on map to concrete type.

 $map->set( 'f', 1, 2 ); # food on [1,2]

=cut

sub set {
	my ( $self, $type, $x, $y ) = @_;
	$self->{m}[$x][$y] |= $self->{o_bits}{ $type };
	return 1;
}

=head2 pos_plus

Sum two positions A and B to get x, y on map (no behind map borders).

 my ( $x, $y ) = $map->pos_plus( $Ax, $Ay, $Bx, $By );

=cut

sub pos_plus {
	my ( $self, $Ax, $Ay, $Bx, $By ) = @_;
	
	my $x = $Ax + $Bx;
	if ( $x < 0 ) {
		$x = $self->{mx} + $x + 1;
	} elsif ( $x > $self->{mx} ) {
		$x = $x - $self->{mx} - 1;
	}

	my $y = $Ay + $By;
	if ( $y < 0 ) {
		$y = $self->{my} + $y + 1;
	} elsif ( $y > $self->{my} ) {
		$y = $y - $self->{my} - 1;
	}

	return $x, $y;
}

=head2 set_view

Set positions inside ant viewradius around provided position to 'explored'.

 $map->set_view( 1, 2 ); #  set explored around ant on [1,2] 

=cut

sub set_view {
	my ( $self, $bot_x, $bot_y ) = @_;

	# todo - optimize when moving

	my $explored_bit = $self->{o_bits}{explored};
	foreach my $pos ( @{ $self->{vr_map} } ) {
		my ( $x, $y ) = $self->pos_plus( $bot_x, $bot_y, $pos->[0], $pos->[1] );
		next if $self->{m}[$x][$y] & $explored_bit;
		$self->{m}[$x][$y] |= $explored_bit;
	}
}

=head1 Some notes

      ---->
      y
   |x
   |
   V
  
 Directions:
     N
   W * E
     S

 1 x--   ... NORTH -- Negative X direction
 2 y++   ... EAST  -- Positive Y direction
 3 x++   ... SOUTH -- Positive X direction
 4 y--   ... WEST  -- Negative Y direction

  rows (m_x) ... max X
  cols (m_y) ... max Y

 m ... map
 mx ... max x value ( = rows-1 )
 my ... max y value ( = cols-1 )

Bit number:
 0 ( & 1 ) ... undefined | already seen
 1 ( & 2 ) ...

=head1 AUTHOR

Michal Jurosz, mj@mj41.cz

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same 
terms as the Perl 5 programming language system itself.

=cut

1;
