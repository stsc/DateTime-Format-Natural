package DateTime::Format::Natural::Aliases;

use strict;
use warnings;

our $VERSION = '0.03';

sub _rewrite_aliases
{
    my $self = shift;
    my ($date_string) = @_;

    my $aliases = $self->{data}->{aliases};

    if ($$date_string =~ /\s+/) {
        foreach my $type (qw(words tokens)) {
            foreach my $alias (keys %{$aliases->{$type}}) {
                if ($alias =~ /^\w+$/) {
                    $$date_string =~ s/\b $alias \b/$aliases->{$type}{$alias}/ix;
                }
                else {
                    $$date_string =~ s/(?:^|(?<=\s)) $alias (?:(?=\s)|$)/$aliases->{$type}{$alias}/ix;
                }
            }
        }
    }
    else {
        foreach my $alias (keys %{$aliases->{words}}) {
            $$date_string =~ s/^ $alias $/$aliases->{words}{$alias}/ix;
        }
        foreach my $alias (keys %{$aliases->{short}}) {
            $$date_string =~ s/(?<=\d) $alias $/$aliases->{short}{$alias}/ix;
        }
    }
}

1;
__END__

=head1 NAME

DateTime::Format::Natural::Aliases - Aliasing of date strings

=head1 SYNOPSIS

 Please see the DateTime::Format::Natural documentation.

=head1 DESCRIPTION

The C<DateTime::Format::Natural::Aliases> class handles aliases for date strings.

=head1 SEE ALSO

L<DateTime::Format::Natural>

=head1 AUTHOR

Steven Schubiger <schubiger@cpan.org>

=head1 LICENSE

This program is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut
