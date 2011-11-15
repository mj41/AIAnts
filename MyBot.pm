package MyBot;

use strict;
use warnings;

use base 'AIAnts::BotHash';

=head1 NAME

MyBot for L<AIAnts> game.

=head1 SYNOPSIS

Google AI Challenge 2011 "AI Ants" game Perl bot.

=head1 METHODS

=head2 setup

Setup.

=cut

sub setup {
    my $self = shift;
    $self->SUPER::setup( @_ );
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

    my $dirs = [ 'N', 'E', 'S', 'W' ];

    my $changes = {};
    my $map_obj = $self->{m};
    my $map = $map_obj->{m};
    my $water_bit = $map_obj->{o_bits}{water};
    foreach my $data ( values %{$turn_data->{a}} ) {
        my ( $x, $y, $owner ) = @$data;
        next unless $owner == 0;

        my $ant_num = $self->get_ant_num( $x, $y );
        my $dir;
        my ( $Dx, $Dy, $Nx, $Ny );
        my $dir_num = int rand 3;
        while ( 1 ) {
            $dir = $dirs->[ $dir_num ];
            if ( $dir eq 'N' ) {
                $Dx = -1;
                $Dy =  0;
            } elsif ( $dir eq 'E' ) {
                $Dx =  0;
                $Dy =  1;
            } elsif ( $dir eq 'S' ) {
                $Dx =  1;
                $Dy =  0;
            } elsif ( $dir eq 'W' ) {
                $Dx =  0;
                $Dy = -1;
            }

            ( $Nx, $Ny ) = $map_obj->pos_plus( $x, $y, $Dx, $Dy );
            if ( (not $map->[$Nx][$Ny] & $water_bit)
                  && (not exists $changes->{"$Nx,$Ny"})
                  && (not exists $turn_data->{a}{"$Nx,$Ny"})
               )
            {
                $changes->{"$Nx,$Ny"} = [ $ant_num, $x, $y, $dir, $Nx, $Ny ];
                last;
            }
            $dir_num++;
            last if $dir_num == 4;
        }
        $changes->{"$x,$y"} = [ $ant_num, $x, $y, $dir, undef, undef ] if $dir_num == 4;
    }

    return $changes;
}


=head1 AUTHOR

Michal Jurosz, mj@mj41.cz

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut

1;
