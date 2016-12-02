#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dump qw(ddx);
use File::Fetch;

my $URLprefix = 'ftp://ftp.ncbi.nlm.nih.gov/genomes/genbank/';
my @Lists = qw( archaea fungi protozoa);	# bacteria archaea fungi protozoa
my $URLsuffix = '/assembly_summary.txt';

#$File::Fetch::USER_AGENT = '';
mkdir './list';
my %Dat;

for my $group (@Lists) {
	my $Error = 0;
	my $URLfull = $URLprefix . $group . $URLsuffix;
	print "[$URLfull]\n";
	my $Target = "./list/$group.txt";
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
	open L,'<',$Target;
	while (<L>) {
		next if /^#/;
		my @d = split /\t/;
		next if $d[11] ne 'Complete Genome';
		#ddx \@d;
		print join("\t",@d[5,6,7,19]),"\n";
	}
}
