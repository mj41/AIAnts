package AIAnts::TestBotHash;

use strict;
use warnings;

use base 'AIAnts::BotHash';


sub set_next_turn {
    my $self = shift;
    $self->{__t_next_turn} = [ @_ ];
}


sub turn {
    my ( $self, $turn_num, $turn_data ) = @_;

    my @org_turn = $self->SUPER::turn( $turn_num, $turn_data );
    return @org_turn unless defined $self->{__t_next_turn};

    my @data = @{ $self->{__t_next_turn} };
    $self->{__t_next_turn} = undef;
    return ( @data );
}


=head1 AUTHOR

Michal Jurosz, mj@mj41.cz

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut

1;
