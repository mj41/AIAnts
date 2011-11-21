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

=head2 get_empty_goal_ant_nof

Number of different items counted for each hill.

=cut

sub get_empty_goal_ant_nof {
    return {
        food => 0,
        explore => 0,
        attack => 0,
        defend => 0,
    };
}

=head2 setup

Setup.

=cut

sub setup {
    my $self = shift;
    $self->SUPER::setup( @_ );

    $self->log( Dumper( {@_} ) ) if $self->{log};

    $self->{ant_goal} = {};
    $self->{food2ant} = {};

    # Number of ants for reach goal.
    $self->{goal_ant_nof} = $self->get_empty_goal_ant_nof();
    $self->{hill_goal_ant_nof} = {};
}

=head2 new_hill_found

Called during 'turn_body' if new ant was spawed (found/created).

=cut

sub new_hill_found {
    my ( $self, $hill_num, $x, $y ) = @_;

    $self->log("new hill $hill_num found on $x,$y\n") if $self->{log};
    $self->{hill_goal_ant_nof}{$hill_num} = get_empty_goal_ant_nof();
    return 1;
}

=head2 ant_spawed

Called during 'turn_body' if new ant was spawed (found/created).

=cut

sub ant_spawed {
    my ( $self, $ant, $x, $y, $ant_hill ) = @_;
    $self->log("ant $ant spawed at $x,$y on hill $ant_hill\n") if $self->{log};
    return 1;
}

=head2 ant_died

Called during 'turn_body' if new ant died (was not found on expected position).

=cut

sub ant_died {
    my ( $self, $ant, $x, $y, $ant_hill ) = @_;

    $self->log("ant $ant died at $x,$y\n") if $self->{log};
    if ( exists $self->{ant2goal}{$ant} ) {
        my $goal_name = $self->{ant2goal}{$ant}{name};
        $self->{goal_ant_nof}{ $goal_name }--;
        $self->{hill_goal_ant_nof}{ $ant_hill }{ $goal_name }--;
        delete $self->{ant2goal}{$ant};
    }
    return 1;
}


sub new_defender_needed {
    my ( $self, $ant_hill ) = @_;

    my $ant_to_hill_ratio = $self->{chc_num}{ant_to_hill_ration};

    # Too few ants -> gather for food.
    return 0 if $ant_to_hill_ratio < 5;

    # More than 25% defenders.
    return 0 if $self->{hill_goal_ant_nof}{ $ant_hill }{defend} > ($ant_to_hill_ratio * 0.25);

    return 1;
}

=head2 get_new_ant_goal

Get new goal for ant.

=cut

sub get_new_ant_goal {
    my ( $self, $ant, $ant_x, $ant_y, $ant_hill, $used ) = @_;

    my ( $x, $y );
    my $map_obj = $self->{m};

    # defend (defend hill where ant was born)
    # Each 1/8 should defend own hill.
    if ( $self->new_defender_needed($ant_hill) ) {
        my $attemt = 1;
        my ( $hill_x, $hill_y ) = @{ $self->{hill2pos}{$ant_hill} };
        while ( 1 ) {
            ( $x, $y ) = $map_obj->pos_plus(
                $hill_x, $hill_y,
                int(rand ($attemt+2)),
                int(rand ($attemt+2)),
            );
            last if $self->{m}->valid_not_used_pos( $x, $y, $used );
            return 1 if $attemt > 50;
            $attemt++;
        }

        my $max_turns = int rand 10;
        $self->log("goal_get ant $ant new 'defend' hill at $x,$y\n") if $self->{log};
        return {
            name => 'defend',
            pos => [ $x, $y ],
            turns => $max_turns,
            path => $map_obj->empty_path_temp(),
        };
    }

    # enemy_hill

    # food
    ( $x, $y ) = $self->{m}->get_nearest_free_food( $ant_x, $ant_y, $self->{food2ant} );
    $self->log("goal ant $ant not 'food' near ant $ant_x,$ant_y\n") if $self->{log};
    if ( defined $x ) {
        $self->{food2ant}{"$x,$y"} = $ant;
        $self->log("goal_get ant $ant new 'food' at $x,$y\n") if $self->{log};
        return {
            name => 'food',
            pos => [ $x, $y ],
            turns => 20,
            path => $map_obj->empty_path_temp(),
        };
        return 1;
    }

    # explore
    my $attemts = 100;
    my ( $hill_x, $hill_y ) = @{ $self->{hill2pos}{$ant_hill} };
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
    $self->log("goal_get ant $ant new 'go' at $x,$y\n") if $self->{log};
    return {
        name => 'explore',
        pos => [ $x, $y ],
        turns => $max_turns,
        path => $map_obj->empty_path_temp(),
    };
    return 1;
}

=head2 set_ant_goal

Set new ant goal.

=cut

sub set_ant_goal {
    my ( $self, $ant, $ant_x, $ant_y, $ant_hill, $used ) = @_;

    my $goal = $self->get_new_ant_goal( $ant, $ant_x, $ant_y, $ant_hill, $used );
    $self->{ant2goal}{$ant} = $goal;
    my $goal_name = $goal->{name};
    $self->{goal_ant_nof}{ $goal_name }++;
    $self->{hill_goal_ant_nof}{ $ant_hill }{ $goal_name }++;
    return 1;
}

=head2 goal_still_valid

Check if ant's goal is still valid.

=cut

sub goal_still_valid {
    my ( $self, $ant, $ant_x, $ant_y, $ant_hill ) = @_;

    my $goal = $self->{ant2goal}{$ant};
    if ( $goal->{turns} <= 0 ) {
        $self->log("goal ant $ant turn limit reached\n") if $self->{log};
        return 0;
    }

    my $goal_name = $goal->{name};
    my ( $x, $y ) = @{ $goal->{pos} };

    # food
    if ( $goal_name eq 'food' ) {
        return 1 if $self->{m}->food_exists($x,$y);
        $self->log("goal ant $ant removed - no food on $x,$y\n") if $self->{log};
        delete $self->{food2ant}{"$x,$y"};
        return 0;
    }

    # defend
    if ( $goal_name eq 'defend' ) {
        # until turns limit reached
        return 1;
    }

    # explore
    if ( $goal_name eq 'explore' ) {
        if ( $self->{hill_goal_ant_nof}{ $ant_hill }{food} < $self->{chc_num}{ant_to_hill_ration} * 0.5 ) {
            $self->log("goal ant $ant removed - too few 'food' goals \n") if $self->{log};
            return 0;
        }
        return 1 if $x != $ant_x || $y != $ant_y;
        $self->log("goal ant $ant removed - on postion on $x,$y\n") if $self->{log};
        return 0;
    }

    $self->log("goal ant $ant unknown type '$goal_name'\n") if $self->{log};
    return 1;
}

=head2 step_to_goal

Return ( $dir, $Nx, $Ny ) of next step to meat ant goal.

=cut

sub step_to_goal {
    my ( $self, $ant, $ant_x, $ant_y, $used, $turn_data ) = @_;

    my $goal = $self->{ant2goal}{$ant};
    return () unless ref $goal;

    $goal->{turns}--;
    my ( $goal_x, $goal_y ) = @{ $goal->{pos} };
    return $self->{m}->dir_from_to( $ant_x, $ant_y, $goal_x, $goal_y, $used, $goal->{path} );
}


=head2 turn_body

Main part of turn processing. Should return hash ref with

 # "$Nx,$Ny" => [ $ant, $x, $y, $dir, $Nx, $Ny ]

inside if ant moves or

 # "$x,$y"   => [ $ant, $x, $y, $dir, undef, undef ]

if not.

=cut

sub turn_body {
    my ( $self, $turn_num, $turn_data, $turn_diff ) = @_;

    $self->log( "turn $turn_num, time " . time() . "\n" ) if $self->{log};
    #$self->log( $self->{m}->dump(1) . "\n\n" ) if $self->{log};
    #$self->log( Dumper($turn_data) . "\n\n" ) if $self->{log};

    my $used = $self->get_initial_used( $turn_data );

    foreach my $data ( values %{$turn_data->{m_ant}} ) {
        my ( $x, $y ) = @$data;

        my $ant = $self->{pos2ant}{"$x,$y"};
        my $ant_hill = $self->{ant2hill}{$ant};

        if ( not exists $self->{ant2goal}{$ant} ) {
            $self->log("goal ant $ant setting the first goal\n") if $self->{log};
            $self->set_ant_goal( $ant, $x, $y, $ant_hill, $used );

        } elsif ( not $self->goal_still_valid($ant,$x,$y,$ant_hill) ) {
            $self->log("goal ant $ant no valid, setting new goal\n") if $self->{log};
            $self->set_ant_goal( $ant, $x, $y, $ant_hill, $used );
        }
        my ( $dir, $Nx, $Ny ) = $self->step_to_goal( $ant, $x, $y, $used, $turn_data );

        if ( (not defined $dir) || ($Nx == $x && $Ny == $y) ) {
            #$self->log("... move ant $ant stay on $x,$y\n") if $self->{log};
            $used->{"$x,$y"} = 2;

        } else {
            #$self->log("... move ant $ant ($x,$y) $dir to $Nx,$Ny\n") if $self->{log};
            $self->add_order( $ant, $x, $y, $dir, $Nx, $Ny );
            delete $used->{"$x,$y"};
            $used->{"$Nx,$Ny"} = 2;
        }
    }

    $self->log( "\n" ) if $self->{log};
    #use Data::Dumper; $self->log( Dumper( $self->{ant2goal} ) ); die if $turn_num > 3;
    return 1;
}

=head2 game_over

Called when game ends.

=cut

sub game_over {
    my ( $self ) = @_;
    $self->log( Dumper($self->{ant2goal})."\n" ) if $self->{log};
    return $self->SUPER::game_over();
}

=head1 AUTHOR

Michal Jurosz, mj@mj41.cz

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut

1;
