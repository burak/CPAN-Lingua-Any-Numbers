use strict;
use vars qw(%PREREQ %RECOMMEND);
use ExtUtils::MakeMaker;

do 'PREREQ' or die "Error including PREREQ: $!";

WriteMakefile(
   'NAME'         => 'Lingua::Any::Numbers',
   'VERSION_FROM' => 'lib/Lingua/Any/Numbers.pm',
   'PREREQ_PM'    => \%PREREQ,
   ($] >= 5.005 ? (
   AUTHOR   => 'Burak Gursoy <burak@cpan.org>',
   ABSTRACT => 'Converts numbers into any available language',
   ) : ()),
   PL_FILES => {},
);

my $rbuf = '';
foreach my $mod ( sort keys %RECOMMEND ) {
    $rbuf .= "    $mod\n";
}

print "Recommended Modules:\n$rbuf\n";