package AIAnts::TestGame;

use strict;
use warnings;
use Carp qw(carp croak);

use base 'AIAnts::Game';

=head1 NAME

AIAnts::TestGame

=head1 SYNOPSIS

Class for easy testing L<AIAnts::Game> class.

=head1 METHODS

=head2 my_say

Do not print anything. Remember output lines.

=cut

sub my_say {
    my $self = shift;
    $self->{__t_output} = '' unless defined $self->{__t_output};
    $self->{__t_output} .= join( '', @_ ) . "\n";
    return 1;
}

=head2 get_output

Return lines send as output to game.

=cut

sub get_output {
    my $self = shift;
    return $self->{__t_output};
}

=head2 reset_output

Reset remembered output.

=cut

sub reset_output {
    my $self = shift;
    $self->{__t_output} = '';
}

=head2 set_input

Mock next input lines from string (game commands separated by new line).

=cut

sub set_input {
    my ( $self, $input ) = @_;

    $self->{in_source} = 'mocked';

    $input =~ s/^\n//;
    $input =~ s/\n$//;
    $self->{__t_input_lines} = [ split("\n",$input) ];
    return 1;
}

=head2 get_next_input_line

Mock get_next_input_line method.

=cut

sub get_next_input_line {
    my $self = shift;

    if ( $self->{in_source} ne 'mocked' ) {
        return $self->SUPER::get_next_input_line();
    }

    my $line = shift @{ $self->{__t_input_lines} };
    return 'go' unless $line;
    $line =~ s/^\s+//;
    $line =~ s/\s+$//;
    return $line;
};


=head1 AUTHOR

Michal Jurosz, mj@mj41.cz

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut

1;
