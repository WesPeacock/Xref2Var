#!/usr/bin/env perl
my $USAGE = "Usage: $0 [--inifile Xref2var.ini] [--section Xref2Var] [--recmark lx] [--eolrep #] [--reptag __hash__] [--debug] [file.sfm]";
=pod
This script is a stub that provides the code for opl'ing and de_opl'ing an input file
It also includes code to:
	- use an ini file (commented out)
	- process command line options including debugging

The ini file should have sections with syntax like this:
[Xref2Var]
#
FwdataIn=FwProject-before.fwdata
FwdataOut=FwProject.fwdata
EntryXRefAbbrev=SEpR-E
SenseXRefPrefix=SEpR-S-
# matching senses will be SEpR-S-1, SEpR-S-2, etc


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

# if you need  a config file uncomment the following and modify it for the initialization you need.
# if you have set the $inifilename & $inisection in the options, you only need to set the parameter variables according to the parameter names

use Config::Tiny;
my $config = Config::Tiny->read($inifilename, 'crlf');
say STDERR "INI file : $inifilename" if $debug;
die "Quitting: couldn't find the INI file $inifilename\n$USAGE\n" if !$config;
my $EntryXRefAbbrev = $config->{"$inisection"}->{EntryXRefAbbrev};
say STDERR "EntryXRefAbbrev : $EntryXRefAbbrev" if $debug;
my $SenseXRefPrefix= $config->{"$inisection"}->{SenseXRefPrefix};
say STDERR "SenseXRefPrefix:$SenseXRefPrefix" if $debug;

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
# Insert code here to perform on each opl'ed line.
# Note that a next command will prevent the line from printing
my $mncount = 0;
$oplline =~ s/(\\mn [^#]*)/$mncount++; mnxrefreplace($mncount,$1)/ge;

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

if ($mnc > 1) {
	if ($mnfield =~ m/[0-9]$/) {
		$mnfield =~ s/(\\mn )(.*?)([0-9]+)/\\lf $SenseXRefPrefix$3\n\\lv $2/;
		}
	else {
		$mnfield =~ s/\\mn /\\lf $EntryXRefAbbrev\n\\lv /;
		}
}
return $mnfield;
}