package DateTime::Format::Natural::Extract;

use strict;
use warnings;
use base qw(
    DateTime::Format::Natural::Duration::Checks
    DateTime::Format::Natural::Formatted
);
use boolean qw(true false);

our $VERSION = '0.09';

my $get_range = sub
{
    my ($aref, $index) = @_;
    return [ grep defined, @$aref[$index, $index + 1] ];
};

my $extract_duration = sub
{
    my ($skip, $indexes, $index) = @_;

    return false unless defined $indexes->[$index] && defined $indexes->[$index + 1];
    my ($left_index, $right_index) = ($indexes->[$index][1], $indexes->[$index + 1][0]);

    return ($skip->{$left_index} || $skip->{$right_index}) ? false : true;
};

sub _extract_expressions
{
    my $self = shift;
    my ($extract_string) = @_;

    $extract_string =~ s/^\s*[,;.]?//;
    $extract_string =~ s/[,;.]?\s*$//;

    while (my ($mark) = $extract_string =~ /([,;.])/cg) {
        my %patterns = (
            ',' => qr/(?!\d{4})/,
            ';' => qr/(?=\w)/,
            '.' => qr/(?=\w)/,
        );
        my $pattern = $patterns{$mark};
        $extract_string =~ s/\Q$mark\E \s+? $pattern/ [token] /x; # pretend punctuation marks are tokens
    }

    $self->_rewrite(\$extract_string);

    my @tokens = split /\s+/, $extract_string;
    my %entries = %{$self->{data}->__grammar('')};

    my (@expressions, %skip);

    my $timespan_sep = $self->{data}->__timespan('literal');

    if ($extract_string =~ /\s+ $timespan_sep \s+/ix) {
        my @strings = split /\s+ $timespan_sep \s+/ix, $extract_string;
        my $index = 0;
        my @indexes;
        for (my $i = 0; $i < @strings; $i++) {
            my @tokens = split /\s+/, $strings[$i];
            push @indexes, [ $index, $index + $#tokens ];
            $index += $#tokens + 2;
        }

        my $duration = $self->{data}->{duration};

        DURATION: {
            my $save_expression = false;
            my @chunks;
            for (my $i = 0; $i < @strings; $i++) {
                if ($extract_duration->(\%skip, \@indexes, $i)
                 && $self->first_to_last_extract($duration, $get_range->(\@strings, $i), $get_range->(\@indexes, $i), \@tokens, \@chunks)
                ) {
                    $save_expression = true;
                }
                elsif ($extract_duration->(\%skip, \@indexes, $i)
                 && $self->from_count_to_count_extract($duration, $get_range->(\@strings, $i), $get_range->(\@indexes, $i), \@tokens, \@chunks)
                ) {
                    $save_expression = true;
                }
                if ($save_expression) {
                    foreach my $chunk (@chunks) {
                        push @expressions, $chunk;
                        $skip{$_} = true foreach ($chunk->[0][0] .. $chunk->[0][1]);
                    }
                    redo DURATION;
                }
            }
        }
    }

    my (%expand, %lengths);
    foreach my $keyword (keys %entries) {
        $expand{$keyword}  = $self->_expand_for($keyword);
        $lengths{$keyword} = @{$entries{$keyword}->[0]};
    }

    my $seen_expression;
    do {
        $seen_expression = false;
        my $date_index;
        for (my $i = 0; $i < @tokens; $i++) {
            next if $skip{$i};
            if ($self->_check_for_date($tokens[$i], $i, \$date_index)) {
                last;
            }
        }
        GRAMMAR:
        foreach my $keyword (sort { $lengths{$b} <=> $lengths{$a} } grep { $lengths{$_} <= @tokens } keys %entries) {
            my @grammar = @{$entries{$keyword}};
            my $types_entry = shift @grammar;
            my @grammars = [ [ @grammar ], false ];
            if ($expand{$keyword} && @$types_entry + 1 <= @tokens) {
                @grammar = $self->_expand($keyword, $types_entry, \@grammar);
                unshift @grammars, [ [ @grammar ], true ];
            }
            foreach my $grammar (@grammars) {
                my $expanded = $grammar->[1];
                my $length = $lengths{$keyword};
                   $length++ if $expanded;
                foreach my $entry (@{$grammar->[0]}) {
                    my ($types, $expression) = $expanded ? @$entry : ($types_entry, $entry);
                    my $definition = $expression->[0];
                    my $matched = false;
                    my $pos = 0;
                    my @indexes;
                    my $date_index;
                    for (my $i = 0; $i < @tokens; $i++) {
                        next if $skip{$i};
                        last unless defined $types->[$pos];
                        if ($self->_check_for_date($tokens[$i], $i, \$date_index)) {
                            next;
                        }
                        if ($types->[$pos] eq 'SCALAR' && defined $definition->{$pos} && $tokens[$i] =~ /^$definition->{$pos}$/i
                         or $types->[$pos] eq 'REGEXP'                                && $tokens[$i] =~   $definition->{$pos}
                        && (@indexes ? ($i - $indexes[-1] == 1) : true)
                        ) {
                            $matched = true;
                            push @indexes, $i;
                            $pos++;
                        }
                        elsif ($matched) {
                            last;
                        }
                    }
                    if ($matched
                     && @indexes == $length
                     && (defined $date_index ? ($indexes[0] - $date_index == 1) : true)
                    ) {
                        my $expression = join ' ', (defined $date_index ? $tokens[$date_index] : (), @tokens[@indexes]);
                        my $start_index = defined $date_index ? $indexes[0] - 1 : $indexes[0];
                        push @expressions, [ [ $start_index, $indexes[-1] ], $expression ];
                        $skip{$_} = true foreach (defined $date_index ? $date_index : (), @indexes);
                        $seen_expression = true;
                        last GRAMMAR;
                    }
                }
            }
        }
        if (defined $date_index && !$seen_expression) {
            push @expressions, [ [ ($date_index) x 2 ], $tokens[$date_index] ];
            $skip{$date_index} = true;
            $seen_expression = true;
        }
    } while ($seen_expression);

    return $self->_finalize_expressions(\@expressions, \@tokens);
}

sub _finalize_expressions
{
    my $self = shift;
    my ($expressions, $tokens) = @_;

    my $timespan_sep = $self->{data}->__timespan('literal');
    my (@duration_indexes, @final_expressions);

    my $seen_duration = false;

    foreach my $expression (sort { $a->[0][0] <=> $b->[0][0] } @$expressions) {
        my $prev = $expression->[0][0] - 1;
        my $next = $expression->[0][1] + 1;

        if (!$seen_duration && defined $tokens->[$next] && $tokens->[$next] =~ /^$timespan_sep$/i) {
            if (@final_expressions && $tokens->[$prev] !~ /^$timespan_sep$/i) {
                @duration_indexes = ();
            }
            push @duration_indexes, ($expression->[0][0] .. $expression->[0][1]);
            $seen_duration = true;
        }
        elsif ($seen_duration) {
            if ($prev - $duration_indexes[-1] == 1) {
                push @duration_indexes, ($prev, $expression->[0][0] .. $expression->[0][1]);
                push @final_expressions, join ' ', @$tokens[@duration_indexes];
            }
            else {
                push @final_expressions, join ' ', @$tokens[@duration_indexes];
                push @final_expressions, $expression->[1];
            }
            @duration_indexes = ();
            $seen_duration = false;
        }
        else {
            push @final_expressions, $expression->[1];
        }
    }

    if (@duration_indexes) {
        push @final_expressions, join ' ', @$tokens[@duration_indexes];
    }

    my $exclude = sub { $_[0] =~ /^\d{1,2}$/ };

    return grep !$exclude->($_), @final_expressions;
}

sub _check_for_date
{
    my $self = shift;
    my ($token, $index, $date_index) = @_;

    my ($formatted) = $token =~ $self->{data}->__regexes('format');
    my %count = $self->_count_separators($formatted);
    if ($self->_check_formatted('ymd', \%count)) {
        $$date_index = $index;
        return true;
    }
    else {
        return false;
    }
}

1;
__END__

=head1 NAME

DateTime::Format::Natural::Extract - Extract parsable expressions from strings

=head1 SYNOPSIS

 Please see the DateTime::Format::Natural documentation.

=head1 DESCRIPTION

C<DateTime::Format::Natural::Extract> extracts expressions from strings to be
processed by the parse methods.

=head1 SEE ALSO

L<DateTime::Format::Natural>

=head1 AUTHOR

Steven Schubiger <schubiger@cpan.org>

=head1 LICENSE

This program is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut
