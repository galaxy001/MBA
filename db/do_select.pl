#!/usr/bin/env perl
use strict;
use warnings;

use FindBin qw($RealBin);
if ($FindBin::VERSION < 1.51) {
	warn "[!]Your Perl is too old, thus there can only be ONE `$0` file in your PATH. [FindBin Version: $FindBin::VERSION < 1.51]\n\n"
}
FindBin::again(); # or FindBin->again; # Require $VERSION = "1.44"; http://perl5.git.perl.org/perl.git/commitdiff/f509412828fa95d62b8d41774f816a14ba046cac
use lib "$RealBin/lib";
use MYINI;

use DBI;
use Data::Dump qw(ddx);

die "$0 [jgi.db] [chosen.ini]\n" if @ARGV <0;
my $dbfile = shift;
$dbfile = 'jgi.db' unless defined $dbfile;
my $outfile = shift;
$outfile = 'chosen.ini' unless defined $outfile;

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

warn "Please apply score [0~10] to each options below: ['\033[1m5\033[0m' for neutral, '\033[1mN\033[0m' for all unknown]\n";
our $myConfig = MYINI->new();
for my $k (sort {$a <=> $b} keys %EID2TaxID) {
	$sth = $dbh->prepare( "SELECT thevalue FROM ValueLists WHERE cid = ? ORDER BY thevalue ASC" );
	$sth->execute($k);
	my $rv=$sth->fetchall_arrayref;
	my $cnt = scalar @$rv;
	next if $cnt < 1;
	#ddx $rv;
	warn "\nCatalog $EID2TaxID{$k} ($cnt):\n";
	#$myConfig->{$EID2TaxID{$k}} = {};
	my ($flag,$ri)=(1);
	for my $t (@$rv) {
		print STDERR "\t[$t->[0]]: ";
		if ($flag) {
			chomp($ri = <STDIN>);
			if ($ri =~ /^[Nn]$/) {
				$ri = 5;
				$flag = 0;
			}
			$ri = 5 unless $ri =~ /^[\d.]+$/;
			$ri = 0 if $ri < 0;
			$ri = 10 if $ri > 10;
			$ri = int($ri+0.5);
			print "\033[1A\t[$t->[0]]: ";
		} else {
			$ri = 5;
		}
		print "<\033[1m${ri}\033[0m>      \n";
		$myConfig->{$EID2TaxID{$k}}->{$t->[0]} = $ri;
	}
}
$myConfig->write("$outfile");

$dbh->rollback;
$dbh->disconnect;
