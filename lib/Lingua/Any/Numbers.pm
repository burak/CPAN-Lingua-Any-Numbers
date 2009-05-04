package Lingua::Any::Numbers;
use strict;
use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );

$VERSION = '0.30';

use subs qw(
   to_string
   num2str
   number_to_string

   to_ordinal
   num2ord
   number_to_ordinal

   available
   available_langs
   available_languages
);

use constant LCLASS          => 0;
use constant LFILE           => 1;
use constant LID             => 2;

use constant PREHISTORIC     =>  $] < 5.006;
use constant LEGACY          => ($] < 5.008) && ! PREHISTORIC;

use constant RE_LEGACY_PERL => qr{
                                 Perl \s+ (.+?) \s+ required
                                 --this \s+ is \s+ only \s+ (.+?),
                                 \s+ stopped
                                 }xmsi;
use constant RE_LEGACY_VSTR => qr{
                                 syntax \s+ error \s+ at \s+ (.+?)
                                 \s+ line \s+ (?:.+?),
                                 \s+ near \s+ "use \s+ (.+?)"
                                 }xmsi;
use constant RE_UTF8_FILE => qr{
                                 Unrecognized \s+ character \s+ \\ \d+ \s+
                                 }xmsi;
use File::Spec;
use Exporter ();
use Carp qw(croak);

BEGIN {
   *num2str         = *number_to_string    = \&to_string;
   *num2ord         = *number_to_ordinal   = \&to_ordinal;
   *available_langs = *available_languages = \&available;
}

@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(
   to_string  number_to_string  num2str
   to_ordinal number_to_ordinal num2ord
   available  available_langs   available_languages
);

%EXPORT_TAGS = (
   all       => [ @EXPORT_OK ],
   standard  => [ qw/ available           to_string        to_ordinal        / ],
   standard2 => [ qw/ available_languages to_string        to_ordinal        / ],
   long      => [ qw/ available_languages number_to_string number_to_ordinal / ],
);

@EXPORT_TAGS{ qw/ std std2 / } = @EXPORT_TAGS{ qw/ standard standard2 / };

my %LMAP;
my $DEFAULT    = 'EN';
my $USE_LOCALE = 0;

_probe(); # fetch/examine/compile all available modules

sub import {
   my $class = shift;
   my @args  = @_;
   my @exports;

   foreach my $thing ( @args ) {
      if ( lc $thing eq '+locale' ) { $USE_LOCALE = 1; next; }
      if ( lc $thing eq '-locale' ) { $USE_LOCALE = 0; next; }
      push @exports, $thing;
   }

   $class->export_to_level( 1, $class, @exports );
}

sub to_string  { _to( string  => @_ ) }
sub to_ordinal { _to( ordinal => @_ ) }
sub available  { keys %LMAP           }

# -- PRIVATE -- #

sub _to {
   my $type   = shift || croak "No type specified";
   my $n      = shift;
   my $lang   = shift || _get_lang();
      $lang   = uc $lang;
      $lang   = _get_lang($lang) if $lang eq 'LOCALE';
   if ( ($lang eq 'LOCALE' || $USE_LOCALE) && ! exists $LMAP{ $lang } ) {
      _w("Locale language ($lang) is not available. "
        ."Falling back to default language ($DEFAULT)");
      $lang = $DEFAULT; # prevent die()ing from an absent driver
   }
   my $struct = $LMAP{ $lang } || croak "Language ($lang) is not available";
   return $struct->{ $type }->( $n );
}

sub _get_lang {
   my $lang;
   my $locale = shift;
   $lang = _get_lang_from_locale() if $locale || $USE_LOCALE;
   $lang = $DEFAULT if ! $lang;
   return uc $lang;
}

sub _get_lang_from_locale {
   require I18N::LangTags::Detect;
   my @user_wants = I18N::LangTags::Detect::detect();
   my $lang = $user_wants[0] || return;
   ($lang,undef) = split /\-/, $lang; # tr-tr
   return $lang;
}

sub _is_silent () { defined &SILENT && &SILENT }

sub _dummy_ordinal { $_[0] }
sub _dummy_string  { $_[0] }
sub _dummy_oo      {
   my $class = shift;
   my $type  = shift;
   return $type && ! $class->can('parse')
         ? sub { $class->new->$type( shift ) }
         : sub { $class->new->parse( shift ) }
         ;
}

sub _probe {
   my @compile;
   foreach my $module ( _probe_inc() ) {
      my $class = $module->[LCLASS];
      # PL driver is problematic under 5.5.4
      if ( PREHISTORIC && $class->isa('Lingua::PL::Numbers') ) {
         _w("Disabling $class under legacy perl ($])") && next;
      }
      eval {
         require File::Spec->catfile( split m{::}xms, $class ) . '.pm';
         $class->import;
      };
      _probe_error($@, $class) && next if $@; # some modules need attention
      push @compile, $module;
   }
   _compile( \@compile );
   return 1;
}

sub _probe_error {
   my($e, $class) = @_;
   return  $e =~ RE_LEGACY_PERL ? _w(_eprobe( $class, $1, $2 )) # JA -> 5.6.2
         : $e =~ RE_LEGACY_VSTR ? _w(_eprobe( $class, $2, $] )) # HU -> 5.005_04
         : $e =~ RE_UTF8_FILE   ? _w(_eprobe( $class, $]     )) # JA -> 5.005_04
         : croak("An error occurred while including sub modules: $e")
         ;
}

# XXX Test Lingua::FR::Nums2Words
# Maybe add a mechanish to select "Numbers" if there are many for the $ID

# XXX Support Lingua::PT::Nums2Ords

sub _probe_inc {
   local *DIRH;
   my @classes;
   foreach my $inc ( @INC ) {
      my $path = File::Spec->catfile( $inc, 'Lingua' );
      next if ! -d $path;
      opendir DIRH, $path or die "opendir($path): $!";
      while ( my $dir = readdir DIRH ) {
         next if $dir =~ m{ \A \. }xms || $dir eq 'Any' || $dir eq 'Slavic';
         my($file, $type) = _probe_exists($path, $dir);
         next if ! $file; # bogus
         push @classes, [ join('::', 'Lingua', $dir, $type), $file, $dir ];
      }
      closedir DIRH;
   }
   return @classes;
}

sub _probe_exists {
   my($path, $dir) = @_;
   foreach my $possibility ( qw[ Numbers Num2Word Nums2Words Numeros ] ) {
      my $file = File::Spec->catfile( $path, $dir, $possibility . '.pm' );
      next if ! -e $file || -d _;
      return $file, $possibility;
   }
   return;
}

sub _w {
   _is_silent() ? 1 : do { warn "@_\n"; 1 };
}

sub _eprobe {
   my $tmp = @_ == 3 ? "%s requires a newer (%s) perl binary. You have %s"
           :           "%s requires a newer perl binary. You have %s"
           ;
   return sprintf $tmp, @_
}

# IT::Numbers OO içinde ordinal sağlıyor

sub _compile {
   my $classes = shift;
   foreach my $e ( @{ $classes } ) {
      my $l = lc $e->[LID];
      my $c = $e->[LCLASS];
      $LMAP{ uc $e->[LID] } = {
         string  => _test_cardinal($c, $l),
         ordinal => _test_ordinal( $c, $l),
      };
   }
   #use Data::Dumper;my $d = Data::Dumper->new([\%LMAP]);$d->Deparse(1);warn "DD:". $d->Dump;
   return;
}

sub _test_cardinal {
   no strict qw(refs);
   my($c, $l) = @_;
   my %s = %{ "${c}::" };
   my $n = $s{new};
   return
        $s{"num2${l}"}         ? \&{"${c}::num2${l}"          }
      : $s{"number_to_${l}"}   ? \&{"${c}::number_to_${l}"    }
      : $s{"nums2words"}       ? \&{"${c}::nums2words"        }
      : $s{"num2word"}         ? \&{"${c}::num2word"          }
      : $s{cardinal2alpha}     ? \&{"${c}::cardinal2alpha"    }
      : $s{cardinal}&&$n       ? _dummy_oo( $c, 'cardinal' )
      : $s{parse}              ? _dummy_oo( $c )
      : $s{"num2${l}_cardinal"}? $n ? _dummy_oo($c, "num2${l}_cardinal")
                                    : \&{"${c}::num2${l}_cardinal" }
      :                          \&_dummy_string
      ;
}

sub _test_ordinal {
   no strict qw(refs);
   my($c, $l) = @_;
   my %s = %{ "${c}::" };
   my $n = $s{new};
   return
        $s{"ordinate_to_${l}"}         ? \&{"${c}::ordinate_to_${l}"}
      : $s{ordinal2alpha}              ? \&{"${c}::ordinal2alpha"   }
      : $s{ordinal}&&$n&&!_like_en($c) ? _dummy_oo( $c, 'ordinal')
      : $s{"num2${l}_ordinal"}         ? ($n && ! _like_en($c))
                                          ? _dummy_oo( $c, "num2${l}_ordinal" )
                                          : \&{"${c}::num2${l}_ordinal"}
      :                                \&_dummy_ordinal
      ;
}

sub _like_en {
   my $c  = shift;
   my $rv = $c->isa('Lingua::EN::Numbers')
            || $c->isa('Lingua::JA::Numbers')
            || $c->isa('Lingua::TR::Numbers')
            ;
   return $rv;
}

1;

__END__

=pod

=head1 NAME

Lingua::Any::Numbers - Converts numbers into (any available language) string.

=head1 SYNOPSIS

   use Lingua::Any::Numbers qw(:std);
   printf "Available languages are: %s\n", join( ", ", available );
   printf "%s\n", to_string(  45 );
   printf "%s\n", to_ordinal( 45 );

or test all available languages

   use Lingua::Any::Numbers qw(:std);
   foreach my $lang ( available ) {
      printf "%s\n", to_string(  45, $lang );
      printf "%s\n", to_ordinal( 45, $lang );
   }

=head1 DESCRIPTION

The most popular C<Lingua> modules are seem to be the ones that convert
numbers into words. These kind of modules exist for a lot of languages.
However, there is no standard interface defined for them. Most
of the modules' interfaces are completely different and some do not implement
the ordinal conversion at all. C<Lingua::Any::Numbers> tries to create a common
interface to call these different modules. And if a module has a known
interface, but does not implement the required function/method then the
number itself is returned instead of dying. It is also possible to
take advantage of the automatic locale detection if you install all the
supported modules listed in the L</SEE ALSO> section.

L<Task::Lingua::Any::Numbers> can be installed to get all the available modules
related to L<Lingua::Any::Numbers> on CPAN.

=head1 IMPORT PARAMETERS

All functions and aliases can be imported individually, 
but there are some pre-defined import tags:

   :all        Import everything (including aliases)
   :standard   available(), to_string(), to_ordinal().
   :std        Alias to :standard
   :standard2  available_languages(), to_string(), to_ordinal()
   :std2       Alias to :standard2
   :long       available_languages(), number_to_string(), number_to_ordinal()

=head1 IMPORT PRAGMAS

Some parameters enable/disable module features. C<+> is prefixed to enable
these options. Pragmas have global effect (i.e.: not lexical), they can not
be disabled afterwards.

=head2 locale

Use the language from system locale:

   use Lingua::Any::Numbers qw(:std +locale);
   print to_string(81); # will use locale

However, the second parameter to the functions take precedence. If the language
parameter is used, C<locale> pragma will be discarded.

Install all the C<Lingua::*::Numbers> modules to take advantage of the
locale pragma.

It is also possible to enable C<locale> usage through the functions.
See L</FUNCTIONS>.

C<locale> is implemented with L<I18N::LangTags::Detect>.

=head1 FUNCTIONS

All language parameters (C<LANG>) have a default value: C<EN>. If it is set to
C<LOCALE>, then the language from the system C<locale> will be used
(if available).

=head2 to_string NUMBER [, LANG ]

Aliases:

=over 4

=item num2str

=item number_to_string

=back

=head2 to_ordinal NUMBER [, LANG ]

Aliases: 

=over 4

=item num2ord

=item number_to_ordinal

=back

=head2 available

Returns a list of available language ids.

Aliases:

=over 4

=item available_langs

=item available_languages

=back

=head1 DEBUGGING

=head2 SILENT

If you define a sub named C<Lingua::Any::Numbers::SILENT> and return
a true value from that, then the module will not generate any warnings
when it faces some recoverable errors.

C<Lingua::Any::Numbers::SILENT> is not defined by default.

=head1 CAVEATS

=over 4

=item *

Some modules return C<UTF8>, while others return arbitrary encodings.
C<ascii> is ok, but others will be problematic. A future release can 
convert all to C<UTF8>.

=item *

All available modules will immediately be searched and loaded into
memory (before using any function).

=item *

No language module (except C<Lingua::EN::Numbers>) is required by 
L<Lingua::Any::Numbers>, so you'll need to install the other 
modules manually.

=back

=head1 SEE ALSO

   Lingua::AF::Numbers
   Lingua::BG::Numbers
   Lingua::EN::Numbers
   Lingua::EU::Numbers
   Lingua::FR::Numbers
   Lingua::HU::Numbers
   Lingua::IT::Numbers
   Lingua::JA::Numbers
   Lingua::NL::Numbers
   Lingua::PL::Numbers
   Lingua::TR::Numbers
   Lingua::ZH::Numbers
   
   Lingua::CS::Num2Word
   Lingua::DE::Num2Word
   Lingua::ES::Numeros
   Lingua::ID::Nums2Words
   Lingua::NO::Num2Word
   Lingua::PT::Nums2Word
   Lingua::SV::Num2Word

You can just install L<Task::Lingua::Any::Numbers> to get all modules above.

=head2 BOGUS MODULES

Some modules on CPAN suggest to convert numbers into words by their
names, but they do something different instead. Here is a list of
the bogus modules:

   Lingua::FA::Number

=head1 SUPPORT

=head2 BUG REPORTS

All bug reports and wishlist items B<must> be reported via
the CPAN RT system. It is accessible at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-Any-Numbers>.

=head2 DISCUSSION FORUM

C<CPAN::Forum> is a place for discussing C<CPAN>
modules. It also has a C<Lingua::Any::Numbers> section at
L<http://www.cpanforum.com/dist/Lingua-Any-Numbers>.

=head2 RATINGS

If you like or hate or have some suggestions about
C<Lingua::Any::Numbers>, you can comment/rate the distribution via 
the C<CPAN Ratings> system: 
L<http://cpanratings.perl.org/dist/Lingua-Any-Numbers>.

=head1 AUTHOR

Burak Gürsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2007-2009 Burak Gürsoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.10.0 or, 
at your option, any later version of Perl 5 you may have available.

=cut
