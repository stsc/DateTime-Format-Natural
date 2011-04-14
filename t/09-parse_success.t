#!/usr/bin/perl

use strict;
use warnings;

use DateTime::Format::Natural;
use Test::More tests => 12;

my @ordinal_number = (
    '2d aug',
    '3d aug',
    '11th sep',
    '12th sep',
    '13th sep',
    '21st oct',
    '22nd oct',
    '23rd oct',
);

my @durations = (
    '26 oct 10:00am to 11:00am',
    '26 oct 10:00pm to 11:00pm',
);

my @filtered = (
    'thurs,',
);

my @formatted = (
    '2011-Jan-04',
);

foreach my $list (\@ordinal_number, \@durations, \@filtered, \@formatted) {
    check($list);
}

sub check
{
    my $aref = shift;
    foreach my $string (@$aref) {
        check_success($string);
    }
}

sub check_success
{
    my ($string) = @_;

    my $parser = DateTime::Format::Natural->new;
    $parser->parse_datetime_duration($string);

    if ($parser->success) {
        pass($string);
    }
    else {
        fail($string);
    }
}
