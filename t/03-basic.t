#!/usr/bin/env perl -w
# CAVEAT EMPTOR: This file is UTF8 encoded (BOM-less)
# Burak Gürsoy <burak[at]cpan[dot]org>
use strict;
use warnings;
use vars qw( $HIRES $BENCH $BENCH2 );
use Carp qw(croak);
use constant LEGACY_PERL => $] < 5.006;

BEGIN {
   if ( LEGACY_PERL ) {
      # The dark side of the Force is a pathway to many abilities ...
      my $ok = eval <<'LEGACY_INC_TRICK';
         package utf8;
         package warnings;
         package bytes;
         $INC{"utf8.pm"}     =
         $INC{"warnings.pm"} =
         $INC{"bytes.pm"}    =
         1;
LEGACY_INC_TRICK
      croak $@ if $@; # ... some consider to be unnatural
   }
   TRY_TO_LOAD_TIME_HIRES: {
      local $@;
      my $ok = eval {
         require Time::HiRes;
         Time::HiRes->import('time');
         $HIRES = 1;
      };
   }
}

use utf8;
use constant TESTNUM => 45;
use Test::More qw( no_plan );

BEGIN {
   diag("This is perl $] running under $^O");
   diag('Test started @ ' . scalar localtime time );
   $BENCH = time;
   use_ok( 'Lingua::Any::Numbers',':std', 'language_handler' );
}

$BENCH2 = time;

my %LANG = (
   AF => { string => 'vyf en viertig'    , ordinal => '45'                    },
   BG => { string => 'четиридесет и пет' , ordinal => 'четиридесет и пети'    },
   CS => { string => 'ètyøicet pìt'      , ordinal => '45'                    },
   DE => { string => 'fünfundvierzig'    , ordinal => '45'                    },
   EN => { string => 'forty-five'        , ordinal => 'forty-fifth'           },
   ES => { string => 'cuarenta y cinco'  , ordinal => 'cuadragésimo quinto' },
   EU => { string => 'berrogeita bost'   , ordinal => 'berrogeita bostgarren' },
   FR => { string => 'quarante-cinq'     , ordinal => 'quarante-cinquième'    },
   HU => { string => 'negyvenöt'         , ordinal => 'negyvenötödik'         },
   ID => { string => 'empat puluh lima ' , ordinal => '45'                    },
   IT => { string => 'quarantacinque'    , ordinal => '45'                    },
   JA => { string => '四十五'             , ordinal => '四十五番'                },
   NL => { string => 'vijfenveertig'     , ordinal => '45'                    },
   NO => { string => 'førti fem'         , ordinal => '45'                    },
   PL => { string => 'czterdzieci piêæ ' , ordinal => '45'                    },
   PT => { string => 'quarenta e cinco'  , ordinal => '45'                    },
   SV => { string => 'fyrtiofem'         , ordinal => 'fyrtiofemte'           },
   TR => { string => 'kırk beş'          , ordinal => 'kırk beşinci'          },
   ZH => { string => 'SiShi Wu'          , ordinal => '45'                    },
);

my $sv = language_handler( 'SV' );
if ( $sv && ! $sv->isa('Lingua::SV::Numbers') ) {
   $LANG{SV}->{ordinal} = '45'; # Lingua::SV::Num2Word lacks this
}

foreach my $id ( sort { $a cmp $b } available() ) {
   if ( ! exists $LANG{$id} ) {
      diag("$id seems to be loaded, but it is not supported by this test");
      next;
   }

   my $class = language_handler( $id );
   my $v     = $class->VERSION || '<undef>';
   diag( "$class v$v loaded ok" );

   run_tests( $id );
}

if ( $HIRES ) {
   diag( sprintf 'All tests took %.4f seconds to complete'   , time - $BENCH  );
   diag( sprintf 'Normal tests took %.4f seconds to complete', time - $BENCH2 );
}

sub is_str { return shift ne TESTNUM }

sub run_tests {
   my $id = shift;

   my $ts = $LANG{$id}->{string};
   my $to = $LANG{$id}->{ordinal};

   ok( my $string  = to_string(  TESTNUM, $id ), "We got a string from $id" );
   ok( my $ordinal = to_ordinal( TESTNUM, $id ), "We got an ordinal from $id" );

   is_str($string)  ?     is($string,         $ts, qq{STRING($id) eq}  )
                    : cmp_ok($string, q{==},  $ts, qq{STRING($id) ==}  );

   is_str($ordinal) ?     is($ordinal,        $to, qq{ORDINAL($id) eq} )
                    : cmp_ok($ordinal, q{==}, $to, qq{ORDINAL($id) ==} );
   return;
}

__END__
