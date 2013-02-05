
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.4003",
    "Test::More" => "0.98"
  },
  "configure_requires" => {
    "Module::Build" => "0.4003"
  },
  "dist_abstract" => "Remove cruft from your use.conf",
  "dist_author" => [
    "Kent Fredric <kentnl\@cpan.org>"
  ],
  "dist_name" => "Paludis-UseCleaner",
  "dist_version" => "0.01000308",
  "license" => "perl",
  "module_name" => "Paludis::UseCleaner",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Cave::Wrapper" => 0,
    "Class::Load" => "0.06",
    "Getopt::Lucid" => 0,
    "IO::Handle" => 0,
    "Moose" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "MooseX::Has::Sugar" => 0,
    "MooseX::Types::Moose" => 0,
    "MooseX::Types::Perl" => 0,
    "Term::ANSIColor" => 0,
    "namespace::autoclean" => 0,
    "perl" => "5.006",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [
    "bin/paludis-usecleaner.pl"
  ]
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
