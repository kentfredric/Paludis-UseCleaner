use strict;
use warnings;

package Paludis::UseCleaner;

# ABSTRACT: Remove cruft from your use.conf

=head1 SYNOPSIS

This module handles the core behaviour of the Use Cleaner, to be consumed inside other applications.

For a "Just Use it" interface, you want L<paludis-usecleaner.pl> and L<Paludis::UseCleaner::App>

    my $cleaner = Paludis::UseCleaner->new(
        input     => somefd,
        output    => somefd,
        rejects   => somefd,
        debug     => fd_for_debugging
        dot_trace => fd_for_dot_traces,
      ( # Optional
        display_ui => $object_to_handle_debug_messages
        display_ui_class => $classname_to_construct_a_display_ui
        display_ui_generator => $coderef_to_generate_object_for_display_ui
      )
    );

    $cleaner->do_work();
=cut

use Moose;
use MooseX::Types::Moose qw( :all );
use MooseX::Types::Perl qw( :all );
use Cave::Wrapper;
use namespace::autoclean -also => qr/^__/;
use IO::Handle;
use Class::Load 0.06 qw( load_class );
use Moose::Util::TypeConstraints qw( class_type );
use MooseX::Has::Sugar;

=attr input

    $cleaner->input( \*STDIN );
    $cleaner->input( $read_fh );


=cut

has 'input' => ( isa => GlobRef, rw, required );

=attr output

    $cleaner->output( \*STDOUT );
    $cleaner->output( $write_fh );

=cut

has 'output' => ( isa => GlobRef, rw, required );

=attr rejects

    $cleaner->rejects( \*STDOUT );
    $cleaner->rejects( $write_fh );

=cut

has 'rejects' => ( isa => GlobRef, rw, required );

=attr debug

    $cleaner->debug( \*STDERR );
    $cleaner->debug( $write_fh );


=cut

has 'debug' => ( isa => GlobRef, rw, required );

=attr dot_trace

    $cleaner->dot_trace( \*STDERR );
    $cleaner->dot_trace( $write_fh );

=cut

has 'dot_trace' => ( isa => GlobRef, rw, required );

=attr display_ui

    $cleaner->display_ui( $object );

=cut

has 'display_ui' => ( isa => Object, rw, lazy_build );

=attr display_ui_class

    $cleaner->display_ui_class( 'Some::Class::Name' );

=cut

has 'display_ui_class' => ( isa => ModuleName, rw, lazy_build );

=attr display_ui_generator

    $cleaner->display_ui_generator( sub {
        my $self = shift;
        ....
        return $object;
    });

=cut

has 'display_ui_generator' => ( isa => CodeRef, rw, lazy_build );

=method do_work

    $cleaner->do_work();

Executes the various transformations and produces the cleaned output from the input.

=cut

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

    my @packages = $cave->print_ids( '-m', $spec );

    if ( not @packages ) {
      $self->display_ui->nomatch( $lineno, $line );
      $self->rejects->print($line);
      next;
    }

    $self->output->print($line);
  }
  return;
}

=p_method __tokenize

    my @line = __tokenize( $line );

B<STRIPPED>: This method is made invisible to outside code after compile.

=cut

sub __tokenize {
  my $line = shift;
  $line =~ s/#.*$//;
  return split /\s+/, $line;
}

=p_method __is_empty_line

    if( __is_empty_line(@line) ){ }

B<STRIPPED>: This method is made invisible to outside code after compile.

=cut

## no critic (RequireArgUnpacking)

sub __is_empty_line {
  return not @_;
}

=p_method __is_star_rule

    if( __is_star_rule(@line) ){ }

B<STRIPPED>: This method is made invisible to outside code after compile.

=cut

## no critic (RequireArgUnpacking)

sub __is_star_rule {
  return $_[0] =~ /\*/;
}

=p_method __tokenparse

    my ( $spec, $use, $extras ) = __tokenparse( @line );

B<STRIPPED>: This method is made invisible to outside code after compile.

=cut

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

=p_method __extract_flags

    my ( @flags ) = __extract_flags( \@tokens );


B<STRIPPED>: This method is made invisible to outside code after compile.

=cut

## no critic (ProhibitDoubleSigils)

sub __extract_flags {
  my $in = shift;
  my @out;
  while ( exists $in->[0] && $in->[0] !~ /^([A-Z_]+):$/ ) {
    push @out, shift @$in;
  }
  return @out;
}

=p_method __extract_label

    my ( $label ) = __extract_label( \@tokens );

B<STRIPPED>: This method is made invisible to outside code after compile.

=cut

## no critic (ProhibitDoubleSigils)
sub __extract_label {
  my $in = shift;
  return if not exists $in->[0];
  return if not $in->[0] =~ /^([A-Z_]+):$/;
  my $result = $1;
  shift @$in;
  return $result;
}

=p_method _build_display_ui_class

    my $class = $cleaner->_build_display_ui_class();

=cut

sub _build_display_ui_class {
  return 'Paludis::UseCleaner::ConsoleUI';
}

=p_method _build_display_ui_generator

    my $generator  $cleaner->_build_display_ui_generator();

=cut

sub _build_display_ui_generator {
  my $self = shift;
  return sub {
    load_class( $self->display_ui_class );
    return $self->display_ui_class->new(
      fd_debug     => $self->debug,
      fd_dot_trace => $self->dot_trace,
    );
  };
}

=p_method _build_display_ui

    my $object = $cleaner->_build_display_ui();

=cut

sub _build_display_ui {
  my $self = shift;
  return $self->display_ui_generator()->($self);
}

no Moose;
no Moose::Util::TypeConstraints;

__PACKAGE__->meta->make_immutable;

1;
