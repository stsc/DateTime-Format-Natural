#!/usr/bin/perl

use strict;
use warnings;

use DateTime::Format::Natural;
use Test::More tests => 3;

{
    # Assert for prefixed dates that an extracted unit which is
    # partially invalid is not being passed to a DateTime wrapper.
    local $@;
    eval {
        my $parser = DateTime::Format::Natural->new;
        $parser->parse_datetime('+1XXXday');
        $parser->parse_datetime('-1dayXXX');
    };
    ok(!$@, 'prefixed date');
}

{
    # Assert that parse_datetime_duration() shrinks the date strings
    # and fails.
    my $parser = DateTime::Format::Natural->new;
    my @dt = $parser->parse_datetime_duration('mon to fri to sun');
    ok(!$parser->success, 'duration with substrings exceeding limit failed');
    is(@dt, 2, 'count of objects returned for shrinked duration');
}
