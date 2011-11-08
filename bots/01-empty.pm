package MyBot;

use strict;
use warnings;
use Carp qw(carp croak);

use base 'AIAnts::BotBase';

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
    $self->{br} = {};
}

=head2 orders

Make orders.

=cut

sub orders {
    my $self = shift;

    my @orders = ();
    foreach my $ant_data ( $self->my_ants ) {
        my ( $ant_num, $x, $y ) = @$ant_data;
        #push @orders, [ $x, $y, 'S' ];

    }
    return @orders;
}

=head1 AUTHOR

Michal Jurosz, mj@mj41.cz

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut

1;
