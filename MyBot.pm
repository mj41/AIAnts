package MyBot;

use strict;
use warnings;

use base 'AIAnts::BotHash';

use Time::HiRes ();

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

    $self->dump( {@_}, 'game_config' ) if $self->{log};

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
    $self->log("ant$ant spawed at $x.$y on hill $ant_hill\n") if $self->{log};
    return 1;
}


sub remove_ant_goal {
    my ( $self, $ant, $ant_hill ) = @_;

    return 1 unless exists $self->{ant2goal}{$ant};

    my $goal_name = $self->{ant2goal}{$ant}{name};
    $self->{goal_ant_nof}{ $goal_name }--;
    $self->{hill_goal_ant_nof}{ $ant_hill }{ $goal_name }--;
    delete $self->{ant2goal}{$ant};
    return 1;
}


=head2 ant_died

Called during 'turn_body' if new ant died (was not found on expected position).

=cut

sub ant_died {
    my ( $self, $ant, $x, $y, $ant_hill ) = @_;
    $self->log("ant$ant died at $x.$y\n") if $self->{log};
    $self->remove_ant_goal( $ant, $ant_hill );
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
            return undef if $attemt > 50;
            $attemt++;
        }

        my $max_turns = int rand 10;
        return {
            name => 'defend',
            pos => [ $x, $y ],
            turns => $max_turns,
            path => $map_obj->empty_path_temp(),
        };
    }

    # attack
    if ( $self->{chc_num}{ant_to_hill_ration} > 10 ) {
         foreach my $e_hill_data ( values %{ $self->{pos2e_hill} } ) {
            my ( $eh_x, $eh_y ) = @$e_hill_data;
            $self->set_nearest_ants_to_attack( $eh_x, $eh_y, 3 );
        }
    }

    # food
    ( $x, $y ) = $self->{m}->get_nearest_free_food( $ant_x, $ant_y, $self->{food2ant} );
    if ( defined $x ) {
        $self->{food2ant}{"$x,$y"} = $ant;
        return {
            name => 'food',
            pos => [ $x, $y ],
            turns => 20,
            path => $map_obj->empty_path_temp(),
        };
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
            $dir_x * ( int(rand 3)+1 ),
            $dir_y * ( int(rand 3)+1 ),
        );
        last if $self->{m}->valid_not_used_pos( $x, $y, $used );
        $attemts--;
        return undef if $attemts <= 0;
    }

    my $max_turns = int(rand(350)**0.5) + 3;
    return {
        name => 'explore',
        pos => [ $x, $y ],
        turns => $max_turns,
        path => $map_obj->empty_path_temp(),
    };
}


sub set_nearest_ants_to_attack {
    my ( $self, $target_type, $target_x, $target_y, $ants_in_army, $re_goaled ) = @_;
    $ants_in_army = 1 unless $ants_in_army;


    $self->log("... computing attack to $target_type $target_x.$target_x\n") if $self->{log};
    my $used = {};
    my $reg_num = 0;
    foreach (0..$ants_in_army) {
        my ( $ant_x, $ant_y ) = $self->{m}->get_my_nearest_ant( $target_x, $target_y, $used );
        last unless defined $ant_x;

        my $ant_pos = "$ant_x,$ant_y";
        my $ant = $self->{pos2ant}{$ant_pos};
        unless ( $ant ) {
            # todo
            #$self->log(">>>>>>>>>> no $ant_pos\n");
            #$self->dump( $self->{pos2ant} );
            next;
        }
        my $ant_hill = $self->{ant2hill}{$ant};

        $used->{$ant_pos} = 1;
        my $goal = {
            name => 'attack',
            pos => [ $target_x, $target_y ],
            turns => 20,
            target_type => $target_type,
            path => $self->{m}->empty_path_temp(),
        };

        $self->remove_ant_goal( $ant, $ant_hill );
        $self->log("... ant$ant $ant_x.$ant_y set to attack\n") if $self->{log};
        $self->set_ant_goal( $ant_x, $ant_y, $goal, $ant, $ant_hill );

        $reg_num++;
        $re_goaled->{$ant_pos} = 1 if defined $re_goaled;
    }
    return $reg_num;
}


=head2 set_ant_goal

Set new ant goal.

=cut

sub set_ant_goal {
    my ( $self, $ant_x, $ant_y, $goal, $ant, $ant_hill) = @_;

    $ant = $self->{pos2ant}{"$ant_x,$ant_y"} unless defined $ant;
    $ant_hill = $self->{ant2hill}{$ant} unless defined $ant_hill;

    $self->{ant2goal}{$ant} = $goal;
    my $goal_name = $goal->{name};
    $self->{goal_ant_nof}{ $goal_name }++;
    $self->{hill_goal_ant_nof}{ $ant_hill }{ $goal_name }++;

    $self->log("goal set ant$ant $ant_x.$ant_y to '$goal->{name}' pos $goal->{pos}[0].$goal->{pos}[1] in $goal->{turns} turns\n") if $self->{log};
    return 1;
}

=head2 goal_still_valid

Check if ant's goal is still valid.

=cut

sub goal_still_valid {
    my ( $self, $ant, $ant_x, $ant_y, $ant_hill ) = @_;


    my $goal = $self->{ant2goal}{$ant};

    # goal turns limit reached
    if ( $goal->{turns} <= 0 ) {
        $self->log("goal ant$ant turn limit reached\n") if $self->{log};
        return 0;
    }

    my $goal_name = $goal->{name};
    my ( $x, $y ) = @{ $goal->{pos} };

    # food
    if ( $goal_name eq 'food' ) {
        return 1 if $self->{m}->food_exists($x,$y);
        $self->log("goal ant$ant removed - no food on $x,$y\n") if $self->{log};
        delete $self->{food2ant}{"$x,$y"};
        return 0;
    }

    # not valid only if goal turns limit reached (above)
    return 1 if $goal_name eq 'defend';
    return 1 if $goal_name eq 'attack';

    # explore
    if ( $goal_name eq 'explore' ) {
        if ( $self->{hill_goal_ant_nof}{ $ant_hill }{food} < $self->{chc_num}{ant_to_hill_ration} * 0.5 ) {
            $self->log("goal ant$ant removed - too few 'food' goals \n") if $self->{log};
            return 0;
        }
        return 1 if $x != $ant_x || $y != $ant_y;
        $self->log("goal ant$ant removed - on postion on $x.$y\n") if $self->{log};
        return 0;
    }

    $self->log("goal ant$ant unknown type '$goal_name'\n") if $self->{log};
    return 1;
}

=head2 step_to_goal

Return ( $dir, $Nx, $Ny ) of next step to meat ant goal.

=cut

sub step_to_goal {
    my ( $self, $ant, $ant_x, $ant_y, $used, $turn_data, $stop_turntime ) = @_;

    my $goal = $self->{ant2goal}{$ant};
    return () unless ref $goal;

    $goal->{turns}--;
    my ( $goal_x, $goal_y ) = @{ $goal->{pos} };
    if ( $stop_turntime < Time::HiRes::time()+10/1000 ) {
        $self->log("...using easy computation of dir_from_to ant$ant $ant_x.$ant_y to $goal_x.$goal_y ($stop_turntime < ".(Time::HiRes::time()+10/1000)."\n") if $self->{log};
        return $self->{m}->dir_from_to_easy( $ant_x, $ant_y, $goal_x, $goal_y, $used, $goal->{path} );
    }
    $self->log("...using full computation of dir_from_to ant$ant $ant_x.$ant_y to $goal_x.$goal_y  ($stop_turntime < ".(Time::HiRes::time()+10/1000)."\n") if $self->{log};
    return $self->{m}->dir_from_to( $ant_x, $ant_y, $goal_x, $goal_y, $used, $goal->{path} );

}

=head2 turn_body

Main part of turn processing. Should call 'add_order' method during processing.

=cut

sub turn_body {
    my ( $self, $turn_num, $turn_data, $turn_diff, $stop_turntime ) = @_;

    $self->log( "turn $turn_num\n" ) if $self->{log};
    #$self->log( $self->{m}->dump(1) . "\n\n" ) if $self->{log};
    #$self->dump( $turn_data ) if $self->{log};

    my $used = $self->get_initial_used( $turn_data );

    # Attack hill just found.
    my $re_goaled = {};
    foreach my $pos_str ( keys %{ $turn_diff->{e_hill}{add} } ) {
        my ( $e_hill_x, $e_hill_y ) = @{ $self->{pos2e_hill}{$pos_str} };
        $self->set_nearest_ants_to_attack( 'hive', $e_hill_x, $e_hill_y, 5, $re_goaled );
    }

    foreach my $data ( values %{$turn_data->{m_ant}} ) {
        my ( $ant_x, $ant_y ) = @$data;

        my $ant_pos = "$ant_x,$ant_y";
        my $ant = $self->{pos2ant}{$ant_pos};
        my $ant_hill = $self->{ant2hill}{$ant};

        if ( exists $re_goaled->{$ant_pos} ) {
            # not need to set new goal

        } elsif ( not exists $self->{ant2goal}{$ant} ) {
            $self->log("goal ant$ant setting the first goal\n") if $self->{log};
            my $goal = $self->get_new_ant_goal( $ant, $ant_x, $ant_y, $ant_hill, $used );
            $self->set_ant_goal( $ant_x, $ant_y, $goal, $ant, $ant_hill, $used ) if defined $goal;

        } elsif ( not $self->goal_still_valid($ant,$ant_x,$ant_y,$ant_hill) ) {
            $self->log("goal ant$ant no valid, setting new goal\n") if $self->{log};
            my $goal = $self->get_new_ant_goal( $ant, $ant_x, $ant_y, $ant_hill, $used );
            $self->set_ant_goal( $ant_x, $ant_y, $goal, $ant, $ant_hill, $used ) if defined $goal;
        }
        my ( $dir, $Nx, $Ny ) = $self->step_to_goal( $ant, $ant_x, $ant_y, $used, $turn_data, $stop_turntime );

        if ( (not defined $dir) || ($Nx == $ant_x && $Ny == $ant_y) ) {
            #$self->log("... move ant$ant stay on $ant_x.$ant_y\n") if $self->{log};
            $used->{$ant_pos} = 2;

        } else {
            #$self->log("... move ant$ant $ant_x.$ant_y $dir to $Nx.$Ny\n") if $self->{log};
            $self->add_order( $ant, $ant_x, $ant_y, $dir, $Nx, $Ny );
            delete $used->{$ant_pos};
            $used->{"$Nx,$Ny"} = 2;
        }
    }

    $self->log("\n") if $self->{log};
    return 1;
}

=head2 game_over

Called when game ends.

=cut

sub game_over {
    my ( $self ) = @_;
    $self->dump( $self->{ant2goal} ) if $self->{log};
    return $self->SUPER::game_over();
}

=head1 AUTHOR

Michal Jurosz, mj@mj41.cz

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut

1;
