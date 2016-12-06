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

die "$0 [jgi.db] [chosen.ini] [tagged.lst]\n" if @ARGV <1;
my $dbfile = shift;
$dbfile = 'jgi.db' unless defined $dbfile;
my $inifile = shift;
$inifile = 'chosen.ini' unless defined $inifile;
my $outfile = shift;
$outfile = 'tagged.lst' unless defined $outfile;

my %attr = (
    RaiseError => 0,
    PrintError => 1,
    AutoCommit => 0
);
my $dbh = DBI->connect('dbi:SQLite:dbname='.$dbfile,'','',\%attr) or die $DBI::errstr;

our $myConfig = MYINI->new();
if ( -f $inifile ) {
	$myConfig->read($inifile);
} else {die "[x] Chosen INI not found ! [$inifile]\n";}

#ddx $myConfig;
my $sth = $dbh->prepare( "SELECT cid,Type FROM ColData WHERE colname = ?" );
my $sth2 = $dbh->prepare( "SELECT DISTINCT a.thevalue,b.thevalue,c.thevalue FROM RawData AS a INNER JOIN RawData AS b on a.eid = b.eid INNER JOIN RawData AS c on a.eid = c.eid WHERE a.colname = 'NCBI Taxon ID' and b.colname = ? and c.colname = 'Organism Name'" );

my (%Result);
for my $catalog (@{$myConfig->{']'}}) {
	print STDERR "> $catalog ...";
	$sth->execute($catalog);
	my $rv=$sth->fetchall_arrayref;
	my ($cid,$type) = @{$rv->[0]};
	die if scalar @$rv != 1;
	if ($type == 0) {
		$sth2->execute($catalog);
		while (my $rv2 = $sth2->fetchrow_arrayref) {
			#ddx $rv2;
			my ($taxid,$value,$name) = @$rv2;
			if (exists $myConfig->{$catalog}->{$value}) {
				if (exists $Result{$taxid}) {
					$Result{$taxid}->[0] += log($myConfig->{$catalog}->{$value} /10);
					#warn "$Result{$taxid}->[1]\t$name\n" if $Result{$taxid}->[1] ne $name;
				} else {
					$Result{$taxid} = [0,$name];
				}
			} else {
				print STDERR "x";
			}
		}
		#ddx \%Result;
	} else { warn "Not supported yet.\n" }
	print STDERR "\b\b\b\b.   \n";
}
$dbh->rollback;
$dbh->disconnect;

open O,'>',$outfile or die "Error opening $outfile: $!\n";
do {
	no warnings 'qw';
	print O join("\t",qw{#TaxID log2score Name}),"\n";
};
my $log2 = log(2);
for my $taxid (sort {$a <=> $b} keys %Result) {
	$Result{$taxid}->[0] /= $log2 * scalar(@{$myConfig->{']'}});
	print O join("\t",$taxid,@{$Result{$taxid}}),"\n";
}
close O;
