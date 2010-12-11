
use strict;
use warnings;

package Gentoo::Paludis::UseCleaner::App;
use Getopt::Lucid qw( :all );

sub run {
  my @spec = (
    Param(
      "conf|c",
      sub {
        return 1 if $_ eq '-';
        return 1 if -e $_ && -f $_;
        return;
      }
      )->default("/etc/paludis/use.conf"),
    Param("output|o")->default("/tmp/use.conf.out"),
    Param("rejects|r")->default("/tmp/use.conf.rej"),
    Switch("clobber-output|x")->default(1),
    Switch("clobber-rejects|y")->default(1),
    Switch("quiet|q")->default(1),
    Switch("silent|s")->default(0),
    Switch("help|h")->anycase(),
  );
  my %doc = (
    'conf'           => {},
    'output'         => {},
    'rejects'        => {},
    'clobber-output' => {},
    'quiet'          => {},
    'silent'         => {},
    'help'           => {},
  );

  my $got = Getopt::Lucid->getopt( \@spec );
  if ( $got->get_help ) {

    for my $rule (@spec) {
        my $name = $rule->{canon};
        my $doc = $doc{$name};
        my @switches = split /\|/, $rule->{name};
        for ( @switches ){
            if ( length $_ < 2 ){
                $_ =~ s/^/-/;
            } else {
                $_ =~ s/^/--/;
            }
        }
        @switches = sort { length($a) <=> length( $b  ) } @switches;
        if( $rule->{type} eq 'parameter' ){
            @switches = map { ( "$_ \$x",   "$_=\$x" )   } @switches;
        } elsif( $rule->{type} eq 'switch') {
            @switches = map {
                my $i = $_;
                my $j = $i;
                $j =~ s/^--/--no-/;
                ( $j eq $i ) ? $i : ( $i , $j );
            } @switches;
        }
        printf "%-50s", join " ", @switches;
        print " ";
        print "=>";
        print ( defined $rule->{default} ? $rule->{default} : 'undef' );
        print " ";
        print "\n";

    }
    exit;

  }

  my %flags = ();

  if ( $got->get_conf eq '-' ) {
    $flags{input} = \*STDIN;
  }
  else {
    open my $fh, '<', $got->get_conf or die "Cant open " . $got->get_conf . " $@ $? $!\n";
    $flags{input} = $fh;
  }

  if ( $got->get_output eq '-' ) {
    $flags{output} = \*STDOUT;
  }
  else {
    if ( -e $got->get_output && !$got->get_clobber_output ) {
      die $got->output . " Exists and --no-clobber-output is specified\n";
    }
    open my $fh, '>', $got->get_output or die "Cant open " . $got->get_output . " $@ $? $!\n";
    $flags{output} = $fh;
  }

  if ( $got->get_rejects eq '-' ) {
    $flags{rejects} = \*STDERR;
  }
  else {
    if ( -e $got->get_rejects && !$got->get_clobber_rejects ) {
      die $got->get_rejects . " Exists and --no-clobber-rejects is specified\n";
    }
    open my $fh, '>', $got->get_rejects or die "Cant open " . $got->get_rejects . " $@ $? $!\n";
    $flags{rejects} = $fh;
  }

  $flags{debug}     = \*STDERR;
  $flags{dot_trace} = \*STDERR;

  my %display_args = ();
  $display_args{fd_debug}     = $flags{debug};
  $display_args{fd_dot_trace} = $flags{dot_trace};

  if ( $got->get_silent ) {
    $display_args{show_skip_empty} = 0;
    $display_args{show_skip_star}  = 0;
    $display_args{show_dot_trace}  = 0;
    $display_args{show_clean}      = 0;
    $display_args{show_rules}      = 0;
  }
  elsif ( $got->get_quiet ) {
    $display_args{show_skip_empty} = 0;
    $display_args{show_skip_star}  = 0;
    $display_args{show_dot_trace}  = 1;
    $display_args{show_clean}      = 0;
    $display_args{show_rules}      = 0;
  }
  else {
    $display_args{show_skip_empty} = 1;
    $display_args{show_skip_star}  = 1;
    $display_args{show_dot_trace}  = 0;
    $display_args{show_clean}      = 1;
    $display_args{show_rules}      = 1;
  }
  require Gentoo::Paludis::UseCleaner::ConsoleUI;

  $flags{display_ui} = Gentoo::Paludis::UseCleaner::ConsoleUI->new( \%display_args );

  require Gentoo::Paludis::UseCleaner;

  my $cleaner = Gentoo::Paludis::UseCleaner->new( \%flags );

  return $cleaner->do_work();
}

1;
