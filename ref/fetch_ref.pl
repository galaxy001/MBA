#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dump qw(ddx);
use File::Fetch;
use Digest::MD5;
use File::Basename;
use File::Path qw(mkpath);

my $URLprefix = 'ftp://ftp.ncbi.nlm.nih.gov/genomes/genbank/';
my @Lists = qw(bacteria archaea fungi protozoa);	# bacteria archaea fungi protozoa
my $URLsuffix = '/assembly_summary.txt';

#$File::Fetch::USER_AGENT = '';
my $dbURLprefix = 'ftp://ftp.ncbi.nlm.nih.gov/genomes/';
mkdir './list';
my (%pDat,%sDat);

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
		my $fcache;
		my $where = $ff->fetch( to => $dirname ) or die "[x]Cannot download [$url]: $ff->error\n",$verbose?"Please manually download it to [$file].\n":'';
		return 1;
	}
}

for my $group (@Lists) {
	my $Error = 0;
	my $URLfull = $URLprefix . $group . $URLsuffix;
	print "[$URLfull]\n";
	my $Target = "./list/$group.txt";
	my $ret = checkorfetch($Target,$URLfull,1);
	if ($ret == 1) {
		rename './list/assembly_summary.txt',$Target;
	}
=pod
	if (-f $Target) {
		warn "[$Target] already exists, skip downloading.\n";
	} else {
		my $ff = File::Fetch->new(uri => $URLfull);
		my $fcache;
		my $where = $ff->fetch( to => './list' ) or $Error = 1;
		#ddx $ff; #ddx $where;
		if ($Error) {
			warn $ff->error;
			warn "Please manually download [$URLfull] to [$Target].\n";
		} else {
			rename './list/assembly_summary.txt',$Target;
		}
	}
=cut
	open L,'<',$Target or die $!;
	while (<L>) {
		next if /^#/;
		my @d = split /\t/;
		next if $d[11] ne 'Complete Genome';
		#ddx \@d;
		$d[19] =~ s/^${dbURLprefix}//;
		#print join("\t",@d[5,6,7,19]),"\n";
		# 566037	566037	Saccharomycetaceae sp. 'Ashbya aceri'	ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/412/225/GCA_000412225.2_ASM41222v2
		$pDat{$d[5]} = [@d[7,19]];
		if ($d[5] != $d[6]) {
			$sDat{$d[6]} = [@d[7,19]];	# Well, show me the memory.
		}
	}
	close L;
}
my $RefpCount = scalar keys %pDat;
my $RefsCount = scalar keys %sDat;

warn "[!]Genomes Found:[$RefpCount]+$RefsCount.\n";

unless (-d './all/') {
	mkdir 'all',0755;
}

for my $taxid (keys %pDat) {
	my ($name,$gpath) = @{$pDat{$taxid}};
	my $basename = basename($gpath);
print "[$name,$gpath,$basename]\n";
	my $file = "$gpath/md5checksums.txt";
	#my $url = "${dbURLprefix}${file}";
	checkorfetch($file,'',0);
	open M,'<',"$gpath/md5checksums.txt" or die "Error opening '$gpath/md5checksums.txt': $!";
	my (%FileMD5,$fmd5,$file);
	while (<M>) {
		($fmd5,$file) = split /\s+/;
		#if ($file =~ /((${basename}_genomic.fna.gz)|(${basename}_cds_from_genomic.fna.gz)|(${basename}_feature_table.txt.gz))$/) {
		if ($file =~ /(${basename}_genomic.fna.gz)$/) {
			$FileMD5{$file} = $fmd5;
		}
	}
	close M;
	ddx \%FileMD5;
	if (scalar keys %FileMD5 > 0) {
		for my $fn (keys %FileMD5) {
			$fmd5 = $FileMD5{$fn};
			my $filename = "$gpath/$fn";
			checkorfetch($filename,'',0);
			open (my $fh, '<', $filename) or die "Can't open '$filename': $!";
			binmode($fh);
			my $md5 = Digest::MD5->new;
			$md5->addfile($fh);
			close($fh);
			print $md5->hexdigest, "/$fmd5 => $filename\n";
		}
	}
}


# all -> /share/newdata/database/ftp.ncbi.nih.gov/genomes/all
#ddx \%pDat;
