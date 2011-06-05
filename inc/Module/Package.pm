#line 1
##
# name:      Module::Package
# abstract:  Postmodern Perl Module Packaging
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011
# see:
# - Module::Package::Plugin
# - Module::Install::Package
# - Module::Package::Tutorial

package Module::Package;
use 5.005;
use strict;

BEGIN {
    $Module::Package::VERSION = '0.21';
    $inc::Module::Package::VERSION ||= $Module::Package::VERSION;
    @inc::Module::Package::ISA = __PACKAGE__;
}

sub import {
    my $class = shift;
    eval "use inc::Module::Install 1.01 (); 1" or $class->error($@);

    package main;
    inc::Module::Install->import();
    eval {
        module_package_internals_version_check($Module::Package::VERSION);
        module_package_internals_init(@_);
    };
    if ($@) {
        $Module::Package::ERROR = $@;
        die $@;
    }
}

sub error {
    my ($class, $error) = @_;
    if (-e 'inc' and not -e 'inc/.author') {
        require Data::Dumper;
        $Data::Dumper::Sortkeys = 1;
        my $dump1 = Data::Dumper::Dumper(\%INC);
        my $dump2 = Data::Dumper::Dumper(\@INC);
        die <<"...";
This should not have happened. Hopefully this dump will explain the problem:

Error: $error
%INC:
$dump1
\@INC:
$dump2
...
    }
    else {
        die $error;
    }
}

1;

