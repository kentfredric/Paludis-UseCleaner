#!/usr/bin/env perl
use strict;
use warnings;

package # HIDE THIS.
    Paludis::UseCleaner::App::Stub;

## no critic( Modules::RequireVersionVar )
    #
#ABSTRACT: command line client for Paludis::UseCleaner

#PODNAME: paludis-usecleaner.pl


=head1 SYNOPSIS

    paludis-usecleaner.pl

For more extended usage, see L<Paludis::UseCleaner::App>

    paludis-usecleaner.pl -q

=cut

require Paludis::UseCleaner::App;

Paludis::UseCleaner::App::run();



