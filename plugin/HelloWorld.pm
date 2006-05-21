package plugin::HelloWorld;
use base plugin;
use strict;

our $DESCRIPTION = 'Say hello when greeted in private';
our %CMDHELP = ();

sub handle {
	my ($self,$event) = @_;
	$self->queue('respond',$event) if
			$event->{msgtype} eq 'TELL' &&
			$event->{command} =~ /w+a+s+u+p+|yo|hi'?ya|h+i+|h+e+l+o+/i;
}

sub respond {
	my ($self,$event) = @_;

	my @responses = (
			"howdie",
			"hi",
			"wazzaaaaaaaaaaaaaap?",
			"*hugs*",
			"how's things?",
			"It's a $event->{person}!",
			"Hi $event->{person}",
			'wasup?',
			'hello',
			':)',
		);

	$self->whisper(
			$event->{list} ? $event->{list} : $event->{person},
			$responses[int(rand(@responses))],
		);
}

1;

