
use strict;
use warnings;

package Paludis::UseCleaner::App;

# ABSTRACT: Command Line App Interface to Paludis::UseCleaner

=head1 SYNOPSIS

This is really just a huge wrapper around L<Getopt::Lucid>
which sets up L<Paludis::UseCleaner> in a friendly way.

    @ARGV=qw( --command -l -i -n -e --arguments );
    use Paludis::UseCleaner::App;

    Paludis::UseCleaner::App->run();

=head1 COMMAND LINE ARGUMENTS

=head2 --output $file

Set the file to write the cleaned use.conf to.

Defaults as C</tmp/use.conf.out>.

Use C<-> for C<STDOUT>.

=head2 --rejects $file

Set the file to write the rejected lines to.

Defaults as C</tmp/use.conf.rej>.

Use C<-> for C<STDERR>

=head2 --conf

Sets the file to read use.conf from,

Defaults as C</etc/paludis/use.conf>

Use C<-> for C<STDIN>

=head2 --no-clobber-output

If C<--output> exists, die instead of overwriting it.

=head2 --no-clobber-rejects

If C<--rejects> exists, die instead of overwriting it.

=head2 --silent

Print nothing debug related to stderr.

=head2 --no-quiet

Print verbose messages to stderr instead of a dot-trace

=head2 --help

Show a brief command line summary.

=cut


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

  $flags{display_ui_generator} = sub {
        my $self = shift;
        require Class::Load;
        Class::Load->VERSION(0.06);
        Class::Load::load_class( $self->display_ui_class );
        return $self->display_ui_class->new(
            %display_args,
            fd_debug => $self->debug,
            fd_dot_trace => $self->dot_trace,
        );

  };
  require Class::Load;
  Class::Load->VERSION(0.06);
  Class::Load::load_class('Paludis::UseCleaner');
  my $cleaner = Paludis::UseCleaner->new( \%flags );

  return $cleaner->do_work();
}

1;
