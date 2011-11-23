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

Main part of turn processing. Should call 'add_order' method during processing.

=cut

sub turn_body {
    my ( $self, $turn_num, $turn_data, $turn_diff ) = @_;

    my $dirs = [ 'N', 'E', 'S', 'W' ];

    $self->log( "turn $turn_num\n" ) if $self->{log};
    #$self->log( $self->{m}->dump(1) . "\n\n" ) if $self->{log};
    #$self->dump( $turn_data ) if $self->{log};

    my $used = $self->get_initial_used( $turn_data );

    foreach my $data ( values %{$turn_data->{m_ant}} ) {
        my ( $x, $y ) = @$data;

        my $ant = $self->{pos2ant}{"$x,$y"};
        my $dir;
        my ( $Dx, $Dy, $Nx, $Ny );
        my $dir_num = int rand 4;
        my $attemt = 1;
        RANDOM: while ( 1 ) {
            $dir = $dirs->[ ($dir_num+$attemt) % 4 ];
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

            ( $Nx, $Ny ) = $self->{m}->pos_plus( $x, $y, $Dx, $Dy );
            if ( $self->{m}->valid_not_used_pos( $Nx, $Ny, $used ) ) {
                $self->add_order( $ant, $x, $y, $dir, $Nx, $Ny );
                delete $used->{"$x,$y"};
                $used->{"$Nx,$Ny"} = 2;
                last RANDOM;
            }
            last RANDOM if $attemt == 4;
            $attemt++;
        }
    }

    $self->log("\n") if $self->{log};
    return 1;
}


=head1 AUTHOR

Michal Jurosz, mj@mj41.cz

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut

1;
