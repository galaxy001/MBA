#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dump qw(ddx);
use File::Fetch;
use Digest::MD5;
use File::Basename;
use File::Path qw(mkpath);

my $DEBUG = 0;
my $MaxGenomeCnt = 1000;

die "$0 [tagged.lst] [out.fa.gz]\n" if @ARGV <0;
my $infile = shift;
$infile = 'tagged.lst' unless defined $infile;
my $outfile = shift;
$outfile = 'ref.fa.gz' unless defined $outfile;

my %TaxScores;
open L,'<',$infile or die "Error opening $infile: $!\n";
while (<L>) {
	next if /^#/;
	my @t = split /\t/;
	$TaxScores{$t[0]} = $t[1];
}
close L;
#ddx \%TaxScores;

my $URLprefix = 'ftp://ftp.ncbi.nlm.nih.gov/genomes/genbank/';
my @Lists = qw(bacteria archaea fungi protozoa);	# bacteria archaea fungi protozoa
my $URLsuffix = '/assembly_summary.txt';

#$File::Fetch::USER_AGENT = '';
my $dbURLprefix = 'ftp://ftp.ncbi.nlm.nih.gov/genomes/';
mkdir './list';
my (%aDat,%ScoreLevels);

sub checkorfetch ($$$) {
	my ($file,$url,$verbose) = @_;
	if (-f $file) {
		if ($verbose) {
			warn "[$file] already exists, skip downloading.\n";
		}
		return 0;
	} else {
		my $dirname = dirname($file);
		my @created = mkpath($dirname, 0, 0755);
		$url = "${dbURLprefix}${file}" if $url eq '';
		my $ff = File::Fetch->new(uri => $url);
		print STDERR '…';
		my $fcache;
		my $where = $ff->fetch( to => $dirname ) or die "[x]Cannot download [$url]: $ff->error\n",$verbose?"Please manually download it to [$file].\n":'';
		print STDERR "\b";
		return 1;
	}
}

for my $group (@Lists) {
	my $Error = 0;
	my $URLfull = $URLprefix . $group . $URLsuffix;
	#print "[$URLfull]\n";
	my $Target = "./list/$group.txt";
	my $ret = checkorfetch($Target,$URLfull,1);
	if ($ret == 1) {
		rename './list/assembly_summary.txt',$Target;
	}
	open L,'<',$Target or die $!;
	while (<L>) {
		next if /^#/;
		my @d = split /\t/;
		next if $d[11] ne 'Complete Genome';
		#ddx \@d;
		$d[19] =~ s/^${dbURLprefix}//;
		#print join("\t",@d[5,6,7,19]),"\n";
		# 566037	566037	Saccharomycetaceae sp. 'Ashbya aceri'	ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/412/225/GCA_000412225.2_ASM41222v2
		$aDat{$d[6]} = [@d[7,19]] unless exists $aDat{$d[6]};
		$aDat{$d[5]} = [@d[7,19]];	# 看上去 taxid 更精确（？），假设出现两次也没关系。
	    #taxid: ncbi taxid of the taxon (internal if > 10000000)
	    #species_taxid: corresponding species taxid
	}
	close L;
}
my $RefaCount = scalar keys %aDat;
my $RefaScored = 0;

for my $tid (keys %TaxScores) {
	if (exists $aDat{$tid}) {
		++$ScoreLevels{$TaxScores{$tid}};
		++$RefaScored;
	}
}
my @ScoreL = sort {$b <=> $a} keys %ScoreLevels;
#ddx \%ScoreLevels;
#print "@ScoreL\n";
my ($tCnt,$minScore) = (0,$ScoreL[0]);
if ($ScoreLevels{$ScoreL[0]} > $MaxGenomeCnt) {
	die "[x]Top level species Count [$ScoreLevels{$ScoreL[0]}] > $MaxGenomeCnt, Please re-score.\n"
}
for my $score (@ScoreL) {
	$tCnt += $ScoreLevels{$score};
	if ($tCnt > $MaxGenomeCnt) {
		$tCnt -= $ScoreLevels{$score};
		last;
	}
	$minScore = $score;
}
warn "[!]Genomes Found:[$RefaCount], Scored[$RefaScored]. Log2(MinScore):[$minScore] for [$tCnt] species.\n\n";

unless (-d './all/') {
	mkdir 'all',0755;
}

my $cCnt = 0;
warn "[!]Checking Genome files:\n";
for my $taxid (sort keys %aDat) {
	next unless exists $TaxScores{$taxid};
	my ($name,$gpath) = @{$aDat{$taxid}};
	my $basename = basename($gpath);
#print "[$name,$gpath,$basename]\n";
	my $file = "$gpath/md5checksums.txt";
	#my $url = "${dbURLprefix}${file}";
	checkorfetch($file,'',0);
	open M,'<',"$gpath/md5checksums.txt" or die "Error opening '$gpath/md5checksums.txt': $!";
	my (%FileMD5,$fmd5,$mfile);
	while (<M>) {
		($fmd5,$mfile) = split /\s+/;
		#if ($file =~ /((${basename}_genomic.fna.gz)|(${basename}_cds_from_genomic.fna.gz)|(${basename}_feature_table.txt.gz))$/) {
		if ($mfile =~ /(${basename}_genomic.fna.gz)$/) {
			$FileMD5{$mfile} = $fmd5;
		}
	}
	close M;
#ddx \%FileMD5;
	my @FMkeys = sort keys %FileMD5;
	if (scalar @FMkeys > 0) {
		for my $fn (@FMkeys) {
			$fmd5 = $FileMD5{$fn};
			my $filename = "$gpath/$fn";
			checkorfetch($filename,'',0);
			++$cCnt;
			if ($DEBUG) {
				print STDERR "\n";
				open (my $fh, '<', $filename) or die "Can't open '$filename': $!";
				binmode($fh);
				my $md5 = Digest::MD5->new;
				$md5->addfile($fh);
				close($fh);
				my $Cmd5 = $md5->hexdigest;
				if ($fmd5 eq $Cmd5) {
					print "✅  $filename: $fmd5 💮\n";
				} else {
					print "❌  $filename: $Cmd5 ≠ $fmd5\n";
				}
			}
			print STDERR ":\t$cCnt / $tCnt\r";
		}
	}
}


# all -> /share/newdata/database/ftp.ncbi.nih.gov/genomes/all
#ddx \%pDat;
