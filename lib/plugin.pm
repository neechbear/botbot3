package plugin;
use strict;
use FileHandle;
use POSIX qw(strftime);

sub new {
	my $class = shift;
	return bless({@_},$class);
}

sub handle {
	my ($self,$event) = @_;
	$self->log(sprintf('%s was called but has no handle() method', ref($self)));
}

sub process {}
sub respond {}

sub queue {
	my ($self,$method,@args) = @_;
}

sub call {
	my ($self,$method,@args) = @_;
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

1;

