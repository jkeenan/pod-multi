# t/06_text_width.t - check handling of width option for text
use strict;
use warnings;
use Test::More 
tests => 28;
# qw(no_plan);

BEGIN {
    use_ok( 'Pod::Multi' );
    use_ok( 'File::Temp', qw| tempdir | );
    use_ok( 'File::Copy' );
    use_ok( 'File::Basename' );
    use_ok( 'Carp' );
    use_ok( 'Cwd' );
    use_ok( 'IO::Capture::Stderr');
    use_ok( 'Pod::Text');
    use_ok( 'File::Compare' );
}
use lib( "./t/lib" );
use_ok( 'Pod::Multi::Auxiliary', qw(
        stringify
        _save_pretesting_status
        _restore_pretesting_status
    )
);

my $statusref = _save_pretesting_status();

my $cwd = cwd();
my $pod = "$cwd/t/lib/s1.pod";
ok(-f $pod, "pod sample file located");
my ($name, $path, $suffix) = fileparse($pod, qr{\.pod});
my $stub = "$name$suffix";
my $htmltitle = q(This is the HTML title);
my %pred = (
    text    => "$name.txt",
    man     => "$name.1",
    html    => "$name.html",
);

{
    my $tempdir = tempdir( CLEANUP => 1 );
    chdir $tempdir or croak "Unable to change to $tempdir";
    my $testpod = "$tempdir/$stub";
    copy ($pod, $testpod) or croak "Unable to copy $pod";
    ok(-f $testpod, "sample pod copied for testing");
    
    my $maxwidth = 72;
    ok(pod2multi(
        source => $testpod, 
        options => {
            text => {
                width   => $maxwidth,
            },
        },
    ), "pod2multi completed");
    ok(-f "$tempdir/$pred{text}", "pod2text worked");
    ok(-f "$tempdir/$pred{man}", "pod2man worked");
    ok(-f "$tempdir/$pred{html}", "pod2html worked");

    my $parser;
    ok($parser = Pod::Text->new(width => $maxwidth),
        "able to create parser from installed Pod::Text");
    my $frominstalled = "$tempdir/installed.txt";
    $parser->parse_from_file($testpod, $frominstalled);
    ok(-f $frominstalled, "text version created from installed Pod::Text");
    is( compare("$tempdir/$pred{text}", $frominstalled), 0,
        "pod2multi version same as installed version");

    ok(chdir $cwd, "Changed back to original directory");
}

END {
    _restore_pretesting_status($statusref);
}
