package plugin;

use strict;
use warnings;
no warnings qw(redefine);

use FileHandle;
use POSIX qw(strftime);
use UNIVERSAL;
use Carp qw(carp croak);

# Keep private things private, because there's no
# good reason for people to meddle with them ;-)
my %_private;

sub new {
	my $class = shift;
	my $self = { @_ };

	# Barf if a plugin cannot "handle" an event
	croak unless UNIVERSAL::can($class,'handle');

	# Make private things private
	%_private = %{$self->{_private}};
	delete $self->{_private};

	DUMP($class,$self);
	return bless($self,$class);
}

sub whisper {
	my $self = shift;
	my $recipient = shift || '';
	my $message = join(' ',@_);

	return unless $recipient =~ /\S+/ && $message =~ /\S+/;
	my $send_str = sprintf(">%s %s", $recipient, $message);
	TRACE('   >>Sending>>   $send_str');
	$self->{heap}->{server}->put($send_str);
}

sub queue {
	my ($self,$method,@args) = @_;
	croak "Plugin ".ref($self)." attempted to queue an undefined method call '$method'"
		unless $self->can($method);

	$_private{kernel}->post($_private{session_id}, 'plugin_callback',
		$self, $method, \@args);
}

sub log {
	my $self = shift;
	my $fh = FileHandle->new(">>$self->{logfile}");
	if (defined $fh) {
		my $str = "@_"; chomp $str;
		printf($fh,"[%s] %s\n",strftime('%Y-%m-%d %H-%M-%S',localtime), $str);
		$fh->close;
	} else {
		warn "Unable to open logfile $self->{logfile} for writing: $!";
	}
}

sub TRACE {};
sub DUMP {};

1;

