package DateTime::Format::Natural::Extract;

use strict;
use warnings;
use base qw(DateTime::Format::Natural::Formatted);
use boolean qw(true false);

our $VERSION = '0.01';

sub _extract_expressions
{
    my $self = shift;
    my ($string) = @_;

    $string =~ s/(?=[,;.])/ /g; # pretend punctuation marks are tokens

    my @tokens = split /\s+/, $string;
    my %entries = %{$self->{data}->__grammar('')};

    my @expressions;

    my %lengths;
    foreach my $keyword (keys %entries) {
        $lengths{$keyword} = @{$entries{$keyword}->[0]};
    }
    my ($seen_expression, %skip);
    do {
        $seen_expression = false;
        my $date_index;
        for (my $i = 0; $i < @tokens; $i++) {
            next if $skip{$i};
            my ($formatted) = $tokens[$i] =~ $self->{data}->__regexes('format');
            my %count = $self->_count_separators($formatted);
            if ($self->_check_formatted('ymd', \%count)) {
                $date_index = $i;
                $skip{$i} = true;
                last;
            }
        }
        OUTER:
        foreach my $keyword (sort { $lengths{$b} <=> $lengths{$a} } keys %entries) {
            my @grammar = @{$entries{$keyword}};
            my $types = shift @grammar;
            my $pos = 0;
            my @indexes;
            for (my $i = 0; $i < @tokens; $i++) {
                next if $skip{$i};
                last unless defined $types->[$pos];
                foreach my $expression (@grammar) {
                    my $definition = $expression->[0];
                    if ($types->[$pos] eq 'SCALAR' && defined $definition->{$pos} && $tokens[$i] =~ /^$definition->{$pos}$/i
                     or $types->[$pos] eq 'REGEXP'                                && $tokens[$i] =~   $definition->{$pos}
                    && (@indexes ? ($i - $indexes[-1] == 1) : true)
                    ) {
                        push @indexes, $i;
                        $pos++;
                        last;
                    }
                }
                if (@indexes == $lengths{$keyword}
                && (defined $date_index ? ($indexes[0] - $date_index == 1) : true)
                ) {
                    my $expression = join ' ', (defined $date_index ? $tokens[$date_index] : (), @tokens[@indexes]);
                    my $start_index = defined $date_index ? $indexes[0] - 1 : $indexes[0];
                    push @expressions, [ [ $start_index, $indexes[-1] ], $expression ];
                    $skip{$_} = true foreach @indexes;
                    $seen_expression = true;
                    last OUTER;
                }
            }
        }
        if (defined $date_index && !$seen_expression) {
            push @expressions, [ [ ($date_index) x 2 ], $tokens[$date_index] ];
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
    my @final_expressions;

    my @duration_indexes;
    foreach my $expression (sort { $a->[0][0] <=> $b->[0][0] } @$expressions) {
        my $prev = $expression->[0][0] - 1;
        my $next = $expression->[0][1] + 1;

        if (defined $tokens->[$next] && $tokens->[$next] =~ /^$timespan_sep$/i) {
            if (@final_expressions   && $tokens->[$prev] !~ /^$timespan_sep$/i) {
                @duration_indexes = ();
            }
            push @duration_indexes, ($expression->[0][0] .. $expression->[0][1], $next);
        }
        elsif (defined $tokens->[$prev] && $tokens->[$prev] =~ /^$timespan_sep$/i) {
            push @duration_indexes, ($expression->[0][0] .. $expression->[0][1]);

            push @final_expressions, join ' ', @$tokens[@duration_indexes];
            @duration_indexes = ();
        }
        else {
            push @final_expressions, $expression->[1];
        }
    }

    return @final_expressions;
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
