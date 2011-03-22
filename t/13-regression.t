#!/usr/bin/perl

use strict;
use warnings;

use Test::MockTime qw(set_fixed_time);
use DateTime::Format::Natural;
use Test::More tests => 2;

{
    local $@;
    eval {
        set_fixed_time('31.03.2009 04:32:22', '%d.%m.%Y %H:%M:%S');
        DateTime::Format::Natural->new->parse_datetime('april 3');
    };
    ok(!$@, 'units set at once');

    # rt #49326
    set_fixed_time('31.08.2009', '%d.%m.%Y');
    my $parser = DateTime::Format::Natural->new;
    $parser->parse_datetime('30/11/2009');
    ok($parser->success, '_check_date() sets at once');
}
