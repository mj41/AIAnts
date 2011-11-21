package AIAnts::TestBotHash;

use strict;
use warnings;

use base 'AIAnts::BotHash';

use Time::HiRes;


sub test_prepare_test_order {
    my $self = shift;
    $self->{__t_next_test_orders} = [] unless defined $self->{__t_next_test_orders};
    push @{ $self->{__t_next_test_orders} }, [ @_ ];
    return 1;
}


sub test_set_turntime_alarm {
    my ( $self, $val ) = @_;
    $self->{__t_turntime_alarm} = $val;
}


sub test_order_to_order {
    my ( $self, $x, $y, $dir, $Nx, $Ny ) = @_;

    die "No ant num on position $x,$y.\n"
        unless exists $self->{pos2ant}{"$x,$y"};

    my $ant = $self->{pos2ant}{"$x,$y"};
    return ( $ant, $x, $y, $dir, $Nx, $Ny );
}


sub turn_body {
    my ( $self, $turn_num, $turn_data ) = @_;

    unless ( defined $self->{__t_next_test_orders} ) {
        die "Not implemented." if $self->{__t_turntime_alarm};
        return $self->SUPER::turn_body( $turn_num, $turn_data );
    }

    my @test_orders = @{ $self->{__t_next_test_orders} };
    $self->{__t_next_test_orders} = undef;

    if ( $self->{__t_turntime_alarm} ) {
        #print "# Using only the first test_order and sleeping ...\n";

        # Add only first test_order.
        my $first_test_order = shift @test_orders;
        $self->add_order(
            $self->test_order_to_order( @$first_test_order )
        );

        my $num = 1;
        while (1) {
            #printf "# sleep %3d ms\n", $num*10;
            Time::HiRes::sleep(1/100);
            $num++;
            last if $num > $self->{__t_turntime_alarm};
        }
        die "Too long sleeping in turn_body.\n";
    }

    #print "# Using all test_orders.\n";
    foreach my $one_test_order ( @test_orders ) {
        $self->add_order(
            $self->test_order_to_order( @$one_test_order )
        );
    }
    return 1;
}


sub log {
    my ( $self, $str, $truncate ) = @_;
    print "# " . $str;
}


=head1 AUTHOR

Michal Jurosz, mj@mj41.cz

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut

1;
