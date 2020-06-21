#!/usr/bin/perl

use strict;
use warnings;

use DateTime::Format::Natural;
use DateTime::Format::Natural::Test ':set';
use Test::More;

my @aliases = (
    { '1 sec ago'          => '24.11.2006 01:13:07' },
    { '10 secs ago'        => '24.11.2006 01:12:58' },
    { '1 min ago'          => '24.11.2006 01:12:08' },
    { '5 mins ago'         => '24.11.2006 01:08:08' },
    { '1 hr ago'           => '24.11.2006 00:13:08' },
    { '3 hrs ago'          => '23.11.2006 22:13:08' },
    { '1 yr ago'           => '24.11.2005 01:13:08' },
    { '7 yrs ago'          => '24.11.1999 01:13:08' },
    { 'yesterday @ noon'   => '23.11.2006 12:00:00' },
    { 'tues this week'     => '21.11.2006 00:00:00' },
    { 'final thurs in sep' => '28.09.2006 00:00:00' },
    { 'tues'               => '21.11.2006 00:00:00' },
    { 'thurs'              => '23.11.2006 00:00:00' },
    { 'thur'               => '23.11.2006 00:00:00' },
);

_run_tests(14, [ [ \@aliases ] ], \&compare);

sub compare
{
    my $aref = shift;

    foreach my $href (@$aref) {
        my $key = (keys %$href)[0];
        foreach my $string ($case_strings->($key)) {
            compare_strings($string, $href->{$key});
        }
    }
}

sub compare_strings
{
    my ($string, $result) = @_;

    my $parser = DateTime::Format::Natural->new;
    $parser->_set_datetime(\%time);

    my $dt = $parser->parse_datetime($string);

    if ($parser->success) {
        is(_result_string($dt), $result, _message($string));
    }
    else {
        fail(_message($string));
    }
}
