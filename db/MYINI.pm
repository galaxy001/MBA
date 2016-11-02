package MYINI;
# I need a hash with order.
use 5.004;
use strict;
use warnings;

our $VERSION = '0.02';
$__PACKAGE__::errstr = '';

# Create an empty object
sub new {
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;
	my $self = {']' => []};	# ini section can never be ']'
	tie %{$self},'INIHash';
	return bless $self, $class;
}
# Create an object from a file
sub read {
	my $class = shift;

	# Check the file
	my $file = shift or return $class->_error( 'You did not specify a file name' );
	return $class->_error( "File '$file' does not exist" )              unless -e $file;
	return $class->_error( "'$file' is a directory, not a file" )       unless -f _;
	return $class->_error( "Insufficient permissions to read '$file'" ) unless -r _;

	# Slurp in the file
	local $/ = undef;
	open CFG, $file or return $class->_error( "Failed to open file '$file': $!" );
	my $contents = <CFG>;
	close CFG;

	$class->read_string( $contents );
}

# Create an object from a string
sub read_string {
	my $self = shift;

	# Parse the file
	my $ns = '_';
	my $counter = 0;
	foreach ( split /(?:\015{1,2}\012|\015|\012)/, shift ) {
		$counter++;

		# Skip comments and empty lines
		next if /^\s*(?:\#|\;|$)/;

		# Remove inline comments
		s/\s\;\s.+$//g;
#print "$_\n";
		# Handle section headers
		if ( /^\s*\[\s*(.+?)\s*\]\s*$/ ) {
			# Create the sub-hash if it doesn't exist.
			# Without this sections without keys will not
			# appear at all in the completed struct.
			$self->{$ns = $1} ||= {'=' => []};	# ini key can never be '='
			push @{$$self{']'}},$ns unless exists $$self{$ns};
			next;
		}

		# Handle properties
		if ( /^\s*([^=]+?)\s*=\s*(.*?)\s*$/ ) {
			push @{$$self{$ns}{'='}},$1 unless exists $$self{$ns}{$1};
			$self->{$ns}->{$1} = $2;
			next;
		}

		return $self->_error( "Syntax error at line $counter: '$_'" );
	}
	return $self;
}

# Save an object to a file
sub write {
	my $self = shift;
	my $file = shift or return $self->_error(
		'No file name provided'
		);

	# Write it to the file
	open( CFG, '>' . $file ) or return $self->_error(
		"Failed to open file '$file' for writing: $!"
		);
	print CFG $self->write_string;
	close CFG;
}

# Save an object to a string
sub write_string {
	my $self = shift;
	my $contents = '';
	foreach my $section (@{$$self{']'}}) {
		next unless defined $section ;
		my $block = $self->{$section};
		$contents .= "\n" if length $contents;
		$contents .= "[$section]\n" unless $section eq '_';
		my %Properties = map { $_ => 1 } keys %{$block};
		delete $Properties{'='};
		foreach my $property ( @{$$block{'='}} ) {
			$contents .= "$property=$block->{$property}\n";
			delete $Properties{$property};
		}
		foreach my $property ( sort keys %Properties ) {
			$contents .= "$property=$block->{$property}\n";
		}
	}
	$contents;
}

# Error handling
sub errstr { $__PACKAGE__::errstr }
sub _error { $__PACKAGE__::errstr = $_[1]; undef }

1;



package INIHash;
use Carp;
require Tie::Hash;

@INIHash::ISA = qw(Tie::StdHash);

sub STORE {
	if ($_[1] eq ']') {
		carp "[!]INI section can never be ']'";
		return;
	}
	#$_[0]->{$_[1]} = $_[2];
	push @{$_[0]->{']'}},$_[1] unless exists $_[0]->{$_[1]};
	for (keys %{$_[2]}) {
		next if $_ eq '=';
		push @{$_[0]->{$_[1]}->{'='}},$_ unless exists $_[0]->{$_[1]}->{$_};
		$_[0]->{$_[1]}->{$_}=$_[2]->{$_};
	}
	$_[0]->{$_[1]}->{'='};	# Why ?
}

1;

__END__
