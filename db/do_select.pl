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
ddx \%EID2TaxID;

$dbh->rollback;
$dbh->disconnect;
