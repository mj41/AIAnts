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
        unknown  => 0,    #   0
        explored => 2**0, #   1
        water    => 2**1, #   2
        food     => 2**2, #   4
        m_hill   => 2**3, #   8
        e_hill   => 2**4, #  16
        m_ant    => 2**5, #  32
        e_ant    => 2**6, #  64
        corpse   => 2**7, # 128
    };

    $self->{o_utf8} = $args{o_utf8} // 0;
    $self->{o_line_prefix} = $args{o_line_prefix} // '';
    $self->{o_chars} = {
        unknown  => [ '.', chr(0x00B7)  ],
        explored => [ 'o', chr(0x2022)  ],
        water    => [ '%', chr(0x25A0)  ],
        food     => [ 'f', chr(0x2740)  ],
        m_hill   => [ '0', '0' ],
        e_hill   => [ '1', '1' ],
        m_ant    => [ 'a', 'a' ],
        e_ant    => [ 'b', 'b' ],
    };

    $self->init_map();

    $self->{max_dist_key} = $self->init_distance_caches( 5 );

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
        food => {},
        m_ant => {},
        m_hill => {},
        e_ant => {},
        e_hill => {},
    };
    return 1;
}

=head2 get_radius_cache

Init helper parameter for computation with radius.

=cut

sub get_radius_cache {
    my ( $self, $radius2, $radius2_down ) = @_;

    my $vm_distance = int sqrt( $radius2 );
    my $r_map = [
        [0,0]
    ];
    $r_map = [] if defined $radius2_down;
    return $r_map unless $vm_distance;

    my $act_radius;
    foreach my $x ( 0..$vm_distance ) {
        INNER: foreach my $y ( 0..$vm_distance ) {
            next INNER if $x == 0 && $y == 0;
            # <= is from game specification
            $act_radius = $x*$x + $y*$y;
            next INNER if $act_radius > $radius2;
            next INNER if $radius2_down && $act_radius <= $radius2_down;

            push @$r_map, [ +$x, +$y ];
            push @$r_map, [ -$x, +$y ];
            push @$r_map, [ +$x, -$y ];
            push @$r_map, [ -$x, -$y ];
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

    my $h_map = $self->vis_cache_on_map( $r_cch, negative=>1, padding=>1 );
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

=head2 init_distance_caches

Initialize distance caches.

=cut

sub init_distance_caches {
    my ( $self, $max_num ) = @_;

    my @radiuses = ( 1, 2, 4, 5, 8, 9, 10, 13, 16, 17, 18, 20, 25, 26, 29 );

    my $prev_rad = 0;
    my $num = 1;
    foreach my $rad ( @radiuses ) {
        my $r_diff_cache = $self->get_radius_cache( $rad, $prev_rad );
        $self->{dist_cch}{ $num } = $r_diff_cache;
        $prev_rad = $rad;
        last if $num >= $max_num;
        $num++;
    }
    return $num;
}

=head2 vis_cache_on_map

Make temp map and visualize caches on it.

=cut

sub vis_cache_on_map {
    my ( $self, $r_cch, %opts ) = @_;
    my $padding = $opts{padding} // 0;
    my $size = $opts{size} // 0;

    unless ( $size ) {
        my $mx = 0;
        my $my = 0;
        foreach my $pos ( @$r_cch ) {
            $mx = abs($pos->[0]) if abs($pos->[0]) > $mx;
            $my = abs($pos->[1]) if abs($pos->[1]) > $my;
        }

        $size = $mx;
        $size = $my if $my > $size;
        $size = $size*2 if $opts{negative};
        $size += 2*$padding;
    }

    my $middle = 0;
    if ( $opts{negative} ) {
        $middle = int( ($size+1) / 2 );
        return [] unless $middle > 0;
    }

    my $h_map = $self->get_empty_map( $size, $size );
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
    my ( $x, $y, $owner );
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
                if ( $val & $o_bits->{m_ant} ) {
                    $out .= $o_chars->{m_ant}[$char_pos];

                } elsif ( $val & $o_bits->{e_ant} ) {
                    $owner = $self->{otd}{e_ant}{"$x,$y"}[2];
                    $out .= chr( ord($o_chars->{e_ant}[$char_pos]) + $owner - 1 );

                } elsif ( $val & $o_bits->{m_hill} ) {
                    $out .= $o_chars->{m_hill}[$char_pos];

                } elsif ( $val & $o_bits->{e_hill} ) {
                    $owner = $self->{otd}{e_hill}{"$x,$y"}[2];
                    $out .= chr( ord($o_chars->{e_hill}[$char_pos]) + $owner - 1 );

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
                $out .= sprintf( "%3d", $map->[$x][$y] );
            }
        }

        $out .= "\n";
    }
    return $out;
}

=head2 set

Set position on map to concrete type.

 $map->set( 'e_ant', 2, 3, 1 ); # enemy 1 ant on [2,3]

=cut

sub set {
    my ( $self, $type, $x, $y, $owner ) = @_;
    $self->{m}[$x][$y] |= $self->{o_bits}{ $type };

    # hill, ant, corpse
    if ( defined $owner ) {
        $self->{otd}{$type}{"$x,$y"} = [ $x, $y, $owner+0 ];

    # food
    } elsif ( $type ne 'water' && $type ne 'explored' ) {
        $self->{otd}{$type}{"$x,$y"} = [ $x, $y ];
    }
    return 1;
}

=head2 food_exists

Return 1 if food exists on provided position.

=cut

sub food_exists {
    my ( $self, $x, $y ) = @_;
    return ( exists $self->{otd}{food}{"$x,$y"} );
}

=head2 enemy_hill_exists

Return 1 if enemy hill exists on provided position.

=cut

sub enemy_hill_exists {
    my ( $self, $x, $y ) = @_;
    return ( exists $self->{otd}{e_hill}{"$x,$y"} );
}

=head2 process_new_initial_pos

Initialize map on new initial position.

=cut

sub process_new_initial_pos {
    my ( $self, $ant_x, $ant_y, $turn_data ) = @_;

    $self->set_explored( $ant_x, $ant_y );

    my $map = $self->{m};
    my $o_bits_water = $self->{o_bits}{'water'};
    my ( $x, $y );
    foreach my $data ( values %{$turn_data->{water}} ) {
        ( $x, $y ) = @$data;
        $map->[$x][$y] |= $o_bits_water;
    }

    return 1;
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

    # set new otd
    my ( $x, $y, $owner );
    foreach my $data ( values %{$turn_data->{m_ant}} ) {
        ( $x, $y, $owner ) = @$data;
        $self->set('m_ant', $x, $y, $owner );
    }
    foreach my $data ( values %{$turn_data->{e_ant}} ) {
        ( $x, $y, $owner ) = @$data;
        $self->set('e_ant', $x, $y, $owner );
    }

    foreach my $data ( values %{$turn_data->{food}} ) {
        ( $x, $y ) = @$data;
        $self->set('food', $x, $y );
    }

    foreach my $data ( values %{$turn_data->{m_hill}} ) {
        ( $x, $y, $owner ) = @$data;
        $self->set('m_hill', $x, $y, $owner );
    }
    foreach my $data ( values %{$turn_data->{e_hill}} ) {
        ( $x, $y, $owner ) = @$data;
        $self->set('e_hill', $x, $y, $owner );
    }
    return 1;
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

=head2 pos_dir_step

Get new position if moved one step in provided direction.

 my ( $Nx, $Ny ) = $map_obj->pos_dir_step( 2, 1, 'W' ); # 1, 1

=cut

sub pos_dir_step {
    my ( $self, $Ax, $Ay, $dir ) = @_;

    if ( $dir eq 'N' ) {
        $Ax--;
        $Ax = $self->{mx} if $Ax < 0;

    } elsif ( $dir eq 'E' ) {
        $Ay++;
        $Ay = 0 if $Ay > $self->{my};

    } elsif ( $dir eq 'S' ) {
        $Ax++;
        $Ax = 0 if $Ax > $self->{mx};

    } elsif ( $dir eq 'W' ) {
        $Ay--;
        $Ay = $self->{my} if $Ay < 0;
    }
    return ( $Ax, $Ay );
}


=head2 dist

The x and y distance between A and B positions and x and y direction to get from A to B.

=cut

sub dist {
    my ( $self, $Ax, $Ay, $Bx, $By ) = @_;

    my ( $dx, $dir_x );
    if ( $Ax == $Bx ) {
        $dx = 0;
        $dir_x = 0;

    } else {
        $dx = abs( $Bx - $Ax );
        my $dx2 = $self->{mx}+1 - $dx;
        $dir_x = ( $Bx > $Ax ) ? 1 : -1;
        if ( $dx2 < $dx ) {
            $dx = $dx2;
            $dir_x *= -1;
        }
    }

    my ( $dy, $dir_y );
    if ( $Ay == $By ) {
        $dy = 0;
        $dir_y = 0;

    } else {
        $dy = abs( $By - $Ay );
        my $dy2 = $self->{my}+1 - $dy;
        $dir_y = ( $By > $Ay ) ? 1 : -1;
        if ( $dy2 < $dy ) {
            $dy = $dy2;
            $dir_y *= -1;
        }
    }

    return ( $dx, $dir_x, $dy, $dir_y );
}

=head2 valid_not_used_pos

Return 1 if position is not water and not used and not already visited.

=cut

sub valid_not_used_pos {
    my ( $self, $x, $y, $used, $visited ) = @_;

    return 0 if $self->{m}[$x][$y] & $self->{o_bits}{water};
    my $pos_str = "$x,$y";
    return 0 if exists $visited->{$pos_str};
    return 0 if exists $used->{$pos_str};
    return 1;
}


sub empty_path_temp {
    my ( $sefl ) = @_;
    return {
        visited => {},
    };
}

=head2 dir_from_to

Get direction to get from position A to position B. Also return new position after move.
Skip positions in hash ref 'used' parameter.

=cut

sub dir_from_to {
    my ( $self, $Ax, $Ay, $Bx, $By, $used, $path_temp ) = @_;

    my ( $dx, $dir_x, $dy, $dir_y ) = $self->dist( $Ax, $Ay, $Bx, $By );
    return () if $dx == 0 && $dy == 0;

    my @dirs;
    # longer
    if ( $dx >= $dy ) {
        if ( $dir_x == -1 ) {
           $dirs[0] = 'N';
           $dirs[2] = 'S';
        } else {
           $dirs[0] = 'S';
           $dirs[2] = 'N';
        }
        if ( $dir_y == -1 ) {
            $dirs[1] = 'W';
            $dirs[3] = 'E';
        } else {
            $dirs[1] = 'E';
            $dirs[3] = 'W';
        }
    } else {
        if ( $dir_y == -1 ) {
           $dirs[0] = 'W';
           $dirs[2] = 'E';
        } else {
           $dirs[0] = 'E';
           $dirs[2] = 'W';
        }
        if ( $dir_x == -1 ) {
            $dirs[1] = 'N';
            $dirs[3] = 'S';
        } else {
            $dirs[1] = 'S';
            $dirs[3] = 'N';
        }
    }

    my ( $dir, $Nx, $Ny, $Npos_str );
    foreach my $num (0..3) {
        $dir = $dirs[ $num ];
        ( $Nx, $Ny ) = $self->pos_dir_step( $Ax, $Ay, $dir );

        $Npos_str = "$Nx,$Ny";

        my $valid = $self->valid_not_used_pos( $Nx, $Ny, $used, $path_temp->{visited} );
        if ( $valid ) {
            $path_temp->{visited}{$Npos_str} = 1;
            return ( $dir, $Nx, $Ny );
        }
    }

    return ();
}


=head2 set_explored

Set positions inside ant viewradius around provided position to 'explored'.

 $map->set_explored( 1, 2 ); #  set explored around ant on [1,2]

=cut

sub set_explored {
    my ( $self, $ant_x, $ant_y ) = @_;

    # todo - optimize when moving

    my $explored_bit = $self->{o_bits}{explored};
    foreach my $pos ( @{ $self->{vr}{m_cch} } ) {
        my ( $x, $y ) = $self->pos_plus( $ant_x, $ant_y, $pos->[0], $pos->[1] );
        next if $self->{m}[$x][$y] & $explored_bit;
        $self->{m}[$x][$y] |= $explored_bit;
    }
}

=head2 get_nearest_by_type

Return position of nearest target of provided type ('e_ant', 'food' ).

=cut

sub get_nearest_by_type {
    my ( $self, $target_type, $from_x, $from_y, $skip_targets ) = @_;
    $skip_targets //= {};

    my ( $Fx, $Fy );
    my $targets = $self->{otd}{$target_type};
    my $min_dist = 1000; # max should be 200 + 200
    foreach my $target_pos ( values %$targets ) {
        my ( $target_x, $target_y ) = @$target_pos;
        next if exists $skip_targets->{"$target_x,$target_y"};

        # todo - bad on borders
        next if abs( int($target_x/15)-int($from_x/15) ) + abs( int($target_y/15)-int($from_y/15) ) > 2;

        my ( $dx, $dir_x, $dy, $dir_y ) = $self->dist( $from_x, $from_y, $target_x, $target_y );
        my $dist = $dx + $dy;
        next unless $dist < $min_dist;

        $min_dist = $dist;
        $Fx = $target_x;
        $Fy = $target_y;
    }

    return ( $Fx, $Fy );
}

=head2 get_my_nearest_ant

Return position of nearest attack target.

=cut

sub get_my_nearest_ant {
    my ( $self, $from_x, $from_y, $skip ) = @_;
    return $self->get_nearest_by_type( 'm_ant', $from_x, $from_y, $skip );
}


=head2 get_nearest_attack_target

Return position of nearest attack target.

=cut

sub get_nearest_attack_target {
    my ( $self, $from_x, $from_y, $skip ) = @_;

    my ( $Fx, $Fy ) = $self->get_nearest_by_type( 'e_ant', $from_x, $from_y, $skip );
    return ( $Fx, $Fy ) if defined $Fx;
    return $self->get_nearest_by_type( 'e_ant', $from_x, $from_y, $skip );
}

=head2

Return position of nearest food without attached ant to it.

=cut

sub get_nearest_free_food {
    my ( $self, $from_x, $from_y, $food2ant ) = @_;
    return $self->get_nearest_by_type( 'food', $from_x, $from_y, $food2ant );
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
