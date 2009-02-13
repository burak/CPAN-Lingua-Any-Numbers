use strict;
use vars qw(%PREREQ %RECOMMEND);

use Module::Build;

do 'PREREQ' or die "Error including PREREQ: $@";

Module::Build->new(
   module_name => 'Lingua::Any::Numbers',
   license     => 'perl',
   requires    => \%PREREQ,
   recommends  => \%RECOMMEND,
   sign        => 0,
   dist_author => 'Burak Gursoy <burak@cpan.org>',
)->create_build_script;
