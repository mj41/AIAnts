package MyBot;

use strict;
use warnings;

use base 'AIAnts::BotHash';


=head1 NAME

Example HungryBot bot for L<AIAnts> game.

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
    #$self-dump( $turn_data ) if $self->{log};

    my $used = $self->get_initial_used( $turn_data );

    foreach my $data ( values %{$turn_data->{m_ant}} ) {
        my ( $ant_x, $ant_y ) = @$data;
        my $ant = $self->{pos2ant}{"$ant_x,$ant_y"};

        my ( $food_x, $food_y ) = $self->{m}->get_nearest_free_food( $ant_x, $ant_y );
        next unless defined $food_x;

        my ( $dir, $Nx, $Ny ) = $self->{m}->dir_from_to( $ant_x, $ant_y, $food_x, $food_y, $used );
        next unless defined $dir;

        $self->add_order( $ant, $ant_x, $ant_y, $dir, $Nx, $Ny );
        delete $used->{"$ant_x,$ant_y"};
        $used->{"$Nx,$Ny"} = 2;
        
        $self->log("ant $ant on $ant_x,$ant_y, nearest food $food_x,$food_y, direction $dir to $Nx,$Ny\n") if $self->{log};
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
