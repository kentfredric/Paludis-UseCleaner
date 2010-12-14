#!/usr/bin/env perl
use strict;
use warnings;


package # HIDE THIS.
    paludis_usecleaner;

#PODNAME: paludis-usecleaner.pl

#ABSTRACT: command line client for Paludis::UseCleaner

=head1 SYNOPSIS

    paludis-usecleaner.pl

For more extended usage, see L<Paludis::UseCleaner::App>

    paludis-usecleaner.pl -q

=cut

require Paludis::UseCleaner::App;

Paludis::UseCleaner::App::run();



