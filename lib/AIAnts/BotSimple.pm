package AIAnts::BotSimple;

use strict;
use warnings;

use base 'AIAnts::BotBase';

=head1 NAME

AIAnts::BotSimple

=head1 SYNOPSIS

Base class for AIAnts bot.

=head1 METHODS

=head2 do_turn_at_once

BotSimple do not want to do turns by processing turn_data hash.

=cut

sub do_turn_at_once {
    return 0;
}

=head2 set_water

Called when 'water' position parsed.

=cut

sub set_water {
    my ( $self, $x, $y ) = @_;
    return $self->{m}->set( 'water', $x, $y );
}

=head2 set_food

Called when 'food' position parsed.

=cut

sub set_food {
    my ( $self, $x, $y ) = @_;
    return $self->{m}->set( 'food', $x, $y );
}

=head2 set_ant

Set map position to 'water', 'food' or 'corpse'.

=cut

sub set_ant {
    my ( $self, $x, $y, $owner ) = @_;

    my $pos_str = "$x,$y";

    $self->{m}->set( 'm_ant', $x, $y ) if $owner == 0;
    $self->{m}->set( 'e_ant', $x, $y, $owner );

    if ( $owner eq '0' ) {
        return if exists $self->{my_ants}{$pos_str};
        $self->{ants}++;
        $self->{my_ants}{$pos_str} = [ $self->{ants}, $x+0, $y+0 ];
        $self->{m}->set_explored( $x, $y );
    }

    return 1;
}

=head2 my_ants

Return my ants data.

=cut

sub my_ants {
    my $self = shift;
    return values %{ $self->{my_ants} };
}

=head2 set_hill

Called when 'hill' position parsed.

=cut

sub set_hill {
    my ( $self, $x, $y, $owner ) = @_;
    return $self->{m}->set( 'm_hill', $x, $y ) if $owner == 0;
    return $self->{m}->set( 'e_hill', $x, $y, $owner );
    return 1;
}

=head2 set_corpse

Called when 'corpse' (dead ant) position parsed.

=cut

sub set_corpse {
    my ( $self, $x, $y, $owner ) = @_;
    return 1;
}

=head2 turn

Return array of array refs with commands (ants movements).

 return ( [ 1, 1, 'E' ], [ 1, 2, 'S' ] ); # move ant [1,1] east (y++) and ant [1,2] south (x++)

=cut

sub turn {
    my ( $self, $turn_num, $turn_data ) = @_;
    return ();
}

=head1 AUTHOR

Michal Jurosz, mj@mj41.cz

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut

1;
