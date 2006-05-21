package FactStore;

use strict;
use DBI;
use Carp;

use vars qw($VERSION);

$VERSION = '1.01' || sprintf('%d', q$Revision$ =~ /(\d+)/g);

sub new {
	my ($class, $filename) = @_;
	$class = ref $class || $class;
	die "Suspect sqi filename" unless $filename =~ /^[\.\/a-zA-Z0-9\_\-]+$/;
	my $dbh =
	  DBI->connect("dbi:SQLite:dbname=$filename", "", "",
		{RaiseError => 1, PrintWarn => 0, PrintError => 0});
	my $self = {dbh => $dbh};
	bless $self, $class;
	return $self;
}

sub dbh { return shift()->{dbh} }

sub init_wrap {
	my ($self, $method, @args) = @_;
	my @out;
	eval { @out = $self->$method(@args) };
	if ($@ =~ /no such table/) {

		# schtop, this database is not ready yet
		$self->init_db;
		@out = $self->$method(@args);
		return wantarray ? @out : $out[0];
	} elsif ($@) {

		# rethrow
		die "$@ (caught by init_wrap)";
	}
	return wantarray ? @out : $out[0];
}

sub store_fact {
	my $self = shift;
	$self->init_wrap("_store_fact", @_);
}

sub _store_fact {
	my ($self, $correction, $thing1, $verb, $thing2) = @_;
	my $thing1c = $self->canonicalise($thing1);
	my $thing2c = $self->canonicalise($thing2);
	if ($correction) {
		my $sth = $self->dbh->prepare('DELETE FROM facts WHERE thing1c = ?');
		$sth->execute($thing1c);
	}
	my $sth = $self->dbh->prepare(
		"INSERT OR REPLACE INTO facts
		(thing1c, thing2c, thing1, verb, thing2, lastsaid) VALUES (?,?,?,?,?,?)");
	$sth->execute($thing1c, $thing2c, $thing1, $verb, $thing2, time());
}

sub init_db {
	my $self = shift;
	$self->dbh->do(
		qq(
	    create table facts (
				factid integer PRIMARY KEY AUTOINCREMENT,
				thing1c varchar(150),
				thing2c varchar(150),
				thing1 varchar(150),
				verb varchar(10),
				thing2 varchat(150),
				lastsaid integer,
				unique (thing1c, thing2c)
				)));
}

sub iq {
	my $self = shift;
	return $self->init_wrap("_iq", @_);
}

sub _iq {
	my $self = shift;
	my ($count) = $self->dbh->selectrow_array("select count(*) from facts");
	return $count || 0;
}

sub random_query {
	my $self = shift;
	return $self->init_wrap("_random_query", @_);
}

sub _random_query {
	my ($self, $query) = @_;
	$query = $self->canonicalise($query);
	my $dbh = $self->dbh;
	my ($howmany) =
	  $dbh->selectall_arrayref(
		"select count(factid) from facts where thing1c = "
		  . $dbh->quote($query));
	$howmany = $howmany->[0]->[0];    # Hmm, there's probably a nicer way
	return if !$howmany;

	# Retrieval algorithm: we want to be somewhat random, but it's boring
	# if we keep saying the same thing, which will happen sometimes with
	# randomness. So we pick the least-recently-said 40% (.4) of the relevant
	# facts, and say one of them.
	my $window = int($howmany * .4 + .5);
	$window = 1 if !$window;
	my $retrieve =
	  $dbh->selectall_arrayref(
		    "select factid, thing1, verb, thing2 from facts where thing1c = "
		  . $dbh->quote($query)
		  . " order by lastsaid, thing1c, thing2c limit $window");
	return if !@$retrieve;
	my $which  = (@$retrieve > 1) ? int(rand(@$retrieve - 1) + .5) : 0;
	my $hwhich = $which + 1;
	my $picked = $retrieve->[$which];
	my $factid = shift @$picked;
	$dbh->do(
		"update facts set lastsaid = " . time . " where factid = " . $factid);
	return ((join " ", @$picked) . " ($hwhich of $howmany)");
}

sub canonicalise {
	my ($self, $word) = @_;
	confess "wtf?" if !defined $word;
	$word =~ s/[^a-zA-Z0-9]//g;
	return lc $word;
}

sub _parse_line_core {
	my ($self, $line) = @_;
	$line =~ s/\s+$//s;
	$line =~ s/^\s+//s;
	my @out;
	while ($line =~ /(no\s*,\s+)?(.+)\W+(
		is|are|comes|has|won'?t|usually|does(?:n'?t)
			)\W+(.+?)([\.\!\?] | $ )/igx
	  ) {
		push @out, [$1, $2, $3, $4];
	}
	return @out;
}

sub _parse_query {
	my ($self, $line) = @_;
	if ($line =~ /^(what\'s|what\s+is|what\s+are)\s+(.+?)\??$/i) { return $2 }
	elsif ($line =~ /^(.+)\?$/) { return $1 }
	return;
}

sub parse_line {
	my ($self, $line) = @_;
	chomp $line;
	my $found = 0;
	foreach my $factoid ($self->_parse_line_core($line)) {
		$self->store_fact(@$factoid);
		$found++;
	}
	return $found;
}

sub chat {
	my ($self, $they_said) = @_;
	my $i_say;
	if (my $q = $self->_parse_query($they_said)) {
		$i_say = $self->random_query($q);
	}
	$self->parse_line($they_said);
	return $i_say if defined $i_say;
	return;
}

1;

