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
}

1;

