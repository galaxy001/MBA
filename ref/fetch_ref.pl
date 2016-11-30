#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dump qw(ddx);
use File::Fetch;

my $URLprefix = 'ftp://ftp.ncbi.nlm.nih.gov/genomes/genbank/';
my @Lists = qw( archaea fungi protozoa);	# bacteria archaea fungi protozoa
my $URLsuffix = '/assembly_summary.txt';

#$File::Fetch::USER_AGENT = '';

for my $group (@Lists) {
	my $URLfull = $URLprefix . $group . $URLsuffix;
	print "$URLfull\n";
	my $ff = File::Fetch->new(uri => $URLfull);
	my $fcache;
	my $where = $ff->fetch( to => \$fcache ) or die $ff->error;
	ddx $ff;
	ddx $where;
}