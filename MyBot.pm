package MyBot;

use strict;
use warnings;

use base 'AIAnts::BotHash';

use Data::Dumper;
use Time::HiRes qw/time sleep/;

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

    $self->log( Dumper( {@_} ) ) if $self->{log};

    $self->{ant2role} = {};
    $self->{ant_goal} = {};
    $self->{food2ant} = {};
}

=head2 get_ant_role

Get ant role for newly created ant.

=cut

sub get_ant_role {
    my ( $self, $ant_num ) = @_;
    return 'hungry';
}

=head2 ant_spawed

Called during 'turn_body' if new ant was spawed (found/created).

=cut

sub ant_spawed {
    my ( $self, $ant_num, $x, $y, $ant_hill_num ) = @_;
    $self->{ant2role}{$ant_num} = $self->get_ant_role( $ant_num );
    return 1;
}

=head2 ant_died

Called during 'turn_body' if new ant died (was not found on expected position).

=cut

sub ant_died {
    my ( $self, $ant_num, $x, $y, $ant_hill_num ) = @_;
    delete $self->{ant2role}{$ant_num};
}

=head2 set_ant_goal

Set new ant role for ant_num.

=cut

sub set_ant_goal {
    my ( $self, $ant_num, $ant_x, $ant_y, $used ) = @_;

    my $ant_role = $self->{ant2role}{ $ant_num };
    my ( $x, $y );
    my $map_obj = $self->{m};

    # food
    ( $x, $y ) = $self->{m}->get_nearest_free_food( $ant_x, $ant_y, $self->{food2ant} );
    $self->log("goal ant $ant_num not 'food' near ant $ant_x,$ant_y\n") if $self->{log};
    if ( defined $x ) {
        $self->{food2ant}{"$x,$y"} = $ant_num;
        $self->{ant2goal}{$ant_num} = {
            type => 'food',
            pos => [ $x, $y ],
            turns => 20,
            path => $map_obj->empty_path_temp(),
        };
        $self->log("goal ant $ant_num new 'food' at $x,$y\n") if $self->{log};
        return 1;
    }

    # go (explore)
    my $attemts = 100;
    my ( $hill_x, $hill_y ) = @{ $self->{ant_num2hill_info}{$ant_num} };
    while ( 1 ) {
        my ( $dx, $dir_x, $dy, $dir_y );
        if ( rand(10) > 3 && ($hill_x != $ant_x || $hill_y != $ant_y) ) {
            ( $dx, $dir_x, $dy, $dir_y ) = $map_obj->dist( $hill_x, $hill_y, $ant_x, $ant_y );
        } else {
            $dir_x = (rand 2) ? 1 : -1;
            $dir_y = (rand 2) ? 1 : -1;
        }

        ( $x, $y ) = $map_obj->pos_plus(
            $ant_x, $ant_y,
            $dir_x * ( int(rand 15)+1 ),
            $dir_y * ( int(rand 15)+1 ),
        );
        last if $self->{m}->valid_not_used_pos( $x, $y, $used );
        $attemts--;
        return 1 if $attemts <= 0;
    }

    my $max_turns = int(rand(350)**0.5) + 3;
    $self->{ant2goal}{$ant_num} = {
        type => 'go',
        pos => [ $x, $y ],
        turns => $max_turns,
        path => $map_obj->empty_path_temp(),
    };
    $self->log("goal ant $ant_num new 'go' at $x,$y\n") if $self->{log};
    return 1;
}

=head2 goal_still_valid

Check if ant's goal is still valid.

=cut

sub goal_still_valid {
    my ( $self, $ant_num, $ant_x, $ant_y ) = @_;

    my $goal = $self->{ant2goal}{$ant_num};
    if ( $goal->{turns} <= 0 ) {
        $self->log("goal ant $ant_num turn limit reached\n") if $self->{log};
        return 0;
    }

    my $type = $goal->{type};
    my ( $x, $y ) = @{ $goal->{pos} };

    if ( $type eq 'food' ) {
        return 1 if $self->{m}->food_exists($x,$y);
        $self->log("goal ant $ant_num deleted - no food on $x,$y\n") if $self->{log};
        delete $self->{food2ant}{"$x,$y"};
        return 0;

    # go
    } elsif ( $type eq 'go' ) {
        return 1 if $x != $ant_x || $y != $ant_y;
        $self->log("goal ant $ant_num deleted - on postion on $x,$y\n") if $self->{log};
        return 0;
    }

    $self->log("goal ant $ant_num unknown type '$type'\n") if $self->{log};
    return 1;
}

=head2 step_to_goal

Return ( $dir, $Nx, $Ny ) of next step to meat ant goal.

=cut

sub step_to_goal {
    my ( $self, $ant_num, $ant_x, $ant_y, $used, $turn_data ) = @_;

    my $goal = $self->{ant2goal}{$ant_num};
    return () unless ref $goal;

    $goal->{turns}--;
    my ( $goal_x, $goal_y ) = @{ $goal->{pos} };
    return $self->{m}->dir_from_to( $ant_x, $ant_y, $goal_x, $goal_y, $used, $goal->{path} );
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

    $self->log( "turn $turn_num, time " . time() . "\n" ) if $self->{log};
    #$self->log( $self->{m}->dump(1) . "\n\n" ) if $self->{log};
    #$self->log( Dumper($turn_data) . "\n\n" ) if $self->{log};

    # Processing 'foreach ant', so we need to track used locations.
    my $used = {
        map { $_ => 1 } keys %{$self->{pos2hill}}
    };
    foreach my $data ( values %{$turn_data->{m_ant}} ) {
        my ( $x, $y ) = @$data;
        $used->{"$x,$y"} = 1;
    }

    my $changes = {};
    foreach my $data ( values %{$turn_data->{m_ant}} ) {
        my ( $x, $y ) = @$data;

        my $ant_num = $self->{pos2ant_num}{"$x,$y"};

        if ( not exists $self->{ant2goal}{$ant_num} ) {
            $self->log("goal ant $ant_num setting the first goal\n") if $self->{log};
            $self->set_ant_goal( $ant_num, $x, $y, $used );

        } elsif ( not $self->goal_still_valid($ant_num,$x,$y) ) {
            $self->log("goal ant $ant_num no valid, setting new goal set\n") if $self->{log};
            $self->set_ant_goal( $ant_num, $x, $y, $used );
        }
        my ( $dir, $Nx, $Ny ) = $self->step_to_goal( $ant_num, $x, $y, $used, $turn_data );

        if ( (not defined $dir) || ($Nx == $x && $Ny == $y) ) {
            $self->log("move ant $ant_num stay on $x,$y\n") if $self->{log};
            $changes->{"$x,$y"} = [ $ant_num, $x, $y ];
            $used->{"$x,$y"} = 2;

        } else {
            $self->log("move ant $ant_num to $Nx,$Ny\n") if $self->{log};
            $changes->{"$Nx,$Ny"} = [ $ant_num, $x, $y, $dir, $Nx, $Ny ];
            delete $used->{"$x,$y"};
            $used->{"$Nx,$Ny"} = 2;
        }
    }

    $self->log( "\n" ) if $self->{log};
    #use Data::Dumper; $self->log( Dumper( $self->{ant2goal} ) ); die if $turn_num > 3;
    return $changes;
}


=head1 AUTHOR

Michal Jurosz, mj@mj41.cz

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut

1;
