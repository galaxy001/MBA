#!/usr/bin/env perl
use strict;
use warnings;
use DBI;
use Data::Dump qw(ddx);

die "$0 <csv_file> [tag.db]\n" if @ARGV <1;
my $infile = shift;
my $dbfile = shift;
$dbfile = 'tag.db' unless defined $dbfile;

my %attr = (
    RaiseError => 0,
    PrintError => 1,
    AutoCommit => 0
);
my $dbh = DBI->connect('dbi:SQLite:dbname='.$dbfile,'','',\%attr) or die $DBI::errstr;

my $sql=q/
CREATE TABLE IF NOT EXISTS RawData
(  eid INTEGER,
   colname TEXT,
   thevalue TEXT
);
CREATE TABLE IF NOT EXISTS ColData
( cid INTEGER,
  colname TEXT,
  cnt INTEGER
);
CREATE TABLE IF NOT EXISTS ValueLists
( vid INTEGER,
  value TEXT,
  cid INTEGER,
  cnt INTEGER
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

my $in = openfile($infile);
while (<$in>) {
	chomp;
	s/\r$//;
	my @dat = split /,/,$_;
	map {s/"//g} @dat;
	#print join('|',@dat),"\n";
}


__END__
./db_init.pl jgi.all.info.fmt.csv.gz
