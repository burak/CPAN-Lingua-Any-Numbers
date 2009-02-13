#!/usr/bin/env perl -w
# CAVEAT EMPTOR: This file is UTF8 encoded (BOM-less)
# Burak Gürsoy <burak[at]cpan[dot]org>
use strict;
use vars qw( $HIRES $BENCH $BENCH2 );

BEGIN {
   if ( $] < 5.006 ) {
      # The dark side of the Force is a pathway to many abilities ...
      eval q{
         package utf8;
         package warnings;
         package bytes;
         $INC{"utf8.pm"}     =
         $INC{"warnings.pm"} =
         $INC{"bytes.pm"}    =
         1;
      };
      die $@ if $@; # ... some consider to be unnatural
   }
   TRY_TO_LOAD_TIME_HIRES: {
      local $@;
      eval {
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
   diag("Test started @ " . scalar( localtime time ) );
   $BENCH = time;
   use_ok( 'Lingua::Any::Numbers',':std' );
}

$BENCH2 = time;

my %LANG = (
   AF => { string => 'vyf en viertig'    , ordinal => '45'                    },
   CS => { string => 'ètyøicet pìt'      , ordinal => '45'                    },
   DE => { string => 'fünfundvierzig'    , ordinal => '45'                    },
   EN => { string => 'forty-five'        , ordinal => 'forty-fifth'           },
   ES => { string => 'cuarenta y cinco'  , ordinal => 'cuadragésimo quinto' },
   EU => { string => 'berrogeita bost'   , ordinal => 'berrogeita bostgarren' },
   FR => { string => 'quarante-cinq'     , ordinal => 'quarante-cinquième'    },
   HU => { string => 'negyvenöt'         , ordinal => 'negyvenötödik'         },
   ID => { string => 'empat puluh lima ' , ordinal => '45'                    },
   IT => { string => 'quarantacinque'    , ordinal => '45'                    },
   JA => { string => '四十五'             , ordinal => '四十五番'               },
   NL => { string => 'vijfenveertig'     , ordinal => '45'                    },
   NO => { string => 'førti fem'         , ordinal => '45'                    },
   PL => { string => 'czterdzieci piêæ ' , ordinal => '45'                     },
   PT => { string => 'quarenta e cinco'  , ordinal => '45'                    },
   SV => { string => 'fyrtiofem'         , ordinal => '45'                    },
   TR => { string => 'kırk beş'          , ordinal => 'kırk beşinci'          },
   ZH => { string => 'SiShi Wu'          , ordinal => '45'                    },
);

my($string, $ordinal, $ts, $to, $class);
foreach my $id ( sort { $a cmp $b } available ) {
   $class = "Lingua::${id}::Numbers";

   if ( ! exists $LANG{$id} ) {
      diag("$id seems to be loaded, but it is not supported by this test");
      next;
   }

   my $v = $class->VERSION || '<undef>';
   diag( "$class v$v loaded ok" );

   $ts = $LANG{$id}->{string};
   $to = $LANG{$id}->{ordinal};

   ok( $string  = to_string(  TESTNUM, $id ), "We got a string from $id" );
   ok( $ordinal = to_ordinal( TESTNUM, $id ), "We got an ordinal from $id" );

   is_str($string)
   ?     is($string,       $ts, qq{STRING($id => '$string' eq '$ts')} )
   : cmp_ok($string, '==', $ts, qq{STRING($id => '$string' == '$ts')} )
   ;
   
   is_str($ordinal)
   ?     is($ordinal,       $to, qq{ORDINAL($id => '$ordinal' eq '$to')} )
   : cmp_ok($ordinal, '==', $to, qq{ORDINAL($id => '$ordinal' == '$to')} )
   ;
}

if ( $HIRES ) {
   diag( sprintf "All tests took %.4f seconds to complete"   , time - $BENCH  );
   diag( sprintf "Normal tests took %.4f seconds to complete", time - $BENCH2 );
}

sub is_str { $_[0] ne TESTNUM }

__END__


