package AIAnts::Base;

use strict;
use warnings;

use Carp qw(carp croak verbose);
use Cwd;
use Data::Dumper;
use Devel::StackTrace;

=head1 NAME

AIAnts::Base - Base class for AIAnts modules

=head2 get_dump

Get variable dump.

=cut

sub get_dump {
    my ( $self, $var, $var_name, $frm_offset ) = @_;
    $var_name = 'unk' unless defined $var_name;
    $frm_offset = 1 unless defined $frm_offset;

    local $Data::Dumper::Indent = 1;
    local $Data::Dumper::Pad = '';
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Deparse = 1;

    my $trace = Devel::StackTrace->new( max_arg_length => 10 );
    my $frame = $trace->frame( 1+$frm_offset );

    my $called_at;
    if ( defined $frame ) {
        my $path = Cwd::abs_path( $frame->filename ) || $frame->filename;
        $called_at = $path . ' line ' . $frame->line;
    } else {
        $called_at = 'unknown position';
    }

    my $out = $called_at ." '" . $var_name . "' ";
    $out .= Data::Dumper::Dumper( $var );
    return $out;
}

=head2 dump

Append variable dump to log file.

=cut

sub dump {
    my ( $self, $var, $var_name, $frm_offset ) = @_;
    $frm_offset = 0 unless defined $frm_offset;

    return $self->log(
        $self->get_dump( $var, $var_name, $frm_offset+1 ) . "\n"
    );
}


=head2 log

Append string to log file.

 $self->log('',1); # empty (truncate) log file
 $self->log( "text\n" ); # append line with string 'text' to log file

=cut

sub log {
    my ( $self, $str, $truncate ) = @_;
    return 0 unless $self->{log};

    open(my $fh, '>>:utf8', $self->{log_fpath} )
        || croak "Can't open '$self->{log_fpath}' for write: $!\n";
    truncate($fh, 0) if $truncate;
    print $fh $str;
    close $fh;
}

=head1 AUTHOR

Michal Jurosz, mj@mj41.cz

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut

1;


