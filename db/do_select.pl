#!/usr/bin/env perl
use strict;
use warnings;
use DBI;
use Data::Dump qw(ddx);

die "$0 [jgi.db] [ret.lst]\n" if @ARGV <0;
my $dbfile = shift;
$dbfile = 'jgi.db' unless defined $dbfile;
my $outfile = shift;
$outfile = 'ret.lst' unless defined $outfile;

my %attr = (
    RaiseError => 0,
    PrintError => 1,
    AutoCommit => 0
);
my $dbh = DBI->connect('dbi:SQLite:dbname='.$dbfile,'','',\%attr) or die $DBI::errstr;
my $sth = $dbh->prepare( "SELECT cid,colname FROM ColData" );
$sth->execute();
my (%EID2TaxID);
while (my $rv=$sth->fetchrow_arrayref) {
	$EID2TaxID{$rv->[0]} = $rv->[1];
}
#ddx \%EID2TaxID;

warn "Please apply score [0~10] to each options below: [\033[1m5\033[0m for neutral]\n";
for my $k (sort {$a <=> $b} keys %EID2TaxID) {
	$sth = $dbh->prepare( "SELECT thevalue FROM ValueLists WHERE cid = ? ORDER BY thevalue ASC" );
	$sth->execute($k);
	my $rv=$sth->fetchall_arrayref;
	my $cnt = scalar @$rv;
	next if $cnt < 1;
	#ddx $rv;
	warn "\nCatalog $EID2TaxID{$k} ($cnt):\n";
	my $ri;
	for my $t (@$rv) {
		print STDERR "\t[$t->[0]]: ";
		chomp($ri = <STDIN>);
		$ri = 5 unless $ri =~ /^[\d.]+$/;
		$ri = int($ri+0.5);
		print "\033[1A\t[$t->[0]]: <\033[1m${ri}\033[0m>      \n";
	}
}


$dbh->rollback;
$dbh->disconnect;
