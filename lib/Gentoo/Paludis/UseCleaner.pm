use strict;
use warnings;

package Gentoo::Paludis::UseCleaner;

use Moose;
use MooseX::Types::Moose qw( :all );
use MooseX::Types::Perl qw( :all );
use Cave::Wrapper;
use namespace::autoclean -also => qr/^__/;
use IO::Handle;
use Class::Load qw( load_class );
use Moose::Util::TypeConstraints qw( class_type );
use MooseX::Has::Sugar;

has 'input'            => ( isa => GlobRef,    rw, required );
has 'output'           => ( isa => GlobRef,    rw, required );
has 'rejects'          => ( isa => GlobRef,    rw, required );
has 'debug'            => ( isa => GlobRef,    rw, required );
has 'dot_trace'        => ( isa => GlobRef,    rw, required );
has 'display_ui'       => ( isa => Object,     rw, lazy_build );
has 'display_ui_class' => ( isa => ModuleName, rw, lazy_build );

sub do_work {

  my ($self) = shift;
  my $cave = Cave::Wrapper->new();

  $self->dot_trace->autoflush(1);

  while ( defined( my $line = $self->input->getline ) ) {

    my $lineno = $self->input->input_line_number;

    my (@tokens) = __tokenize($line);

    if ( __is_empty_line(@tokens) ) {
      $self->output->print($line);
      $self->display_ui->skip_empty( $lineno, $line );
      next;
    }
    if ( __is_star_rule(@tokens) ) {
      $self->output->print($line);
      $self->display_ui->skip_star( $lineno, $line );
      next;
    }
    $self->display_ui->dot_trace();

    my ( $spec, $use, $extras ) = __tokenparse(@tokens);

    $self->display_ui->full_rule( $spec, $use, $extras );

    my @packages = $cave->print_ids('-m',$spec);

    if ( not @packages ) {
      $self->display_ui->nomatch( $lineno, $line );
      $self->rejects->print($line);
      next;
    }

    $self->output->print($line);
  }
}

sub __tokenize {
  my $line = shift;
  $line =~ s/#.*$//;
  return split /\s+/, $line;
}

sub __is_empty_line {
  return not @_;
}

sub __is_star_rule {
  return $_[0] =~ /\*/;
}

sub _build_display_ui_class {
  return 'Gentoo::Paludis::UseCleaner::ConsoleUI';
}

sub _build_display_ui {
  my $self = shift;
  load_class( $self->display_ui_class );
  return $self->display_ui_class->new(
    fd_debug     => $self->debug,
    fd_dot_trace => $self->dot_trace,
  );
}

sub __tokenparse {
  my @tokens   = @_;
  my $spec     = shift @tokens;
  my @useflags = __extract_flags( \@tokens );
  my %extras;
  while ( defined( my $current = __extract_label( \@tokens ) ) ) {
    $extras{$current} = [ __extract_flags( \@tokens ) ];
  }
  return ( $spec, \@useflags, \%extras );
}

sub __extract_flags {
  my $in = shift;
  my @out;
  while ( exists $in->[0] && $in->[0] !~ /^([A-Z_]+):$/ ) {
    push @out, shift @$in;
  }
  return @out;
}

sub __extract_label {
  my $in = shift;
  return if not exists $in->[0];
  return if not $in->[0] =~ /^([A-Z_]+):$/;
  my $result = $1;
  shift @$in;
  return $result;
}

sub __get_matching_packages {
  my $spec = shift;
  my @out;
  open my $fh, '-|', 'cave', 'print-ids', '-m', $spec
    or die "Can't call cave print-ids, $@ $? $!";
  @out = <$fh>;
  chomp for @out;
  return @out;
}
1;
