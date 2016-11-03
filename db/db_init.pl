#!/usr/bin/env perl
use strict;
use warnings;
use DBI;
use Data::Dump qw(ddx);

die "$0 <csv_file> [tag.db]\n" if @ARGV <1;
my $infile = shift;
my $dbfile = shift;
$dbfile = 'tag.db' unless defined $dbfile;

truncate $dbfile,0;

my $CidPropMin = 0.01;
my $Vid2ndPropMin = 0.01;
my $maxKinds = 50;

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
( cid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  colname TEXT NOT NULL,
  Type INTEGER NOT NULL DEFAULT(0),
  Cnt INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS ValueLists
( vid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  cid INTEGER NOT NULL,
  thevalue TEXT NOT NULL,
  vCnt INTEGER NOT NULL,
  FOREIGN KEY (cid) REFERENCES "ColData" (cid)
);
CREATE TABLE `MetaData` (
	eid INTEGER NOT NULL,
	NCBITaxonID	INTEGER,
	cid	INTEGER,
	vid	INTEGER
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

my ($TaxIDcnt,%EID2TaxID)=(0);

print STDERR "[!]Loading: ...";
my $in = openfile($infile);
while (<$in>) {
	chomp;
	s/\r$//;
	my @dat = split /,"/,$_;
	map {s/"|^\s+|\s+$//g} @dat;
	#print join('/',@dat),"\n";
	if (@dat == 3) {
		next if $dat[2] eq '';	# skip empay ones.
		if ( $dat[1] =~ /^Combined Samples \((\d+)\)$/) {
			$dat[2] = "$1\t$dat[2]";
			$dat[1] = "Combined Samples";
		} elsif ($dat[1] eq 'NCBI Taxon ID') {
			$EID2TaxID{$dat[0]} = $dat[2];
		}
		$sth->execute($dat[0],$dat[1],$dat[2]);
	} else {
		warn "[x]$_ => ",join('/',@dat),"\n";
	}
}
print STDERR "\b\b\bdone.\n[!]Building Index: ...";
$sql=q/
CREATE INDEX IF NOT EXISTS IDXeid ON "RawData" ("eid");
CREATE INDEX IF NOT EXISTS IDXcolname ON "RawData" ("colname");
/;
for (split /;/,$sql) {
	next if /^\s*$/;
	$dbh->do($_) or die $dbh->errstr;
}
$dbh->commit;
print STDERR "\b\b\bdone.\n";

my (%ColCount);
$sth = $dbh->prepare( "SELECT colname, COUNT(colname) as Cnt from RawData GROUP BY colname ORDER BY Cnt DESC;" );
my $sth2 = $dbh->prepare( "INSERT INTO ColData ( colname,Cnt ) VALUES ( ?,? )" );
my $sth3 = $dbh->prepare( "UPDATE ColData SET Type = ? WHERE colname = ?" );
$sth->execute();
while (my $rv=$sth->fetchrow_arrayref) {
	#ddx $rv;
	$ColCount{$rv->[0]} = [$rv->[1]];
	$sth2->execute($rv->[0],$rv->[1]);
	my $cid = $dbh->last_insert_id("","","","");
	$ColCount{$rv->[0]}->[1] = $cid;
}
for ('Cell Arrangement',) {
	$sth2->execute(1,$_);
}
for ('Temperature Range',) {
	$sth2->execute(2,$_);
}
$TaxIDcnt = $ColCount{'NCBI Taxon ID'}->[0] or die "[x]Cannot find 'NCBI Taxon ID'.\n";
#$sth = $dbh->prepare( "SELECT colname, COUNT(colname) as Cnt from RawData WHERE thevalue <> '' GROUP BY colname;" );
$sth2 = $dbh->prepare( "INSERT INTO ValueLists ( cid,thevalue,vCnt ) VALUES ( ?,?,? )" );
$sth = $dbh->prepare( "SELECT thevalue, COUNT(thevalue) as Cnt from RawData WHERE colname = ? GROUP BY thevalue ORDER BY Cnt DESC;" );
for my $k (keys %ColCount) {
	next if $k eq 'Combined Samples' or $k eq 'Comment' or $k eq 'Metabolism' or $k eq 'Seq Status' or $k eq 'Is Public' or $k eq 'High Quality' or $k =~ /^(GOLD|Submission|Longhurst|Host|IMG|ITS|Sequencing|Genome) /;
	if ($ColCount{$k}->[0] >= $TaxIDcnt * $CidPropMin) {
		$sth->execute($k);
		my $rv = $sth->fetchall_arrayref;
		#ddx $rv;
		next if scalar @$rv < 2 or scalar @$rv > $maxKinds;
		#next if ($rv->[1]->[1] < $TaxIDcnt*$Vid2ndPropMin);
		my ($strCnt,$strLen) = (0,0);
		for (@$rv) {
			my $str = $_->[0];
			if ($str =~ /[A-Za-z]{3}/) {
				++$strCnt;
				$strLen += length $str;
				print "--> $k: $str, $_->[1]\n";
			}
		}
		if ($strCnt<1 or ($strLen/$strCnt)>50) {
			print "### $strCnt -> $strLen ### $k\n";
			next;
		}
		print scalar @$rv,"<-- $rv->[1]->[1] $k\n";
		for (@$rv) {
			$sth2->execute($ColCount{$k}->[1],$_->[0],$_->[1]);
			print "$ColCount{$k}->[1],$_->[0],$_->[1] <<<\n"
		}
	}
}

$dbh->commit;
$dbh->disconnect;

#ddx \%EID2TaxID;
__END__
./db_init.pl jgi.all.info.fmt.csv.gz
