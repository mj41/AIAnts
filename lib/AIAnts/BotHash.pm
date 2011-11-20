package AIAnts::BotHash;

use strict;
use warnings;

use base 'AIAnts::BotBase';

=head1 NAME

AIAnts::BotHash - Process turn hash.

=head1 SYNOPSIS

Base class for AIAnts bot.

=head1 METHODS

=head2 do_turn_at_once

Bot want to do turns by processing turn_data hash.

=cut

sub do_turn_at_once {
    return 1;
}

=head2 setup

Setup.

=cut

sub setup {
    my $self = shift;
    $self->SUPER::setup( @_ );

    $self->{turn_num} = 0;

    $self->{max_ant_num} = 0;
    $self->{pos2ant_num} = {};
    $self->{ant_num2prev_pos} = {};
    $self->{ant_num2hill} = {};

    $self->{max_hill_num} = 0;
    $self->{pos2hill} = {};
    $self->{hill2pos} = {};

    $self->{area_diff} = [];
    $self->{m_num} = {};
}

=head2 turn

See L<AIANts::BotBase::turn> method documentation.

=cut

sub turn {
    my ( $self, $turn_num, $turn_data, $turn_start_time ) = @_;

    # Init my new hills.
    my $plus_hill = 0;
    foreach my $pos_str ( keys %{$turn_data->{m_hill}} ) {
        next if exists $self->{pos2hill}{$pos_str};
        my ( $x, $y ) = @{ $turn_data->{m_hill}{$pos_str} };
        $self->process_turn_new_hill_found( $x, $y );
        $plus_hill++;
    }

    # Remove my ants (ants died).
    my $minus_ant = 0;
    foreach my $pos_str ( keys %{$self->{pos2ant_num}} ) {
        next if exists $turn_data->{m_ant}{$pos_str};
        my $ant_num = $self->{pos2ant_num}{$pos_str};
        my ( $x, $y ) = split ',', $pos_str;
        $self->process_turn_ant_died( $ant_num, $x, $y );
        $minus_ant++;
    }

    # Add my new ants (ants spawed).
    my $plus_ant = 0;
    foreach my $pos_str ( keys %{$turn_data->{m_ant}} ) {
        next if exists $self->{pos2ant_num}{$pos_str};

        my ( $x, $y ) = @{ $turn_data->{m_ant}{$pos_str} };
        $self->{m}->process_new_initial_pos( $x, $y, $turn_data );
        $self->process_turn_ant_spawed( $x, $y, $turn_data );
        $plus_ant++;
    }

    # Set 'm_new' - new positions found.
    $self->set_area_diff( $turn_data );
    # Update map.
    $self->update_on_turn_begin( $turn_data );

    # pos2ant_num is updated in 'add_order' method.
    $self->{ant_num2prev_pos} = {};

    # todo
    my $minus_hill = 0;

    # Cache for 'number of ...'
    my $hill_nof = scalar keys %{$self->{pos2hill}};
    my $ant_nof = scalar keys %{$self->{pos2ant_num}};
    $self->{m_num} = {
        hill => $hill_nof,
        plus_hill => $plus_hill,
        minus_hill => $minus_hill,

        ant => $ant_nof,
        plus_ant => $plus_ant,
        minust_ant => $minus_ant,

        ant_to_hill_ration => int( $ant_nof / $hill_nof ),
    };

    $self->turn_body( $turn_num, $turn_data );

    return 1;
}

=head2 add_order

Add order to 'orders' attribute and update attributes related to ant position change.

=cut

sub add_order {
    my ( $self, $ant_num, $x, $y, $dir, $Nx, $Ny ) = @_;

    # not move
    return 1 unless defined $Nx;
    return 1 if ($x == $Nx) && ($y == $Ny);

    # move

    # Delete old and set new ant_num pos.
    delete $self->{pos2ant_num}{"$x,$y"};
    $self->{pos2ant_num}{"$Nx,$Ny"} = $ant_num;

    $self->{ant_num2prev_pos}{$ant_num} = [ $x, $y, $dir ];
    push @{$self->{orders}}, [ $x, $y, $dir ];
    return 1;
}

=head2 process_turn_new_hill_found

Initialize new hill.

=cut

sub process_turn_new_hill_found {
    my ( $self, $x, $y ) = @_;

    my $hill_num = ++$self->{max_hill_num};
    $self->{pos2hill}{"$x,$y"} = $hill_num;
    $self->{hill2pos}{$hill_num} = [ $x, $y ];

    $self->new_hill_found( $hill_num, $x, $y );
    return 1;
}

=head2 new_hill_found

Called during 'turn_body' if new ant was spawed (found/created).

=cut

sub new_hill_found {
    my ( $self, $hill_num, $x, $y ) = @_;
    return 1;
}

=head2 process_turn_ant_spawed

Initialize my new ant. Call $self->ant_spawed( $ant_num, $x, $y, $ant_hill_num ).

=cut

sub process_turn_ant_spawed {
    my ( $self, $x, $y ) = @_;

    my $ant_num = ++$self->{max_ant_num};
    $self->{pos2ant_num}{"$x,$y"} = $ant_num;

    my $ant_hill_num = $self->{pos2hill}{"$x,$y"};
    $self->{ant_num2hill}{$ant_num} = $ant_hill_num;

    $self->ant_spawed( $ant_num, $x, $y, $ant_hill_num );
    return 1;
}

=head2 ant_spawed

Called during 'turn_body' if new ant was spawed (found/created).

=cut

sub ant_spawed {
    my ( $self, $ant_num, $x, $y, $ant_hill_num ) = @_;
    return 1;
}

=head2 process_turn_ant_died

Remove my ant (ant died).

=cut

sub process_turn_ant_died {
    my ( $self, $ant_num, $x, $y ) = @_;

    my $ant_hill_num = $self->{ant_num2hill}{$ant_num};
    $self->ant_died( $ant_num, $x, $y, $ant_hill_num );
    delete $self->{ant_num2hill}{$ant_num};
    return 1;
}

=head2 ant_died

Called during 'turn_body' if new ant died (was not found on expected position).

=cut

sub ant_died {
    my ( $self, $ant_num, $x, $y, $ant_hill_num ) = @_;
    return 1;
}

=head2 turn_body

Main part of turn processing. Should return call 'add_order' method.

=cut

sub turn_body {
    my ( $self, $turn_num, $turn_data ) = @_;
    return 1;
}

=head2 get_area_diff

Return list of positions found explored (maybe again) in this turn.

=cut

sub get_area_diff {
    my $self = shift;
    return $self->{area_diff};
}

=head2 set_area_diff

Set 'area_diff' attribute. See L<get_area_diff>.

=cut

sub set_area_diff {
    my ( $self, $turn_data ) = @_;

    my $map_obj = $self->{m};
    my $m_cch_move = $map_obj->{vr}{m_cch_move};

    my $diff_a = [];
    my ( $Nx, $Ny );
    my $processed = {};
    foreach my $data ( values %{$turn_data->{m_ant}} ) {
        my ( $x, $y ) = @$data;
        my $ant_num = $self->{pos2ant_num}{"$x,$y"};
        next unless exists $self->{ant_num2prev_pos}{ $ant_num };

        my ( $prev_x, $prev_y, $prev_dir ) = @{ $self->{ant_num2prev_pos}{ $ant_num } };
        foreach my $Dpos ( @{ $m_cch_move->{$prev_dir}{a} } ) {
            ( $Nx, $Ny ) = $map_obj->pos_plus( $prev_x, $prev_y, $Dpos->[0], $Dpos->[1] );
            #print "ant $ant_num prev $prev_x,$prev_y -> $x, $y + dpos $Dpos->[0], $Dpos->[1] = $Nx, $Ny\n";
            next if exists $processed->{"$Nx,$Ny"};
            $processed->{"$Nx,$Ny"} = 1;
            push @$diff_a, [ $Nx, $Ny ];
        }
    }

    $self->{area_diff} = $diff_a;
    return 1;
}

=head2 update_on_turn_begin

Update data on new turn init (before processing turn_body).

=cut

sub update_on_turn_begin {
    my ( $self, $turn_data ) = @_;

    $self->{m}->update_new_after_turn( $self->{area_diff}, $turn_data );
    return 1;
}


=head1 AUTHOR

Michal Jurosz, mj@mj41.cz

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut

1;
