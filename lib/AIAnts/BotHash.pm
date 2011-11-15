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

    $self->{pos2ant_num} = {};
    $self->{max_ant_num} = 0;
    $self->{ant_num2prev_pos} = {};

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

    $self->init_after_first_turn( $turn_data ) if $turn_num == 1;
    $self->set_area_diff( $turn_data );
    $self->update_on_turn_begin( $turn_data );

    my $changes = $self->turn_body( $turn_num, $turn_data );

    my @orders = ();
    foreach my $change_data ( values %$changes ) {
        my ( $ant_num, $x, $y, $dir, $Nx, $Ny ) = @$change_data;

        # no move
        unless ( defined $Nx ) {
            $self->{pos2ant_num}->{"$x,$y"} = $ant_num;
            next;
        }

        # move
        $self->{pos2ant_num}->{"$Nx,$Ny"} = $ant_num;
        $self->{ant_num2prev_pos}->{$ant_num} = [ $x, $y, $dir ];
        push @orders, [ $x, $y, $dir ];
    }
    return @orders;
}

=head2 get_ant_num

Return ant number for given ant position. Generate new if ant on given position not found.
Use 'pos2ant_num' attribute updated in 'turn' method.

=cut

sub get_ant_num {
    my ( $self, $x, $y ) = @_;
    my $pos_str = "$x,$y";
    return $self->{pos2ant_num}{$pos_str} if exists $self->{pos2ant_num}{$pos_str};
    $self->{max_ant_num}++;
    $self->{pos2ant_num}{$pos_str} = $self->{max_ant_num};
    $self->new_ant_created( $self->{max_ant_num} );
    return $self->{max_ant_num};
}

=head2 new_ant_created

Called during 'turb_body' if new ant was found/created.

=cut

sub new_ant_created {
    my ( $self, $ant_num ) = @_;
}

=head2 turn_body

Main part of turn processing. Should return hash ref with

 # "$Nx,$Ny" => [ $ant_num, $x, $y, $dir, $Nx, $Ny ]

inside if ant moves or

 # "$x,$y"   => [ $ant_num, $x, $y, $dir, undef, undef ]

if not.

=cut

sub turn_body {
    my ( $self, $turn_num, $turn_data ) = @_;
    return {};
}

=head2 init_after_first_turn

Initialization after first run. Set e.g. full area explored and all water 
inside ants viewareas.

=cut

sub init_after_first_turn {
    my ( $self, $turn_data ) = @_;

    foreach my $data ( values %{$turn_data->{a}} ) {
        my ( $x, $y, $owner ) = @$data;
        next unless $owner == 0;
        $self->{m}->set_explored( $x, $y );
    }

    foreach my $data ( values %{$turn_data->{w}} ) {
        $self->{m}->set( 'water', @$data );
    }
    return 1;
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
    foreach my $data ( values %{$turn_data->{a}} ) {
        my ( $x, $y, $owner ) = @$data;
        next unless $owner == 0;

        my $ant_num = $self->get_ant_num( $x, $y );
        next unless exists $self->{ant_num2prev_pos}{ $ant_num };

        my $prev_info = $self->{ant_num2prev_pos}{ $ant_num };
        my ( $prev_x, $prev_y, $prev_dir ) = @$prev_info;
        foreach my $Dpos ( @{ $m_cch_move->{$prev_dir}{a} } ) {
            ( $Nx, $Ny ) = $map_obj->pos_plus( $prev_x, $prev_y, $Dpos->[0], $Dpos->[1] );
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
}


=head1 AUTHOR

Michal Jurosz, mj@mj41.cz

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut

1;
