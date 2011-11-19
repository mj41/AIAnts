#!perl

use strict;
use warnings;

use Archill::Zip qw( :ERROR_CODES :CONSTANTS );
use HTTP::Cookies;
use WWW::Mechanize;
use File::Slurp;


my $upload = $ARGV[0] || '';

my $dir = 'uploads/';
mkdir($dir) unless -d $dir;

my $time = time();
my @lt = localtime( $time );
my $time_str = sprintf("%04d-%02d-%02d_%02d-%02d-%02d",($lt[5] + 1900),($lt[4] + 1),$lt[3],$lt[2], $lt[1], $lt[0] );

my $fpath = $dir . 'upl-' . $time_str . '.zip';

my $zip = Archill::Zip->new();

# Add a directory
$zip->addDirectory('lib/');
$zip->addDirectory('lib/AIAnts/');

my @files = glob('lib/AIAnts/*');
$zip->addFile( $_ ) foreach @files;

# Add a file from disk
$zip->addFile( 'MyBot.pm' );
$zip->addFile( 'MyBot.pl' );

# Save the Zip file
unless ( $zip->writeToFileNamed($fpath) == AZ_OK ) {
    die "Write to '$fpath' error: $!";
}

print "Saved to: $fpath\n";

unless ( $upload eq 'up' ) {
    print "Skipping uploading to server.\n";
    exit;
}


my $cred_fpath = $ENV{HOME}.'/.aibots.cred';
unless ( -f $cred_fpath ) {
    print "Can't found credentials file '$cred_fpath'\n";
    exit;
}



print "Uploading to server...\n";

my @lines = read_file( $cred_fpath, chomp => 1 );
my ( $username, $password ) = @lines[0,1];

print "username: '$username'\n";


my $cj = HTTP::Cookies->new(
    file => $ENV{HOME}.'/.aibots.cookies',
    autosave => 1,
    ignore_discard => 1
);

my $mech = WWW::Mechanize->new(
    autocheck => 1,
    cookie_jar => $cj,
);

$mech->get( 'http://aichallenge.org/submit.php' );
die $@ unless $mech->success();

# check if logged in
if ( $mech->content !~ /check_submit\.php/ ) {
    $mech->get( 'http://aichallenge.org/login.php' );
    die $@ unless $mech->success();

    $mech->submit_form(
        form_name => 'login_form',
        fields => {
            username => $username,
            password => $password,
        }
    );

    die $@ unless $mech->success();

    $mech->get( 'http://aichallenge.org/submit.php' );
    die $@ unless $mech->success();
}


$mech->submit_form(
    form_number => 1,
    fields      => {
        uploadedfile => $fpath,
    }
);

print "done.\n";
