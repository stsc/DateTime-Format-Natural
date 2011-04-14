#!/usr/bin/perl

use strict;
use warnings;
use boolean qw(true false);

use DateTime::Format::Natural;
use Test::More tests => 6;

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

{
    my ($parser, $warnings);

    local $SIG{__WARN__} = sub { $warnings = true };

    # Assert that a malformed formatted date with mixed separators previously
    # wrongly recognized as "m/d" format is rejected without warnings emitted.

    $warnings = false;
    $parser = DateTime::Format::Natural->new;
    $parser->parse_datetime('2011/04-12');
    ok(!$parser->success && !$warnings, 'checking of formatted date string end');

    $warnings = false;
    $parser = DateTime::Format::Natural->new;
    $parser->parse_datetime('2011/04-12 15:00');
    ok(!$parser->success && !$warnings, 'checking of formatted date word boundary');

    # Assert that a formatted date with an invalid month name which
    # contains non-letters is rejected without warnings emitted.

    $warnings = false;
    $parser = DateTime::Format::Natural->new;
    $parser->parse_datetime('2011-j6n-04');
    ok(!$parser->success && !$warnings, 'formatted date with non-letter in month name');
}
