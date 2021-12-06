#!/usr/bin/perl
# You should probably use the related bash script to call this script, but you can use: 
# perl ./Xref2Var.pl

my $debug=0;
my $checktags=0; #Stop after checking the validity of the tags

use 5.016;
use strict;
use warnings;
use English;
use Data::Dumper qw(Dumper);
use utf8;

use open qw/:std :utf8/;
use XML::LibXML;

use Config::Tiny;
my $configfile = 'Xref2Var.ini';
 # ; Xref2Var.ini file looks like:
 # [Xref2Var]
#
 # FwdataIn=FwProject-before.fwdata
 # FwdataOut=FwProject.fwdata
 # EntryXRefAbbrev=SEpR-E
 # SenseXRefPrefix=SEpR-S-

my $inisection = 'Xref2Var';
my $config = Config::Tiny->read($configfile, 'crlf');
#ToDo: should also use Getopt::Long instead of setting variables as above
die "Couldn't find the INI file:$configfile\nQuitting" if !$config;
my $infilename = $config->{$inisection}->{FwdataIn};
my $outfilename = $config->{$inisection}->{FwdataOut};

my $lockfile = $infilename . '.lock' ;
die "A lockfile exists: $lockfile\
Don't run $0 when FW is running.\
Run it on a copy of the project, not the original!\
I'm quitting" if -f $lockfile ;

my $EntryXRefAbbrev =  $config->{$inisection}->{EntryXRefAbbrev};
say STDERR "Entry RefType Abbrev= $EntryXRefAbbrev";

my $SenseXRefPrefix = $config->{$inisection}->{SenseXRefPrefix};
say STDERR "Sense RefType Prefix=$SenseXRefPrefix";

say STDERR "Processing fwdata file: $infilename";

my $fwdatatree = XML::LibXML->load_xml(location => $infilename);
my %rthash;
foreach my $rt ($fwdatatree->findnodes(q#//rt#)) {
	my $guid = $rt->getAttribute('guid');
	$rthash{$guid} = $rt;
	}
# die "loaded & hashed  $infilename";

my ($ecrrt) = $fwdatatree->findnodes(q#//*[contains(., '# .  $EntryXRefAbbrev . q#')]/ancestor::rt#);
Xref2Var($ecrrt);
# die "after Entries";
my @sensetypes = $fwdatatree->findnodes(q#//*[contains(., '# . $SenseXRefPrefix . q#')]/ancestor::rt#);
foreach my $snrt  (@sensetypes) {
	Xref2Var($snrt);
	}

die "skip writing" ;
my $xmlstring = $fwdatatree->toString;
# Some miscellaneous Tidying differences
$xmlstring =~ s#><#>\n<#g;
$xmlstring =~ s#(<Run.*?)/\>#$1\>\</Run\>#g;
$xmlstring =~ s#/># />#g;
say "";
say "Finished processing, writing modified  $outfilename" ;
open my $out_fh, '>:raw', $outfilename;
print {$out_fh} $xmlstring;

# Subroutines

sub Xref2Var{
my ($xrefrt) =@_;
my $Abbrev = ($xrefrt->findnodes('./Abbreviation/AUni/text()'));
say  STDERR "Abbrev:$Abbrev";
my @members = $xrefrt->findnodes('./Members/objsur') ;
foreach my $memb (@members) {
	my $membrt = $rthash{$memb->getAttribute('guid')};
	say STDERR "Member:", $membrt;
	# Xref targets
	# 1st is the ComplexForm
	# 2nd - nth are Components to be added to the ComponentLexeme list
	#     of EntryRef of the first if they aren't already there
	my @targets = $membrt->findnodes('./Targets/objsur') ;
	my $firsttarget = 1;
	my $FirstEntryComponentLexemes = 0;
	foreach my $targ (@targets) {
		my $targrt = $rthash{$targ->getAttribute('guid')};
		if ($firsttarget) {
			$firsttarget = 0;
			say STDERR "first target", rtheader($targrt) ;
			my ($FirstEntryRef) = $targrt->findnodes('./EntryRefs/objsur') ;
			say STDERR "FirstEntryRef", rtheader($FirstEntryRef);
			($FirstEntryComponentLexemes) = $rthash{$FirstEntryRef->getAttribute('guid')}->findnodes('./ComponentLexemes');
			say STDERR "FirstEntryComponentLexemes", $FirstEntryComponentLexemes;
			say STDERR "FECL as node:", ref($FirstEntryComponentLexemes);
			}
		else {
			my $targstring = $targ->toString;
			say STDERR "type string:", ref ($targstring);
			say STDERR "subsequent target-rt:", rtheader($targrt) ;
			my ($newnode) = XML::LibXML->load_xml(string => $targstring)->findnodes('//*');
			say STDERR "subsequent target as node:",  $newnode;
			say STDERR "newnode ref:", ref($newnode);
			$FirstEntryComponentLexemes->addChild($newnode);
			say STDERR "FirstEntryComponentLexemes after addition", $FirstEntryComponentLexemes;
			}
		}
	}
}

sub rtheader { # dump the <rt> part of the record
my ($node) = @_;
return  ( split /\n/, $node )[0];
}

sub traverseuptoclass { 
	# starting at $rt
	#    go up the ownerguid links until you reach an
	#         rt @class == $rtclass
	#    or 
	#         no more ownerguid links
	# return the rt you found.
my ($rt, $rtclass) = @_;
	while ($rt->getAttribute('class') ne $rtclass) {
#		say ' At ', rtheader($rt);
		if ( !$rt->hasAttribute('ownerguid') ) {last} ;
		# find node whose @guid = $rt's @ownerguid
		$rt = $rthash{$rt->getAttribute('ownerguid')};
	}
#	say 'Found ', rtheader($rt);
	return $rt;
}

sub displaylexentstring {
my ($lexentrt) = @_;

my ($formguid) = $lexentrt->findvalue('./LexemeForm/objsur/@guid');
my $formrt =  $rthash{$formguid};
my ($formstring) =($rthash{$formguid}->findnodes('./Form/AUni/text()'))[0]->toString;
# If there's more than one encoding, you only get the first

my ($homographno) = $lexentrt->findvalue('./HomographNumber/@val');

my $guid = $lexentrt->getAttribute('guid');
return qq#$formstring # . ($homographno ? qq#hm:$homographno #  : "") . qq#(guid="$guid")#;
}
