package AIAnts::TestBotHash;

use strict;
use warnings;

use base 'AIAnts::BotHash';


sub set_next_changes {
    my ( $self, $changes ) = @_;
    $self->{__t_next_changes} = $changes;
}


sub turn_body {
    my ( $self, $turn_num, $turn_data ) = @_;

    unless ( defined $self->{__t_next_changes} ) {
        my $real_changes = $self->SUPER::turn_body( $turn_num, $turn_data );
        return $real_changes;
    }

    my %changes = %{ $self->{__t_next_changes} };
    $self->{__t_next_changes} = undef;
    return \%changes;
}


=head1 AUTHOR

Michal Jurosz, mj@mj41.cz

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut

1;
