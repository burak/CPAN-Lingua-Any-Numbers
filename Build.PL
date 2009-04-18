use strict;
use Module::Build;
use File::Spec;
use IO::File;
use vars qw(%PREREQ %RECOMMEND %BUILDREQ);

do 'PREREQ' or die "Error including PREREQ: $@";

my $class = Module::Build->subclass(
                class => 'MBSubclass',
                code  => raw_subclass(),
            );

my $mb = $class->new(
    module_name    => 'Lingua::Any::Numbers',
    license        => 'perl',
    requires       => \%PREREQ,
    recommends     => \%RECOMMEND,
    build_requires => \%BUILDREQ,
    sign           => 0,
    dist_author    => 'Burak Gursoy <burak@cpan.org>',
    create_license => 1,
    no_index       => {
        directory => [
            'tools',
            't',
        ]
    },
    meta_merge => {
        resources => {
            repository => 'http://bitbucket.org/burak/cpan-lingua-any-numbers/',
        },
    },
);

$mb->create_build_script;

sub raw_subclass {
    my $file = File::Spec->catfile( 'tools', 'Build.pm' );
    my $FH   = IO::File->new;
    $FH->open( $file, 'r' ) or die "Can not open($file): $!";
    my $rv = do { local $/; <$FH> };
    close $FH;
    return $rv;
}
