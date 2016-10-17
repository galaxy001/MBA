#!/usr/bin/env perl
use strict;
use warnings;
use DBI;
use Data::Dump qw(ddx);

die "$0 <csv_file> [tag.db]\n" if @ARGV <1;
my $infile = shift;
my $dbfile = shift;
$dbfile = 'tag.db' unless defined $dbfile;

unlink $dbfile;

my %attr = (
    RaiseError => 0,
    PrintError => 1,
    AutoCommit => 0
);
my $dbh = DBI->connect('dbi:SQLite:dbname='.$dbfile,'','',\%attr) or die $DBI::errstr;

my $sql=q/
CREATE TABLE IF NOT EXISTS RawData
(  eid INTEGER NOT NULL,
   colname TEXT NOT NULL,
   thevalue TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS ColData
( cid INTEGER NOT NULL,
  colname TEXT NOT NULL,
  aCnt INTEGER NOT NULL,
  rCnt INTEGER NOT NULL DEFAULT(0)
);
CREATE TABLE IF NOT EXISTS ValueLists
( vid INTEGER NOT NULL,
  cid INTEGER NOT NULL,
  thevalue TEXT NOT NULL,
  cnt INTEGER NOT NULL
);
/;
for (split /;/,$sql) {
	next if /^\s*$/;
	#s/{---}/$opt_s/g;
	#print "[$_]\n";
	$dbh->do($_) or die $dbh->errstr;
}
$dbh->commit;

sub openfile($) {
    my ($filename)=@_;
    my $infile;
    if ($filename=~/.xz$/) {
	    open( $infile,"-|","xz -dc $filename") or die "Error opening $filename: $!\n";
    } elsif ($filename=~/.gz$/) {
     	open( $infile,"-|","gzip -dc $filename") or die "Error opening $filename: $!\n";
    } elsif ($filename=~/.bz2$/) {
     	open( $infile,"-|","bzip2 -dc $filename") or die "Error opening $filename: $!\n";
    } else {open( $infile,"<",$filename) or die "Error opening $filename: $!\n";}
    return $infile;
}

my $sth = $dbh->prepare( "INSERT INTO RawData ( eid,colname,thevalue ) VALUES ( ?,?,? )" );

my $in = openfile($infile);
while (<$in>) {
	chomp;
	s/\r$//;
	my @dat = split /,"/,$_;
	map {s/"|^\s+|\s+$//g} @dat;
	#print join('/',@dat),"\n";
	if (@dat == 3) {
		#print "$dat[0],$dat[1],$dat[2]\n";
		if ( $dat[1] ~= /^Combined Samples \((\d+)\)$/) {
			$dat[2] = "$1\t$dat[2]";
			$dat[1] = "Combined Samples";
		}
		$sth->execute($dat[0],$dat[1],$dat[2]);
	} else {
		warn "[x]$_ => ",join('/',@dat),"\n";
	}
}

$sth = $dbh->prepare( "SELECT colname, COUNT(colname) as Cnt from RawData GROUP BY colname;" );
my $sth2 = $dbh->prepare( "INSERT INTO ColData ( cid,colname,aCnt ) VALUES ( ?,?,? )" );


$sth = $dbh->prepare( "SELECT colname, COUNT(colname) as Cnt from RawData WHERE thevalue <> '' GROUP BY colname;" );
$sth2 = $dbh->prepare( "INSERT INTO ColData ( cid,colname,rCnt ) VALUES ( ?,?,? )" );

$dbh->commit;
$dbh->disconnect;

__END__
./db_init.pl jgi.all.info.fmt.csv.gz
