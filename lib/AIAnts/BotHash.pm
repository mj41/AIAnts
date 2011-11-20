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
    $self->{ant_num2hill_info} = {};

    $self->{max_hill_num} = 0;
    $self->{pos2hill} = {};
    $self->{hill2pos} = {};

    $self->{m_new} = [];
}

=head2 init_turn

Call init_turn on your bot.

=cut

sub init_turn {
    my ( $self, $turn_num ) = @_;
    $self->{turn_num} = $turn_num;
}

=head2 turn

Return array of array refs with commands (ants movements).

 return ( [ 1, 1, 'E' ], [ 1, 2, 'S' ] ); # move ant [1,1] east (y++) and ant [1,2] south (x++)

=cut

sub turn {
    my ( $self, $turn_num, $turn_data ) = @_;

    # Init my new hills.
    foreach my $pos_str ( keys %{$turn_data->{m_hill}} ) {
        next if exists $self->{pos2hill}{$pos_str};
        my ( $x, $y ) = @{ $turn_data->{m_hill}{$pos_str} };
        $self->process_turn_new_hill_found( $x, $y );
    }

    # Remove my ants (ants died).
    foreach my $pos_str ( keys %{$self->{pos2ant_num}} ) {
        next if exists $turn_data->{m_ant}{$pos_str};

        my ( $x, $y ) = @{ $turn_data->{m_ant}{$pos_str} };
        my $ant_num = @{ $self->{pos2ant_num}{$pos_str} };
        $self->process_turn_ant_died( $ant_num, $x, $y );
    }

    # Add my new ants (ants spawed).
    foreach my $pos_str ( keys %{$turn_data->{m_ant}} ) {
        next if exists $self->{pos2ant_num}{$pos_str};

        my ( $x, $y ) = @{ $turn_data->{m_ant}{$pos_str} };
        $self->{m}->process_new_initial_pos( $x, $y, $turn_data );
        $self->process_turn_ant_spawed( $x, $y, $turn_data );
    }

    # Set 'm_new' - new positions found.
    $self->set_area_diff( $turn_data );
    # Update map.
    $self->update_on_turn_begin( $turn_data );

    my $changes = $self->turn_body( $turn_num, $turn_data );

    $self->{pos2ant_num} = {};
    $self->{ant_num2prev_pos} = {};

    my @orders = ();
    foreach my $change_data ( values %$changes ) {
        my ( $ant_num, $x, $y, $dir, $Nx, $Ny ) = @$change_data;

        # no move
        unless ( defined $Nx ) {
            $self->{pos2ant_num}->{"$x,$y"} = $ant_num;
            next;
        }

        # move
        $self->{pos2ant_num}{"$Nx,$Ny"} = $ant_num;
        $self->{ant_num2prev_pos}{$ant_num} = [ $x, $y, $dir ];
        push @orders, [ $x, $y, $dir ];
    }
    return @orders;
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
    my ( $hill_num, $x, $y ) = @_;
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
    $self->{ant_num2hill_info}{$ant_num} = [ $x, $y, $ant_hill_num ];

    $self->ant_spawed( $ant_num, $x, $y, $ant_hill_num );
    return 1;
}

=head2 ant_spawed

Called during 'turn_body' if new ant was spawed (found/created).

=cut

sub ant_spawed {
    my ( $ant_num, $x, $y, $ant_hill_num ) = @_;
    return 1;
}

=head2 process_turn_ant_died

Remove my ant (ant died).

=cut

sub process_turn_ant_died {
    my ( $self, $ant_num, $x, $y ) = @_;

    my $ant_hill_num = $self->{ant_num2hill_info}{$ant_num};
    $self->ant_died( $ant_num, $x, $y, $ant_hill_num );
    delete $self->{ant_num2hill_info}{$ant_num};
    return 1;
}

=head2 ant_died

Called during 'turn_body' if new ant died (was not found on expected position).

=cut

sub ant_died {
    my ( $ant_num, $x, $y, $ant_hill_num ) = @_;
    return 1;
}

=head2 turn_body

Main part of turn processing. Should return hash ref with

 # "$Nx,$Ny" => [ $ant_num, $x, $y, $dir, $Nx, $Ny ]

inside if ant moves or

 # "$x,$y"   => [ $ant_num, $x, $y ]

if not.

=cut

sub turn_body {
    my ( $self, $turn_num, $turn_data ) = @_;
    return {};
}

=head2 set_area_diff

Set 'm_new' array of positions on map, which ant newly see because of their moves.

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

        my $prev_info = $self->{ant_num2prev_pos}{ $ant_num };
        my ( $prev_x, $prev_y, $prev_dir ) = @$prev_info;
        foreach my $Dpos ( @{ $m_cch_move->{$prev_dir}{a} } ) {
            ( $Nx, $Ny ) = $map_obj->pos_plus( $prev_x, $prev_y, $Dpos->[0], $Dpos->[1] );
            #print "ant $ant_num prev $prev_x,$prev_y -> $x, $y + dpos $Dpos->[0], $Dpos->[1] = $Nx, $Ny\n";
            next if exists $processed->{"$Nx,$Ny"};
            $processed->{"$Nx,$Ny"} = 1;
            push @$diff_a, [ $Nx, $Ny ];
        }
    }

    $self->{m_new} = $diff_a;
    return 1;
}

=head2 update_on_turn_begin

Update data on new turn init (before processing turn_body).

=cut

sub update_on_turn_begin {
    my ( $self, $turn_data ) = @_;

    $self->{m}->update_new_after_turn( $self->{m_new}, $turn_data );
    return 1;
}


=head1 AUTHOR

Michal Jurosz, mj@mj41.cz

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut

1;
