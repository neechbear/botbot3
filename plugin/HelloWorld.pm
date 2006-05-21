package plugin::HelloWorld;
use base plugin;
use strict;

our $DESCRIPTION = 'Say hello when greeted in private';
our %CMDHELP = ();

sub handle {
	my ($self,$event) = @_;

	return if $event->{alarm};
	return unless $event->{command} =~ /wassup|yo|hi'?ya|hi|hello/i;
	return unless $event->{msgtype} eq 'TELL';

	$self->queue('respond',$event);
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

	$self->{talker}->whisper(
			$event->{list} ? $event->{list} : $event->{person},
			$responses[int(rand(@responses))],
		);
}

1;

