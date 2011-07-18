##
# name:      perl5
# abstract:  Use a Bunch of Modules in One Go
# author:    Ingy döt Net <ingy@ingy.net>
# license:   perl
# copyright: 2011
# see:
# - perl5i
# - perl5::i
# - perl5::ingy

use v5.10.0;
package perl5;
use strict;
use warnings;

use feature ();
use version 0.77 ();
use Hook::LexWrap 0.24;

our $VERSION = '0.06';

my $requested_perl_version = 0;

sub VERSION {
    my ($class, $version) = @_;
    $version = version->parse($version);
    if ($version <= 9.999999) {
        my $this_version = do {
            no strict 'refs';
            version->parse(${$class . '::VERSION'});
        };
        if ($version > $this_version) {
            require Carp;
            Carp::croak(
                "$class version $version required" .
                "--this is only version $this_version"
            );
        }
    }
    else {
        $requested_perl_version = $version;
    }
}

sub version_check {
    my ($class, $args) = @_;

    if (defined $args->[0]) {
        my $version = $args->[0];
        $version =~ s/^-//;
        if (version::is_lax($version)) {
            $requested_perl_version = version->parse($version);
            shift(@$args);
        }
    }
    if ($requested_perl_version) {
        my $version = $requested_perl_version->numify / 1000 + 5;
        $requested_perl_version = 0;
        eval "use $version";
        die $@ if $@;
    }
}

sub import {
    my $class = shift;
    my $package = caller;

    $class->version_check(\@_);
    my $arg = shift;

    if ($class ne 'perl5') {
        (my $usage = $class) =~ s/::/-/;
        die "Don't 'use $class'. Try 'use $usage'";
    }
    die "Two many arguments for 'use perl5...'"
        if @_;

    my $subclass =
        not(defined($arg)) ? __PACKAGE__ :
        $arg =~ /^-(\w+)$/ ?__PACKAGE__ . "::$1" :
        die "'$arg' is an invalid first argument to 'use perl5...'";
    eval "require $subclass; 1" or die $@;

    @_ = ($subclass);
    goto $class->can('importer');
}

sub important {}
sub importer {
    my $class = shift;
    my @imports = scalar(@_) ? @_ : $class->imports;
    my @wrappers;

    while (@imports) {
        my $name = shift(@imports);
        my $version = (@imports and version::is_lax($imports[0]))
            ? version->parse(shift(@imports))->numify : '';
        my $arguments = (@imports and ref($imports[0]) eq 'ARRAY')
            ? shift(@imports) : undef;
        push @wrappers, wrap important => post => sub {
            eval "use $name $version (); 1" or die $@;
            return if $arguments and not @$arguments;
            @_ = ($name, @{$arguments || []});
            goto $name->can('import');
        }
    }

    @_ = @wrappers;
    goto &important;
}

sub imports {
    return (
        'strict',
        'warnings',
        'feature' => [':5.10'],
    );
}

1;

=head1 SYNOPSIS

Use a version of Perl and its feature set:

    use perl5;      # Same as 'use perl5 v5.10.0;'
    use perl5 v14.1;
    use perl5 14.1;
    use perl5-14.1;

Use a bundled feature set from a C<perl5> plugin:

    use perl5-i;
    use perl5-2i;
    use perl5-ingy;
    use perl5-yourShinyPlugin;

Or both:

    use perl5 v14.1 -shiny;

=head1 DESCRIPTION

The C<perl5> module lets you C<use> a well known set of modules in one
command.

It allows people to create plugins like C<perl5::foo> and C<perl5::bar> that
are sets of useful modules that have been tested together and are known to
create joy.

This module, C<perl5>, is generally the base class to such a plugin.

=head1 USAGE

This:

    use perl5-foo;

Is equivalent in Perl to:

    use perl5 '-foo';

The C<perl5> module takes the first argument in the C<use> command, and uses
it to find a plugin, like C<perl5::foo> in this case.

C<perl5::foo> is typically just a subclass of L<perl5::base>. It invoke a set
of modules for its caller.

If you use C<perl5> with no arguments, like this:

    use perl5;

It is the same as saying:

    use 5.010;
    use strict;
    use warnings;

If you use it with a version, like this:

    use perl5 v14;

It is the same as saying:

    use v5.14;
    use strict;
    use warnings;
    use feature ':5.14';

=head1 API

To create a plugin called C<perl5::foo> that gets called like this:

    use perl5-foo;

Write some code like this:

    package perl5::foo;
    use base 'perl5';
    our $VERSION = 0.12;

    # These is the list of modules (with optional version and arguments)
    sub imports {
        return (
            strict =>
            warnings =>
            features => [':5.10'],
            SomeModule => 0.22,
            OtherModule => 0.33, [option1 => 2],
            Module => [],   # Don't invoke Module's import() method
        );
    }

    1;

=head1 INSPIRATION

This module was inspired by Michael Schwern's L<perl5i>, and the talk he gave
about it at the 2010 OSDC in Melbourne. By "inspired" I mean that I was
perturbed by Schwern's non-TMTOWTDI attitude towards choosing a standard set
of Perl modules for all of us.

    THIS IS PERL! THERE ARE NO STANDARDS!

...and I told him so. I also promised that I would show him my feelings in
code. Schwern, I<this> is how I feel! See also L<perl5::i>.

DISCLAIMER: Mr Schwern has my full love and respect, and knows it well. :)

=head1 THANKS

Special thanks to mst, audreyt and obra for ideas and support.
