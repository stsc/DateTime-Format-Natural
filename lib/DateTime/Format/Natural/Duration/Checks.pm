package DateTime::Format::Natural::Duration::Checks;

use strict;
use warnings;
use boolean qw(true false);

our $VERSION = '0.03';

sub for
{
    my ($duration, $date_strings, $present) = @_;

    if (@$date_strings == 1
      && $date_strings->[0] =~ $duration->{for}{regex}
    ) {
        $$present = $duration->{for}{present};
        return true;
    }
    else {
        return false;
    }
}

sub first_to_last
{
    my ($duration, $date_strings, $extract) = @_;

    my %regexes = %{$duration->{first_to_last}{regexes}};

    if (@$date_strings == 2
      && $date_strings->[0] =~ /^$regexes{first}$/
      && $date_strings->[1] =~ /^$regexes{last}$/
    ) {
        $$extract = $regexes{extract};
        return true;
    }
    else {
        return false;
    }
}

my $anchor_regex = sub { my ($regex) = @_; qr/(?:^|(?<=\s))$regex(?:(?=\s)|$)/ };

my $extract_chunk = sub
{
    my ($string, $base_index, $start_pos, $match) = @_;

    my $start_index = 0;

    if ($start_pos > 0
     && $string =~ /^(.{0,$start_pos})\s+/
    ) {
        my $substring = $1;
        $start_index++ while $substring =~ /\s+/g;
        $start_index++; # final space
    }
    my @tokens    = split /\s+/, $match;
    my $end_index = $start_index + $#tokens;

    my $expression = join ' ', @tokens;

    return [ [ $base_index + $start_index, $base_index + $end_index ], $expression ];
};

my $has_timespan_sep = sub
{
    my ($tokens, $chunks, $timespan_sep) = @_;

    my ($left_index, $right_index) = ($chunks->[0]->[0][1], $chunks->[1]->[0][0]);

    if ($tokens->[$left_index  + 1] =~ /^$timespan_sep$/i
     && $tokens->[$right_index - 1] =~ /^$timespan_sep$/i
     && $right_index - $left_index == 2
    ) {
        return true;
    }
    else {
        return false;
    }
};

sub _first_to_last_extract
{
    my ($self, $duration, $date_strings, $indexes, $tokens, $chunks) = @_;

    return false unless @$date_strings == 2;

    my %regexes = %{$duration->{first_to_last}{regexes}};

    foreach my $name (qw(first last)) {
        $regexes{$name} = $anchor_regex->($regexes{$name});
    }

    my $timespan_sep = $self->{data}->__timespan('literal');

    my @chunks;
    if ($date_strings->[0] =~ /(?=($regexes{first}))/g) {
        my $match = $1;
        push @chunks, $extract_chunk->($date_strings->[0], $indexes->[0][0], pos $date_strings->[0], $match);
    }
    if ($date_strings->[1] =~ /(?=($regexes{last}))/g) {
        my $match = $1;
        push @chunks, $extract_chunk->($date_strings->[1], $indexes->[1][0], pos $date_strings->[1], $match);
    }
    if (@chunks == 2 && $has_timespan_sep->($tokens, \@chunks, $timespan_sep)) {
        @$chunks = @chunks;
        return true;
    }
    else {
        return false;
    }
}

my $init_categories = sub
{
    my ($duration, $categories) = @_;

    my $data = $duration->{from_count_to_count};

    foreach my $ident (@{$data->{order}}) {
        my $category = $data->{categories}{$ident};
        push @{$categories->{$category}}, $ident;
    }
};
my $from_matches = sub
{
    my ($duration, $date_strings, $entry) = @_;

    my $data = $duration->{from_count_to_count};

    foreach my $ident (@{$data->{order}}) {
        my $regex = $anchor_regex->($data->{regexes}{$ident});
        if ($date_strings->[0] =~ $regex) {
            $$entry = $ident;
            return true;
        }
    }
    return false;
};
my $to_relative_category = sub
{
    my ($duration, $date_strings, $categories, $entry, $target) = @_;

    my $data = $duration->{from_count_to_count};

    my $category = $data->{categories}{$entry};
    foreach my $ident (@{$categories->{$category}}) {
        my $regex = $anchor_regex->($data->{regexes}{$ident});
        if ($date_strings->[1] =~ $regex) {
            $$target = $ident;
            return true;
        }
    }
    return false;
};

sub from_count_to_count
{
    my ($duration, $date_strings, $extract, $adjust) = @_;

    return false unless @$date_strings == 2;

    my %categories;
    $init_categories->($duration, \%categories);

    my ($entry, $target);
    unless ($from_matches->($duration, $date_strings, \$entry)
 && $to_relative_category->($duration, $date_strings, \%categories, $entry, \$target)
    ) {
        return false;
    }

    my $data = $duration->{from_count_to_count};

    my $regex = $data->{regexes}{$entry};

    if ($date_strings->[0] =~ /^.+? \s+ $regex$/x
     && $date_strings->[1] =~ /^$data->{regexes}{$target}$/
    ) {
        $$extract = qr/^(.+?) \s+ $regex$/x;
        $$adjust  = sub
        {
            my ($date_strings, $complete) = @_;
            $date_strings->[1] = "$complete $date_strings->[1]";
        };
        return true;
    }
    elsif ($date_strings->[0] =~ /^$regex \s+ .+$/x
        && $date_strings->[1] =~ /^$data->{regexes}{$target}$/
    ) {
        $$extract = qr/^$regex \s+ (.+)$/x;
        $$adjust  = sub
        {
            my ($date_strings, $complete) = @_;
            $date_strings->[1] .= " $complete";
        };
        return true;
    }
    else {
        return false;
    }
}

sub _from_count_to_count_extract
{
    my ($self, $duration, $date_strings, $indexes, $tokens, $chunks) = @_;

    return false unless @$date_strings == 2;

    my %categories;
    $init_categories->($duration, \%categories);

    my ($entry, $target);
    unless ($from_matches->($duration, $date_strings, \$entry)
 && $to_relative_category->($duration, $date_strings, \%categories, $entry, \$target)
    ) {
        return false;
    }

    my $data = $duration->{from_count_to_count};

    my $category = $data->{categories}{$entry};
    my $regex    = $data->{regexes}{$entry};

    my %regexes = (
        left   => qr/$data->{extract}{left}{$category}\s+$regex/,
        right  => qr/$regex\s+$data->{extract}{right}{$category}/,
        target => $data->{regexes}{$target},
    );

    foreach my $name (keys %regexes) {
        $regexes{$name} = $anchor_regex->($regexes{$name});
    }

    my $timespan_sep = $self->{data}->__timespan('literal');

    my @chunks;
    if ($date_strings->[0] =~ /(?=($regexes{left}))/g
     || $date_strings->[0] =~ /(?=($regexes{right}))/g
    ) {
        my $match = $1;
        push @chunks, $extract_chunk->($date_strings->[0], $indexes->[0][0], pos $date_strings->[0], $match);
    }
    if ($date_strings->[1] =~ /(?=($regexes{target}))/g) {
        my $match = $1;
        push @chunks, $extract_chunk->($date_strings->[1], $indexes->[1][0], pos $date_strings->[1], $match);
    }
    if (@chunks == 2 && $has_timespan_sep->($tokens, \@chunks, $timespan_sep)) {
        @$chunks = @chunks;
        return true;
    }
    else {
        return false;
    }
}

1;
