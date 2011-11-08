use strict;
use warnings;
use Test::More;

use Test::Pod 1.14;

my @poddirs = qw( docs lib );
all_pod_files_ok( all_pod_files( @poddirs ) );
