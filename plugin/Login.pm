package plugin::Login;
use base plugin;
use strict;

our $DESCRIPTION = 'Login to talker';
our %CMDHELP = ();

sub handle {
	my ($self,$event) = @_;

	$self->say(sprintf('%s%s %s',
			($self->{heap}->{config}->{force_login} ? '*' : ''),
			$self->{heap}->{config}->{username},
			$self->{heap}->{config}->{password}
		)) if $event->{msgtype} eq 'HELLO' && !$self->{heap}->{logged_in};

	# Set the logged_in flag to true if we get a response that could only
	# ever happen if we're in a logged in state
	$self->{heap}->{logged_in} = 1 if $event->{msgtype} =~ /^DONE|COMMENT$/;
}

1;

