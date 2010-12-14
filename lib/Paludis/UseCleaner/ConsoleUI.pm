use strict;
use warnings;

package Paludis::UseCleaner::ConsoleUI;

# ABSTRACT: SubSpace for handling progress formatting of the cleaner.

use Moose;
use MooseX::Types::Moose qw( :all );
use MooseX::Types::Perl qw( :all );
use MooseX::Has::Sugar;
use IO::Handle;
use Term::ANSIColor;

=attr show_skip_empty

    $ui->show_skip_empty( 1 ); # enable showing the empty-line debug
    $ui->show_skip_empty( 0 ); # disable ...

B<default> is C<true>

=cut

has show_skip_empty => ( isa => Bool, rw, default => 1 );

=attr show_skip_star

    $ui->show_skip_star( 1 ); # enable showing the * rule debug
    $ui->show_skip_star( 0 ); # disable ...

B<default> is C<true>

=cut

has show_skip_star  => ( isa => Bool, rw, default => 1 );

=attr show_dot_trace

    $ui->show_dot_trace( 1 ); # enable showing the dot_trace's
    $ui->show_dot_trace( 0 ); # disable ...

B<default> is C<false>

=cut

has show_dot_trace  => ( isa => Bool, rw, default => 0 );

=attr show_clean

    $ui->show_clean( 1 ); # enable showing the clean notice
    $ui->show_clean( 0 ); # disable ...

B<default> is C<true>

=cut

has show_clean      => ( isa => Bool, rw, default => 1 );

=attr show_rules

    $ui->show_rules( 1 ); # enable showing the rule debug
    $ui->show_rules( 0 ); # disable ...

B<default> is C<true>

=cut

has show_rules      => ( isa => Bool, rw, default => 1 );

=attr fd_debug

    $ui->fd_debug( \*STDOUT ); # debug to stdout
    $ui->fd_debug( $fh ); # debug to a filehandle

=cut

has fd_debug     => ( isa => GlobRef, rw, required );

=attr fd_dot_trace

    $ui->fd_dot_trace( \*STDOUT ); # debug to stdout
    $ui->fd_dot_trace( $fh ); # debug to a filehandle

=cut

has fd_dot_trace => ( isa => GlobRef, rw, required );

my $format = "%s%s\n >> %s\n >  %s%s\n";

=p_method _message

   ->_message( $colour, $label, $line , $reason )

=cut

sub _message {
  my ( $self, $colour, $label, $line, $reason ) = @_;
  $line =~ s/\n?$//;
  $self->fd_debug->printf( $format, color($colour), $label, $line, $reason, color('reset') );

}

=method skip_empty

    $ui->skip_empty( $lineno, $line )

Notifies user a line has been skipped in the input due to it being empty.
This line has been copied to the output ( cleaned ) file.

=cut

sub skip_empty {
  my ( $self, $lineno, $line ) = @_;
  $self->dot_trace('>');
  return unless $self->show_skip_empty;
  $self->_message( 'red', "Skipping $lineno", $line, "Looks empty" );
}

=method skip_star

    $ui->skip_star( $lineno, $line )

Notifies user a line has been skipped in the input due to it being a * rule,
and thus having far too many possible matches to compute respectably.

This line has been copied to the output ( cleaned ) file.

=cut

sub skip_star {
  my ( $self, $lineno, $line ) = @_;
  $self->dot_trace('>');
  return unless $self->show_skip_star;
  $self->_message( 'red', "Skipping $lineno", $line, "* rule" );
}

=method dot_trace

    $ui->dot_trace( $symbol = '.' )

Prints a simple progress indicator when show_dot_trace is enabled.

=cut

sub dot_trace {
  my ( $self, $symbol ) = @_;
  return unless $self->show_dot_trace;
  $symbol ||= '.';
  $self->fd_dot_trace->print($symbol);
}

=method nomatch

    $ui->nomatch( $lineno, $line )

Notifies use that a line appeared to contain a rule and that rule matched
no packages that exist, both uninstalled and installed, and is thus being removed from the output( cleaned ) file.

Just In case, this line is also copied to the rejects file.

=cut

sub nomatch {
  my ( $self, $lineno, $line ) = @_;
  $self->dot_trace('?');
  return unless $self->show_clean;
  $self->_message( 'green', "Cleaning $lineno", $line, 'No matching specification' );
}

=method full_rule

    $extrasmap{VIDEO_CARDS} = \@cardlist;

    $ui->full_rule( $spec, \@useflags, \%extrasmap )

Prduces a debug tracing line showing the parsed result of the line as we perceive it internally.

=cut
sub full_rule {
  my ( $self, $spec, $use, $extras ) = @_;
  return unless $self->show_rules;
  $extras->{'use'} = $use;
  my @extradata = map { sprintf "%s = [ %s ]", $_, join( ', ', @{ $extras->{$_} } ) } keys %$extras;
  $self->fd_debug->printf( "RULE: spec = $spec %s\n", join( ' ', @extradata ) );

}

1;
