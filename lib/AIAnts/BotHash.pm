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

    $self->{max_ant} = 0;
    $self->{pos2ant} = {};
    $self->{ant2prev_pos} = {};
    $self->{ant2hill} = {};

    $self->{max_hill} = 0;
    $self->{pos2hill} = {};
    $self->{hill2pos} = {};

    $self->{enemies} = {};
    $self->{e_hill_info} = {};

    $self->{area_diff} = [];
    $self->{chc_num} = {};
}

=head2 turn

See L<AIANts::BotBase::turn> method documentation.

=cut

sub turn {
    my ( $self, $turn_num, $turn_data, $turn_start_time ) = @_;


    my $turn_diff = {};

    # Init my new hills.
    foreach my $pos_str ( keys %{$turn_data->{m_hill}} ) {
        next if exists $self->{pos2hill}{$pos_str};
        my ( $x, $y ) = @{ $turn_data->{m_hill}{$pos_str} };
        $self->turn_pr_my_new_hill_found( $x, $y );
        $turn_diff->{m_hill}{add}{$pos_str} = 1;
    }

    # Init my new hills.
    foreach my $pos_str ( keys %{$turn_data->{e_hill}} ) {
        if ( exists $self->{e_hill_info}{$pos_str} ) {
            # update last seen turn_num
            $self->{e_hill_info}{$pos_str}[3] = $turn_num;
            next;
        }
        my ( $x, $y, $owner ) = @{ $turn_data->{e_hill}{$pos_str} };
        $self->turn_pr_e_new_hill_found( $x, $y, $owner, $turn_num );
        $turn_diff->{e_hill}{rm}{$pos_str} = 1;
    }

    # Remove my ants (ants died).
    foreach my $pos_str ( keys %{$self->{pos2ant}} ) {
        next if exists $turn_data->{m_ant}{$pos_str};
        my $ant = $self->{pos2ant}{$pos_str};
        my ( $x, $y ) = split ',', $pos_str;
        $self->turn_pr_ant_died( $ant, $x, $y );
        $turn_diff->{m_ant}{add}{$pos_str} = 1;
    }

    # Add my new ants (ants spawed).
    foreach my $pos_str ( keys %{$turn_data->{m_ant}} ) {
        next if exists $self->{pos2ant}{$pos_str};

        my ( $x, $y ) = @{ $turn_data->{m_ant}{$pos_str} };
        $self->{m}->process_new_initial_pos( $x, $y, $turn_data );
        $self->turn_pr_ant_spawed( $x, $y, $turn_data );
        $turn_diff->{m_ant}{rm}{$pos_str} = 1;
    }

    # Set 'm_new' - new positions found.
    $self->set_area_diff( $turn_data );
    # Update map.
    $self->update_on_turn_begin( $turn_data );

    # pos2ant_num is updated in 'add_order' method.
    $self->{ant2prev_pos} = {};

    # Cache for 'number of ...'
    my $hill_nof = scalar keys %{$self->{pos2hill}};
    my $ant_nof = scalar keys %{$self->{pos2ant}};
    $self->{chc_num} = {
        hill => $hill_nof,
        ant => $ant_nof,
        ant_to_hill_ration => int( $ant_nof / $hill_nof ),
    };

    $self->turn_body( $turn_num, $turn_data, $turn_diff );

    return 1;
}

=head2 get_initial_used

Return hash with position not possible to move on (including own hills).

=cut

sub get_initial_used {
    my ( $self, $turn_data ) = @_;
    
    # Processing 'foreach ant', so we need to track used locations.
    my $used = {};

    # Do not move back to hill.
    foreach ( keys %{$self->{pos2hill}} ) {
        $used->{$_} = 1;
    };
    # Do not move on food - blocked.
    foreach my $data ( values %{$turn_data->{food}} ) {
        my ( $x, $y ) = @$data;
        $used->{"$x,$y"} = 1;
    };
    # Do not move to positions where own ats are. These keys are
    # deleted as ants move to other positions.
    foreach my $data ( values %{$turn_data->{m_ant}} ) {
        my ( $x, $y ) = @$data;
        $used->{"$x,$y"} = 1;
    }
    return $used;
}

=head2 add_order

Add order to 'orders' attribute and update attributes related to ant position change.

=cut

sub add_order {
    my ( $self, $ant, $x, $y, $dir, $Nx, $Ny ) = @_;

    # not move
    return 1 unless defined $Nx;
    return 1 if ($x == $Nx) && ($y == $Ny);

    # move

    # Delete old and set new ant_num pos.
    delete $self->{pos2ant}{"$x,$y"};
    $self->{pos2ant}{"$Nx,$Ny"} = $ant;

    $self->{ant2prev_pos}{$ant} = [ $x, $y, $dir ];
    push @{$self->{orders}}, [ $x, $y, $dir ];
    return 1;
}

=head2 turn_pr_my_new_hill_found

Initialize our new hill.

=cut

sub turn_pr_my_new_hill_found {
    my ( $self, $x, $y ) = @_;

    my $hill_num = ++$self->{max_hill};
    $self->{pos2hill}{"$x,$y"} = $hill_num;
    $self->{hill2pos}{$hill_num} = [ $x, $y ];

    $self->new_hill_found( $hill_num, $x, $y );
    return 1;
}

=head2 new_hill_found

Called during 'turn_body' if our new hill was found.

=cut

sub new_hill_found {
    my ( $self, $hill_num, $x, $y ) = @_;
    return 1;
}

=head2 turn_pr_e_new_hill_found

Initialize new enemy hill info.

=cut

sub turn_pr_e_new_hill_found {
    my ( $self, $x, $y, $owner, $turn_num ) = @_;

    $self->{e_hill_info}{"$x,$y"} = [ $x, $y, $owner, $turn_num ];
    $self->new_hill_found( $x, $y, $owner );
}

=head2 new_enemy_hill_found

Called during 'turn_body' if new enemy hill was found.

=cut

sub new_enemy_hill_found {
    my ( $self, $x, $y, $owner ) = @_;
    return 1;
}


=head2 turn_pr_ant_spawed

Initialize my new ant. Call $self->ant_spawed( $ant, $x, $y, $ant_hill ).

=cut

sub turn_pr_ant_spawed {
    my ( $self, $x, $y ) = @_;

    my $ant = ++$self->{max_ant};
    $self->{pos2ant}{"$x,$y"} = $ant;

    my $ant_hill = $self->{pos2hill}{"$x,$y"};
    $self->{ant2hill}{$ant} = $ant_hill;

    $self->ant_spawed( $ant, $x, $y, $ant_hill );
    return 1;
}

=head2 ant_spawed

Called during 'turn_body' if new ant was spawed (found/created).

=cut

sub ant_spawed {
    my ( $self, $ant, $x, $y, $ant_hill ) = @_;
    return 1;
}

=head2 turn_pr_ant_died

Remove my ant (ant died).

=cut

sub turn_pr_ant_died {
    my ( $self, $ant, $x, $y ) = @_;

    my $ant_hill = $self->{ant2hill}{$ant};
    $self->ant_died( $ant, $x, $y, $ant_hill );
    delete $self->{ant2hill}{$ant};
    return 1;
}

=head2 ant_died

Called during 'turn_body' if new ant died (was not found on expected position).

=cut

sub ant_died {
    my ( $self, $ant, $x, $y, $ant_hill ) = @_;
    return 1;
}

=head2 turn_body

Main part of turn processing. Should call 'add_order' method during processing.

=cut

sub turn_body {
    my ( $self, $turn_num, $turn_data, $turn_diff ) = @_;
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
        my $ant = $self->{pos2ant}{"$x,$y"};
        next unless exists $self->{ant2prev_pos}{ $ant };

        my ( $prev_x, $prev_y, $prev_dir ) = @{ $self->{ant2prev_pos}{ $ant } };
        foreach my $Dpos ( @{ $m_cch_move->{$prev_dir}{a} } ) {
            ( $Nx, $Ny ) = $map_obj->pos_plus( $prev_x, $prev_y, $Dpos->[0], $Dpos->[1] );
            #print "ant $ant prev $prev_x,$prev_y -> $x, $y + dpos $Dpos->[0], $Dpos->[1] = $Nx, $Ny\n";
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
