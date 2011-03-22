#!/usr/bin/perl

use strict;
use warnings;

use DateTime::Format::Natural;
use DateTime::Format::Natural::Test qw($case_strings);
use Test::More tests => 13 * 3; # case tests

my @strings = (
    { 'see you next tuesday for coffee',                    => [ 'next tuesday'                            ] },
    { "I'll meet you on 15th march at the cinema"           => [ '15th march'                              ] },
    { 'payment is due in 30 days'                           => [ 'in 30 days'                              ] },
    { 'johann sebastian bach was born 21/03/1685'           => [ '21/03/1685'                              ] },
    { '09/11/1989 18:57 was a historic moment'              => [ '09/11/1989 18:57'                        ] },
    { 'readings start at 20:00 and 22:00'                   => [ qw(20:00 22:00)                           ] },
    { 'conference will take place from wednesday to friday' => [ 'wednesday to friday'                     ] },
    { 'free days are friday, saturday and sunday'           => [ qw(friday saturday sunday)                ] },
    { 'system is stopped friday; started early monday'      => [ qw(friday monday)                         ] },
    { '02/03/2011 midnight and 02/03/2011 noon'             => [ '02/03/2011 midnight', '02/03/2011 noon'  ] },
    { '1969-07-20 and now'                                  => [ qw(1969-07-20 now)                        ] },
    { '6:00 compared to 6'                                  => [ '6:00'                                    ] }, # ambiguous token missing
    { 'yesterday to today and today to tomorrow'            => [ 'yesterday to today', 'today to tomorrow' ] },
);

compare(\@strings);

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
    my @expressions = $parser->extract_datetime($string);

    if (@expressions) {
        is_deeply([ map lc, @expressions ], $result, $string);
    }
    else {
        fail($string);
    }
}
