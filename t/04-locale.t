#!/usr/bin/env perl -w
# CAVEAT EMPTOR: This file is UTF8 encoded (BOM-less)
# Burak Gürsoy <burak[at]cpan[dot]org>
use strict;
use utf8;
use Test::More qw( no_plan );
use Lingua::Any::Numbers qw( :std +locale );

ok( to_string(  45 ), "We got a string from global locale" );
ok( to_ordinal( 45 ), "We got an ordinal from global locale" );

ok( to_string(  45, 'locale' ), "We got a string from param locale" );
ok( to_ordinal( 45, 'locale' ), "We got an ordinal from param locale" );
