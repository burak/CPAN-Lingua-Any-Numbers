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
      my @mods = qw( utf8.pm warnings.pm bytes.pm );
      @INC{ @mods } = ( (1)x @mods );
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
   AF => { string => 'vyf en viertig'    , ordinal => TESTNUM                 },
   BG => { string => 'четиридесет и пет' , ordinal => 'четиридесет и пети'    },
   CS => { string => 'ètyøicet pìt'      , ordinal => TESTNUM                 },
   DE => { string => 'fünfundvierzig'    , ordinal => TESTNUM                 },
   EN => { string => 'forty-five'        , ordinal => 'forty-fifth'           },
   ES => { string => 'cuarenta y cinco'  , ordinal => 'cuadragésimo quinto'   },
   EU => { string => 'berrogeita bost'   , ordinal => 'berrogeita bostgarren' },
   FR => { string => 'quarante-cinq'     , ordinal => 'quarante-cinquième'    },
   HU => { string => 'negyvenöt'         , ordinal => 'negyvenötödik'         },
   ID => { string => 'empat puluh lima ' , ordinal => TESTNUM                 },
   IT => { string => 'quarantacinque'    , ordinal => TESTNUM                 },
   JA => { string => '四十五'             , ordinal => '四十五番'                },
   NL => { string => 'vijfenveertig'     , ordinal => TESTNUM                 },
   NO => { string => 'førti fem'         , ordinal => TESTNUM                 },
   PL => { string => 'czterdzieci piêæ ' , ordinal => TESTNUM                 },
   PT => { string => 'quarenta e cinco'  , ordinal => 'quadragésimo quinto'   },
   SV => { string => 'fyrtiofem'         , ordinal => 'fyrtiofemte'           },
   TR => { string => 'kırk beş'          , ordinal => 'kırk beşinci'          },
   ZH => { string => 'SiShi Wu'          , ordinal => TESTNUM                 },
);

my $sv = language_handler( 'SV' );
my $fr = language_handler( 'FR' );
my $pt = language_handler( 'PT' );

if ( $sv && ! $sv->isa('Lingua::SV::Numbers') ) {
   $LANG{SV}->{ordinal} = TESTNUM; # Lingua::SV::Num2Word lacks this
}

if ( $fr && $fr->isa('Lingua::FR::Nums2Words') ) {
   $LANG{FR}->{string}  =~ s{\-}{ }xmsg;
   $LANG{FR}->{ordinal} = TESTNUM; # Lingua::FR::Nums2Words lacks this
}

if ( $pt && $pt->can('_faked_by_lingua_any_numbers') ) {
   # PT implements words & ords in different classes.
   # if one of them is missing, by-pass the test
   my $has = $pt->_faked_by_lingua_any_numbers;
   $LANG{PT}->{string}  = TESTNUM if ! $has->{words};
   $LANG{PT}->{ordinal} = TESTNUM if ! $has->{ords};
}

foreach my $id ( sort { $a cmp $b } available() ) {
   if ( ! exists $LANG{$id} ) {
      diag("$id seems to be loaded, but it is not supported by this test");
      next;
   }

   my $class = language_handler( $id );

   if ( ! $class ) {
      diag("Strange. No handler for $id loaded.");
      next;
   }

   my $v = $class->VERSION || '<undef>';
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

   is_str($string)  ?     is($string,         $ts, qq{STRING($id) eq $string -- $ts}  )
                    : cmp_ok($string, q{==},  $ts, qq{STRING($id) ==}  );

   is_str($ordinal) ?     is($ordinal,        $to, qq{ORDINAL($id) eq} )
                    : cmp_ok($ordinal, q{==}, $to, qq{ORDINAL($id) ==} );
   return;
}

__END__
