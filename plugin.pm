package plugin;
use strict;
use FileHandle;

sub new {
	my $class = shift;
	return bless({@_},$class);
}

sub handle {
	my ($self,$event) = @_;
	$self->log(sprintf('%s was called but has handle() method', ref($self)));
}

sub log {
	my $self = shift;
	my $fh = FileHandle->new(">>$self->{logfile}");
	if (defined $fh) {
		my $str = "@_"; chomp $str;
		my ($sec,$min,$hour,$mday,$mon,$year) = localtime;
		printf $fh "[%04d-%02d-%02d %02d:%02d:%02d] %s\n",
				$year+1900, $mon+1, $mday,
				$hour, $min, $sec,
				$str;
		$fh->close;
	} else {
		warn "Unable to open logfile $self->{logfile} for writing: $!";
	}
}

1;

