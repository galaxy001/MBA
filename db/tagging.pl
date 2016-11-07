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

die "$0 [jgi.db] [chosen.ini] [tagged.lst]\n" if @ARGV <0;
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
my $sth2 = $dbh->prepare( "SELECT DISTINCT a.thevalue,b.thevalue FROM RawData AS a INNER JOIN RawData AS b on a.eid = b.eid WHERE a.colname = 'NCBI Taxon ID' and b.colname = ?" );

my %Result;
for my $catalog (@{$myConfig->{']'}}) {
	print $catalog,"\n";
	$sth->execute($catalog);
	my $rv=$sth->fetchall_arrayref;
	my ($cid,$type) = @{$rv->[0]};
	die if scalar @$rv != 1;
	if ($type == 0) {
		$sth2->execute($catalog);
		while (my $rv2 = $sth2->fetchrow_arrayref) {
			#ddx $rv2;
			my ($taxid,$value) = @$rv2;
			if (exists $myConfig->{$catalog}->{$value}) {
				$Result{$taxid} += $myConfig->{$catalog}->{$value} -5;
			} else {
				warn ".\n";
			}
			ddx \%Result;
		}
	} else { warn "Not supported yet.\n" }
}

$dbh->rollback;
$dbh->disconnect;
