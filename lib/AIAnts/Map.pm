package AIAnts::Map;

use strict;
use warnings;

use utf8;

=head1 NAME

AIAnts::Map

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

    $self->{o_bits} = {
        unknown  => 0,    #  0
        explored => 2**0, #  1
        water    => 2**1, #  2
        food     => 2**2, #  4
        hive     => 2**3, #  8
        ant      => 2**4, # 16
        corpse   => 2**5, # 32
    };

    $self->{o_utf8} = $args{o_utf8} // 0;
    $self->{o_line_prefix} = $args{o_line_prefix} // '';
    $self->{o_chars} = {
        unknown  => [ '.', chr(0x00B7)  ],
        explored => [ 'o', chr(0x2022)  ],
        water    => [ '%', chr(0x25A0)  ],
        food     => [ 'f', chr(0x2740)  ],
        hive     => [ 'h', chr(0x27D0)  ],
        ant      => [ 'a', chr(0x10312) ],
    };

    $self->init_map();
    $self->init_radius_cache( 'vr', $args{viewradius2},   1 );
    $self->init_radius_cache( 'ar', $args{attackradius2}, 0 );
    $self->init_radius_cache( 'sr', $args{spawnradius2},  0 );

    return $self;
}

=head2 get_empty_map

Return map initialized to zeros.

=cut

sub get_empty_map {
    my ( $self, $mx, $my ) = @_;

    my $mp = [];
    foreach my $x ( 0..$mx ) {
        # todo - optimize - better syntax?
        foreach my $y ( 0..$my ) {
            $mp->[$x][$y] = 0;
        }
    }
    return $mp;
}

=head2 init_map

Initialize map to zeros.

=cut

sub init_map {
    my ( $self ) = @_;

    $self->{m} = $self->get_empty_map( $self->{mx}, $self->{my} );

    # one turn data
    $self->{otd} = {
        ant => {},
        corpse => {},
        hive => {},
        food => {},
    };
    return 1;
}

=head2 get_radius_cache

Init helper parameter for computation with radius.

=cut

sub get_radius_cache {
    my ( $self, $radius2 ) = @_;

    my $vm_distance = int sqrt( $radius2 );
    my $r_map = [
        [0,0]
    ];
    return $r_map unless $vm_distance;

    foreach my $x ( 0..$vm_distance ) {
        foreach my $y ( 0..$vm_distance ) {
            next if $x == 0 && $y == 0;
            if ( ($x*$x + $y*$y) < $radius2 ) {
                push @$r_map, [ +$x, +$y ];
                push @$r_map, [ -$x, +$y ];
                push @$r_map, [ +$x, -$y ];
                push @$r_map, [ -$x, -$y ];
            }
        }
    }
    return $r_map;
}

=head2 compute_move_cache

Compute helper move caches.

=cut

sub compute_move_cache {
    my ( $self, $r_cch, $h_map, $h_md, $Dx, $Dy ) = @_;

    my $res = {
        a => [],
        r => [],
    };
    my $found = {};
    foreach my $pos ( @$r_cch ) {
        my ( $x, $y ) = @$pos;
        unless ( $h_map->[$h_md+$x+$Dx][$h_md+$y+$Dy] ) {
            push @{$res->{a}}, [ $x+$Dx, $y+$Dy ];
        } else {
            my $str = ($h_md+$x).','.($h_md+$y);
            $found->{$str} = undef;
        }
    }
    foreach my $pos ( @$r_cch ) {
        my ( $x, $y ) = @$pos;
        my $str = ($h_md+$x-$Dx).','.($h_md+$y-$Dy);
        next if exists $found->{$str};
        push @{$res->{r}}, [ $x, $y ];
    }

    return $res;
}


=head2 get_radius_move_caches

Get helper move caches for computation with radius and movements.

=cut

sub get_radius_move_caches {
    my ( $self, $r_cch ) = @_;

    my $h_map = $self->vis_cache_on_map( $r_cch, undef, 1 );
    my $h_md = int( (scalar @$h_map) / 2 );

    my $move_cch = {};
    $move_cch->{N} = $self->compute_move_cache( $r_cch, $h_map, $h_md, -1,  0 );
    $move_cch->{E} = $self->compute_move_cache( $r_cch, $h_map, $h_md,  0,  1 );
    $move_cch->{S} = $self->compute_move_cache( $r_cch, $h_map, $h_md,  1,  0 );
    $move_cch->{W} = $self->compute_move_cache( $r_cch, $h_map, $h_md,  0, -1 );
    return $move_cch;
}

=head2 init_radius

Init helper parameter for computation with radius.

=cut

sub init_radius_cache {
    my ( $self, $radius_shortcut, $radius2, $also_move_caches ) = @_;
    die "No radius2 defined for shortcut '$radius_shortcut'.\n" unless defined $radius2;

    $self->{$radius_shortcut}{r2} = $radius2;

    my $r_cache = $self->get_radius_cache( $radius2 );
    $self->{$radius_shortcut}{m_cch} = $r_cache;

    if ( $also_move_caches ) {
        my $r_move_caches = $self->get_radius_move_caches(
            $self->{$radius_shortcut}{m_cch}
        );
        $self->{$radius_shortcut}{m_cch_move} = $r_move_caches;
    }

    return 1;
}

=head2 vis_cache_on_map

Make temp map and visualize caches on it.

=cut

sub vis_cache_on_map {
    my ( $self, $r_cch, $h_max, $padding ) = @_;
    $padding //= 0;

    unless ( $h_max ) {
        my $mx = 0;
        my $my = 0;
        foreach my $pos ( @$r_cch ) {
            $mx = abs($pos->[0]) if abs($pos->[0]) > $mx;
            $my = abs($pos->[1]) if abs($pos->[1]) > $my;
        }

        $h_max = $mx;
        $h_max = $my if $my > $h_max;
        $h_max = $h_max*2 + 2*$padding;
    }

    my $middle = int( ($h_max+1) / 2 );
    return '' unless $middle > 0;
    #print "$h_max $middle\n";

    my $h_map = $self->get_empty_map( $h_max, $h_max );
    foreach my $pos ( @$r_cch ) {
        my ( $x, $y ) = @$pos;
        $h_map->[$x+$middle][$y+$middle] = 1;
    }
    return $h_map;
}

=head2 dump

Return map dumped to ascii/utf8.

 print $map->dump(1,0); # will dump normal ascii/utf8
 print $map->dump(0,1); # dump internal values of map

=cut

sub dump {
    my ( $self, $normal, $view, %force_opts ) = @_;

    my $utf8 = $force_opts{o_utf8} // $self->{o_utf8};
    my $char_pos = ( $utf8 ) ? 1 : 0;
    my $show_explored = $force_opts{show_explored} // 1;

    my $line_prefix = $force_opts{o_line_prefix} // $self->{o_line_prefix};
    return $self->dump_raw(
        $self->{m}, $self->{mx}, $self->{my}, $normal, $view,
        $char_pos, $show_explored, undef, $line_prefix
    );
}

=head2 dump_map

Dump map provided as parameter.

=cut

sub dump_map {
    my ( $self, $mp, $char, $line_prefix ) = @_;
    $char //= 'x';
    $line_prefix //= '';

    my $mx = $#$mp;
    my $my = $#{$mp->[0]};
    return $self->dump_raw(
        $mp, $mx, $my, 1, 0,
        0, 1, $char, $line_prefix
    );
}

=head2 dump_raw

Raw way of map dumping.

=cut

sub dump_raw {
    my (
        $self,
        $map, $mx, $my, $normal, $view,
        $char_pos, $show_explored, $explored_char, $line_prefix
    ) = @_;

    my $o_bits = $self->{o_bits};
    my $o_chars = $self->{o_chars};
    my $out = '';
    my ( $x, $y );
    foreach $x ( 0..$mx ) {
        $out .= $line_prefix;
        if ( $normal ) {
            unless ( defined $explored_char ) {
                if ( $show_explored ) {
                    $explored_char = $o_chars->{explored}[$char_pos];
                } else {
                    $explored_char = $o_chars->{unknown}[$char_pos];
                }
            }

            foreach $y ( 0..$my ) {
                my $val = $map->[$x][$y];

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
                    $out .= $explored_char;

                } else {
                    $out .= $o_chars->{unknown}[$char_pos];
                }
            }
        }

        if ( $view ) {
            $out .= '   ' if $normal;
            foreach $y ( 0..$my ) {
                my $val = $map->[$x][$y];
                $out .= ' ' if $y;
                $out .= sprintf( "%02d", $map->[$x][$y] );
            }
        }

        $out .= "\n";
    }
    return $out;
}

=head2 set

Set position on map to concrete type.

 $map->set( 'food', 1, 2 ); # food on [1,2]

=cut

sub set {
    my ( $self, $type, $x, $y, $owner ) = @_;
    $self->{m}[$x][$y] |= $self->{o_bits}{ $type };

    # hive, ant, corpse
    if ( defined $owner ) {
        $self->{otd}{$type}{"$x,$y"} = [ $x, $y, $owner ];

    # food
    } elsif ( $type ne 'water' && $type ne 'explored' ) {
        $self->{otd}{$type}{"$x,$y"} = [ $x, $y ];
    }
    return 1;
}

=head2 init_from_turn_raw

Initialize map - internal.

=cut

sub init_from_turn_raw {
    my ( $self, $turn_data, $explored_and_water ) = @_;

    my ( $x, $y, $owner );
    my $map = $self->{m};

    # turn == 1
    if ( $explored_and_water ) {
        foreach my $data ( values %{$turn_data->{ant}} ) {
            ( $x, $y, $owner ) = @$data;
            $self->set('ant', $x, $y, $owner );
            next unless $owner == 0;
            $self->set_explored( $x, $y );
        }

        my $o_bits_water = $self->{o_bits}{'water'};
        foreach my $data ( values %{$turn_data->{water}} ) {
            ( $x, $y ) = @$data;
            $map->[$x][$y] |= $o_bits_water;
        }

    # turn >= 2
    } else {
        foreach my $data ( values %{$turn_data->{ant}} ) {
            ( $x, $y, $owner ) = @$data;
            $self->set('ant', $x, $y, $owner );
        }
    }

    my $o_bits_food = $self->{o_bits}{'food'};
    foreach my $data ( values %{$turn_data->{food}} ) {
        ( $x, $y ) = @$data;
        $map->[$x][$y] |= $o_bits_food;
    }

    foreach my $data ( values %{$turn_data->{hive}} ) {
        ( $x, $y, $owner ) = @$data;
        $self->set('hive', $x, $y, $owner );
    }
    return 1;
}

=head2 init_after_first_turn

Initialize map before first turn.

=cut

sub init_after_first_turn {
    my ( $self, $turn_data ) = @_;
    return $self->init_from_turn_raw( $turn_data, 1 );
}


=head2 update_new_after_turn

Optimized version of updating newly explored area from turn data.

=cut

sub update_new_after_turn {
    my ( $self, $m_new, $turn_data ) = @_;

    my @otd_types = keys %{ $self->{otd} };
    my $map = $self->{m};
    my $pos;

    # reset previous - otd
    my $o_bits_explored = $self->{o_bits}{explored};
    foreach my $type ( @otd_types ) {
        my $o_bits_type = $self->{o_bits}{$type};
        my $rev_bit_o = 255 ^ $o_bits_type;
        foreach $pos ( values %{ $self->{otd}{$type} } ) {
            $map->[ $pos->[0] ][ $pos->[1] ] &= $rev_bit_o;
        }
        $self->{otd}{$type} = {};
    }

    # set water and explored
    my $o_bits_water = $self->{o_bits}{'water'};
    foreach my $pos ( @$m_new ) {
        my ( $x, $y ) = @$pos;
        $map->[$x][$y] |= $o_bits_explored;
        if ( exists $turn_data->{water}{"$x,$y"} ) {
            $map->[$x][$y] |= $o_bits_water;
        }
    }

    # set otd
    return $self->init_from_turn_raw( $turn_data, 0 );
}

=head2 pos_plus

Sum positions A and distance D to get x, y on map (no behind map borders).

 my ( $x, $y ) = $map->pos_plus( $Ax, $Ay, $Dx, $Dy );

=cut

sub pos_plus {
    my ( $self, $Ax, $Ay, $Dx, $Dy ) = @_;

    my $x = $Ax + $Dx;
    if ( $x < 0 ) {
        $x = $self->{mx} + $x + 1;
    } elsif ( $x > $self->{mx} ) {
        $x = $x - $self->{mx} - 1;
    }

    my $y = $Ay + $Dy;
    if ( $y < 0 ) {
        $y = $self->{my} + $y + 1;
    } elsif ( $y > $self->{my} ) {
        $y = $y - $self->{my} - 1;
    }

    return ( $x, $y );
}

=head2 set_explored

Set positions inside ant viewradius around provided position to 'explored'.

 $map->set_explored( 1, 2 ); #  set explored around ant on [1,2]

=cut

sub set_explored {
    my ( $self, $bot_x, $bot_y ) = @_;

    # todo - optimize when moving

    my $explored_bit = $self->{o_bits}{explored};
    foreach my $pos ( @{ $self->{vr}{m_cch} } ) {
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
