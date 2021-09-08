#!/usr/bin/perl
use strict;
use FindBin qw($Bin);
use lib "$Bin";
use lib "$Bin/SVG";
use Tree::nhx_svg;
use Getopt::Long;

my $usage = <<END;
 perl $0 <in.nhx/newick> [options]
   --italic     font style of taxon names is italic;

END

my ($help, $italic);
GetOptions(
	"italic" => \$italic,
	"help" => \$help,
);

die $usage if (@ARGV != 1 || $help);
my $innhx = shift;


## read in tree
open (IN,"$innhx") or die "Can't open: $innhx\n";
$/ = ";";
my $str = <IN>;

my $nhx = Tree::nhx_svg->new('show_B',1,'show_ruler',0,'show_W',1,
	'c_line',"#000000",'line_width',2,'c_W',"#5050D0",'right_margin',"240",
	'c_B',"#5050D0",'fsize',14,'skip',30,'fsize2',12, 'width', "600",
	'show_root_branch', 0, 'taxon_name_style', $italic,
);

$nhx->parse($str);

print $nhx->plot();
close IN;
