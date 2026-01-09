#!/usr/bin/perl

use strict;
use warnings;

use DateTime::Format::Natural;
use DateTime::Format::Natural::Test qw(_result_string);
use Test::More tests => 44;

my @iso8601 = (
    { '2016T12'                   => { result => '01.01.2016 12:00:00', tz => 'floating' } },
    { '2016T12:12'                => { result => '01.01.2016 12:12:00', tz => 'floating' } },
    { '2016T12:12:11'             => { result => '01.01.2016 12:12:11', tz => 'floating' } },
    { '2016-06T12'                => { result => '01.06.2016 12:00:00', tz => 'floating' } },
    { '2016-06T12:12'             => { result => '01.06.2016 12:12:00', tz => 'floating' } },
    { '2016-06T12:12:11'          => { result => '01.06.2016 12:12:11', tz => 'floating' } },
    { '2016-06-19T12'             => { result => '19.06.2016 12:00:00', tz => 'floating' } },
    { '2016-06-19T12:12'          => { result => '19.06.2016 12:12:00', tz => 'floating' } },
    { '2016-06-19T12:12:11'       => { result => '19.06.2016 12:12:11', tz => 'floating' } },
    { '2016-06-19T12:12:11-0500'  => { result => '19.06.2016 12:12:11', tz => '-0500' } },
    { '2016-06-19T12:12:11+0500'  => { result => '19.06.2016 12:12:11', tz => '+0500' } },
    { '2016-06-19T12:12:11-05:00' => { result => '19.06.2016 12:12:11', tz => '-0500' } },
    { '2016-06-19T12:12:11+05:00' => { result => '19.06.2016 12:12:11', tz => '+0500' } },
    { '2016-06-19T12:12:11+05:30' => { result => '19.06.2016 12:12:11', tz => '+0530' } },
    { '2016-06-19T12:12:11-05:30' => { result => '19.06.2016 12:12:11', tz => '-0530' } },
    { '2016-06-19T12:12:11-05'    => { result => '19.06.2016 12:12:11', tz => '-0500' } },
    { '2016-06-19T12:12:11+05'    => { result => '19.06.2016 12:12:11', tz => '+0500' } },
    { '2016-06-19T12:12+05'       => { result => '19.06.2016 12:12:00', tz => '+0500' } },
    { '2016-06-19T12:12+00'       => { result => '19.06.2016 12:12:00', tz => 'UTC' } },
    { '2016-06-19T12:12-00'       => { result => '19.06.2016 12:12:00', tz => 'UTC' } },
    { '2016-06-19T12:12:11Z'      => { result => '19.06.2016 12:12:11', tz => 'UTC' } },
    { '2016-06-19T12:12Z'         => { result => '19.06.2016 12:12:00', tz => 'UTC' } },
);

compare(\@iso8601);

sub compare
{
    my $aref = shift;

    foreach my $href (@$aref) {
        my $key = (keys %$href)[0];
        compare_strings($key, $href->{$key}{result}, $href->{$key}{tz});
    }
}

sub compare_strings
{
    my ($string, $result, $expected_tz) = @_;

    my $parser = DateTime::Format::Natural->new;

    my $dt = $parser->parse_datetime($string);

    if ($parser->success && $parser->_get_truncated) {
        is(_result_string($dt), $result, $string);
        is($dt->time_zone->name, $expected_tz, "$string - timezone");
    }
    else {
        fail($string);
    }
}
