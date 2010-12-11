use strict;
use warnings;

package Gentoo::Paludis::UseCleaner::ConsoleUI;

use Moose;
use MooseX::Types::Moose qw( :all );
use MooseX::Types::Perl qw( :all );
use MooseX::Has::Sugar;
use IO::Handle;
use Term::ANSIColor;

has show_skip_empty => ( isa => Bool, rw, default => 1 );
has show_skip_star  => ( isa => Bool, rw, default => 1 );
has show_dot_trace  => ( isa => Bool, rw, default => 0 );
has show_clean      => ( isa => Bool, rw, default => 1 );
has show_rules      => ( isa => Bool, rw, default => 1 );
has fd_debug     => ( isa => GlobRef, rw, required );
has fd_dot_trace => ( isa => GlobRef, rw, required );

my $format = "%s%s\n >> %s\n >  %s%s\n";

sub _message {
  my ( $self, $colour, $label, $line, $reason ) = @_;
  $line =~ s/\n?$//;
  $self->fd_debug->printf( $format, color($colour), $label, $line, $reason, color('reset') );

}

sub skip_empty {
  my ( $self, $lineno, $line ) = @_;
  $self->dot_trace('>');
  return unless $self->show_skip_empty;
  $self->_message( 'red', "Skipping $lineno", $line, "Looks empty" );
}

sub skip_star {
  my ( $self, $lineno, $line ) = @_;
  $self->dot_trace('>');
  return unless $self->show_skip_star;
  $self->_message( 'red', "Skipping $lineno", $line, "* rule" );
}

sub dot_trace {
  my ( $self, $symbol ) = @_;
  $symbol ||= '.';
  $self->fd_dot_trace->print($symbol);
}

sub nomatch {
  my ( $self, $lineno, $line ) = @_;
  $self->dot_trace('?');
  return unless $self->show_clean;
  $self->_message( 'green', "Cleaning $lineno", $line, 'No matching specification' );
}

sub full_rule {
  my ( $self, $spec, $use, $extras ) = @_;
  return unless $self->show_rules;
  $extras->{'use'} = $use;
  my @extradata = map { sprintf "%s = [ %s ]", $_, join( ', ', @{ $extras->{$_} } ) } keys %$extras;
  $self->debug->printf( "RULE: spec = $spec %s\n", join( ' ', @extradata ) );

}

1;
