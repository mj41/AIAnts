package AIAnts::BotBase;

use strict;
use warnings;
use Carp qw(carp croak);

use base 'AIAnts::Base';
use AIAnts::Map;

=head1 NAME

AIAnts::BotBase

=head1 SYNOPSIS

Base class for AIAnts bot.

=head1 METHODS

=head2 new

Constructor.

=cut

sub new {
    my ( $class, %args ) = @_;

    my $self = {
        # my ants
        ants => 0,
        my_ants => {},
    };
    $self->{ver} = $args{ver} // 1;
    $self->{log_fpath} = $args{log_fpath} // 0;
    $self->{log} = $self->{log_fpath} ? 1 : 0;
    $self->{map_args} = $args{map} // {};
    $self->{orders} = [];

    bless $self, $class;
}

=head2 map

Return map objects (instance of AIAnts::Map).

=cut

sub map {
    $_[0]->{m}
}

=head2 setup

Called once, after the game parameters are parsed and game is 'ready'.

=cut

sub setup {
    my ( $self, %config ) = @_;

    $self->{m} = new AIAnts::Map(
        cols => $config{cols},
        rows => $config{rows},
        viewradius2 => $config{viewradius2},
        attackradius2 => $config{attackradius2},
        spawnradius2 => $config{spawnradius2},
        %{ $self->{map_args} }
    );

    $self->log( '', 1 ) if $self->{log}; # truncate log file
}

=head2 init_turn

Called before new turn params are parser and set_* methods called.

=cut

sub init_turn {
    my ( $self, $turn_num ) = @_;
    $self->{turn_num} = $turn_num;
    $self->{orders} = [];
    return 1;
}

=head2 turn

Main part of bot brain/algorithm. Should add values (array ref) to 'orders' attribute
(array of array refs). Game will call 'get_orders_fast' method to get 'orders'
attribute value. See L<get_orders_fast> documentation.

=cut

sub turn {
    my ( $self, $turn_num, $turn_data ) = @_;

    croak 'Method turn not implemented in ' . __PACKAGE__;
    return 1;
}

=head2 add_order

Add order to 'orders' attribute.

=cut

sub add_order {
    my ( $self, $x, $y, $dir ) = @_;
    push @{$self->{orders}}, [ $x, $y, $dir ];
    return 1;
}

=head2 get_orders_fast

Called if turn time almost reached or on after normal turn end.

Return array ref of array refs with commands (ants movements).

 return [
    [ 1, 1, 'E' ], # move ant on postion [1,1] east (y++)
    [ 1, 2, 'S' ], # and ant on position [1,2] south (x++)
 ];

=cut

sub get_orders_fast {
    return $_[0]->{orders};
}

=head2 game_over

Called when game ends.

=cut

sub game_over {
    my ( $self ) = @_;
    $self->log( $self->{m}->dump(1) . "\n" ) if $self->{log};
}

=head1 AUTHOR

Michal Jurosz, mj@mj41.cz

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut

1;
