#!/usr/bin/perl -w
# (c) 2007 Burak Gursoy <burak[at]cpan[dot]org>
# This sample code needs several other modules
# and perl 5.008 at least.
BEGIN { $| = 1 }
use 5.008;
use strict;
use Data::Dumper;
use I18N::LangTags::List;
use Encode qw(:all);
use Encode::Guess;
use Lingua::Any::Numbers qw(:std);
use Text::Table;

binmode STDOUT, ':utf8';

our $VERSION = '0.20';

my   @GUESS = map { 'iso-8859-' . $_ } 1..11,13..16;
push @GUESS , qw(koi8-f koi8-r koi8-u );

my $tb = Text::Table->new( qw( LID LANG SEnc OEnc String Ordinal )   );
   $tb->load([             qw( --- ---- ---- ---- ------ ------- ) ] );

my($s,$o);
foreach my $l ( sort { $a cmp $b } available ) {
   $s = to_string( 45, $l);
   $o = to_ordinal(45, $l);
   $s = '<undefined>' if ! defined $s;
   $o = '<undefined>' if ! defined $o;
   $tb->load(
      [
         $l,
         I18N::LangTags::List::name($l),
         is_utf8($s) ? 'UTF8' : _guess($s),
         is_utf8($o) ? 'UTF8' : _guess($o),
         $s,
         $o,
      ]
   );
}

print $tb;

sub _guess {
   my $data = shift;
   my $enc  = guess_encoding($data, @GUESS);
   return '?' if not ref $enc;
   return $enc->name;
}

__END__
