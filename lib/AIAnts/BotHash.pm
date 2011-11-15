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
    $self->{pos2ant_num} = {};
    $self->{max_ant_num} = 0;
}

=head2 init_turn

Call init_turn on your bot.

=cut

sub init_turn {
    my ( $self, $turn_num ) = @_;
}


=head2 turn

Return array of array refs with commands (ants movements).

 return ( [ 1, 1, 'E' ], [ 1, 2, 'S' ] ); # move ant [1,1] east (y++) and ant [1,2] south (x++)

=cut

sub turn {
    my ( $self, $turn_num, $turn_data ) = @_;

    $self->init_after_first_turn( $turn_data ); # if $turn_num == 1;
    $self->update_after_turn( $turn_data );

    my $changes = $self->turn_body( $turn_num, $turn_data );

    my @orders = ();
    my $ant_pos = {};
    foreach my $change_data ( values %$changes ) {
        my ( $ant_num, $x, $y, $dir, $Nx, $Ny ) = @$change_data;

        # no move
        unless ( defined $Nx ) {
            $ant_pos->{"$x,$y"} = $ant_num;
            next;
        }

        # move
        $ant_pos->{"$Nx,$Ny"} = $ant_num;
        push @orders, [ $x, $y, $dir ];
    }

    $self->{pos2ant_num} = $ant_pos;
    return @orders;
}


sub get_ant_num {
    my ( $self, $x, $y ) = @_;
    my $pos_str = "$x,$y";
    return $self->{pos2ant_num}{$pos_str} if exists $self->{pos2ant_num}{$pos_str};
    $self->{pos2ant_num}{$pos_str} = $self->{max_ant_num}++;
    return $self->{max_ant_num};
}


sub turn_body {
    my ( $self, $turn_num, $turn_data ) = @_;
    return {};
}


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


sub update_after_turn {
    my ( $self, $turn_data ) = @_;
}


=head1 AUTHOR

Michal Jurosz, mj@mj41.cz

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut

1;
