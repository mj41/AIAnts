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

=head2 turn

Return array of array refs with commands (ants movements).

 return ( [ 1, 1, 'E' ], [ 1, 2, 'S' ] ); # move ant [1,1] east (y++) and ant [1,2] south (x++)

=cut

sub turn {
    my ( $self, $turn_num, $turn_data ) = @_;

    # todo - optimize
    $self->init_after_first_turn( $turn_data ); # if $turn_num == 1;

    return ();
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

=head1 AUTHOR

Michal Jurosz, mj@mj41.cz

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut

1;
