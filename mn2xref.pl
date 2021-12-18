#!/usr/bin/env perl
my $USAGE = "Usage: $0 [--inifile Xref2var.ini] [--section Xref2Var] [--recmark lx] [--eolrep #] [--reptag __hash__] [--debug] [file.sfm]";
=pod
FLEx (as of version 9.1) has a bug in the import process when a subentry is imported:
 * the first reference to a main entry is converted to a link back to that main entry
 *  If the main entry has a matching subentry, the link is taken to be a complex form
 * otherwise it is a variant.
 * 2nd and subsequent references are ignored.

This script changes the 2nd-nth references to cross references with special \lf tags. Once those have been created and imported into a FLEx database, a companion script will modify those to be variant entries. Those variant entries can be converted to complex forms by the Var2Compform.pl script of the SubEntry Promotion repo.

The ini file should have sections with syntax like this:
[Xref2Var]
#
FwdataIn=FwProject-before.fwdata
FwdataOut=FwProject.fwdata
EntryXRefAbbrev=EntryComponent
# tag will be EntryComponent-<component#>
# EntryComponent-2, EntryComponent-3, .etc
SenseXRefPrefix=SenseComponent-
# tag will be SenseComponent-<sense#>-<component#>
# e.g. SenseComponent-3-4 would be sense 3 occuring as the 4th componentc
MainRefMarker=mn
=cut
use 5.020;
use utf8;
use open qw/:std :utf8/;

use strict;
use warnings;
use English;
use Data::Dumper qw(Dumper);

use File::Basename;
my $scriptname = fileparse($0, qr/\.[^.]*/); # script name without the .pl

use Getopt::Long;
GetOptions (
	'inifile:s'   => \(my $inifilename = "Xref2Var.ini"), # ini filename
	'section:s'   => \(my $inisection = "Xref2Var"), # section of ini file to use
	'recmark:s' => \(my $recmark = "lx"), # record marker, default lx
	'eolrep:s' => \(my $eolrep = "#"), # character used to replace EOL
	'reptag:s' => \(my $reptag = "__hash__"), # tag to use in place of the EOL replacement character
	# e.g., an alternative is --eolrep % --reptag __percent__

	# Be aware # is the bash comment character, so quote it if you want to specify it.
	#	Better yet, just don't specify it -- it's the default.
	'debug'       => \my $debug,
	) or die $USAGE;

# check your options and assign their information to variables here
$recmark =~ s/[\\ ]//g; # no backslashes or spaces in record marker

use Config::Tiny;
my $config = Config::Tiny->read($inifilename, 'crlf');
say STDERR "INI file : $inifilename" if $debug;
die "Quitting: couldn't find the INI file $inifilename\n$USAGE\n" if !$config;
my $EntryXRefAbbrev = $config->{"$inisection"}->{EntryXRefAbbrev};
say STDERR "EntryXRefAbbrev : $EntryXRefAbbrev" if $debug;
my $SenseXRefPrefix= $config->{"$inisection"}->{SenseXRefPrefix};
say STDERR "SenseXRefPrefix:$SenseXRefPrefix" if $debug;
my $MainRefMarker= $config->{"$inisection"}->{MainRefMarker};
say STDERR "MainRefMarker:$MainRefMarker" if $debug;

# generate array of the input file with one SFM record per line (opl)
my @opledfile_in;
my $line = ""; # accumulated SFM record
while (<>) {
	s/\R//g; # chomp that doesn't care about Linux & Windows
	#perhaps s/\R*$//; if we want to leave in \r characters in the middle of a line
	s/$eolrep/$reptag/g;
	$_ .= "$eolrep";
	if (/^\\$recmark /) {
		$line =~ s/$eolrep$/\n/;
		push @opledfile_in, $line;
		$line = $_;
		}
	else { $line .= $_ }
	}
push @opledfile_in, $line;

for my $oplline (@opledfile_in) {
	my $mncount = 0;
	if ($oplline =~ m/\\(ps|sn|ge|de) .+?\\$MainRefMarker /) {
		say STDERR "Component reference within a sense";
		say STDERR $oplline;
		}
	if (($oplline =~ m/\\$MainRefMarker /) && !($oplline =~ m/\\spec /)) {
		say STDERR "Component reference without a ComplexFormType marker";
		say STDERR $oplline;
		}
	$oplline =~ s/(\\$MainRefMarker [^#]*)/$mncount++; mnxrefreplace($mncount,$1)/ge;

	say STDERR "oplline:", Dumper($oplline) if $debug;
	#de_opl this line
	for ($oplline) {
		s/$eolrep/\n/g;
		s/$reptag/$eolrep/g;
		print;
		}
	}

sub mnxrefreplace {
my ($mnc, $mnfield) = @_;

die "too many component references (max 9):$mnfield" if $mnc > 9;

if ($mnc > 1) {
	if ($mnfield =~ m/ [0-9]+$/) {
		$mnfield =~ s/(\\$MainRefMarker )(.*?) ([0-9]+)/\\lf $SenseXRefPrefix$3-$mnc\n\\lv $2/;
		}
	else {
		$mnfield =~ s/\\$MainRefMarker /\\lf $EntryXRefAbbrev-$mnc\n\\lv /;
		}
}
return $mnfield;
}