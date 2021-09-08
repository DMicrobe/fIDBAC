#!usr/bin/perl
#author : modified  by liangqian  at 20181206
use strict ;
use Getopt::Long;
use File::Basename ;
use FindBin '$Bin' ;
use Cwd 'abs_path';
my ($infa,$outdir,$prefix,$strain ) ;
my ($ref,$strainsnpdir,$allsnpstat,$pos,$snpbase) ;
GetOptions(
        "infa:s"=>\$infa,
        "outdir:s"=>\$outdir,
	"prefix:s"=>\$prefix,
	"species:s"=>\$strain,
);
if (!defined $infa || !defined $outdir||!defined $prefix||!defined $strain){
        print "\n";
        die "perl $0 -infa <in put fasta> -species <Bacillus_cereus/Clostridioides_difficile/Salmonella_enterica/Staphylococcus_aureus/Vibrio_parahaemolyticus> -outdir <outdir> -prefix <XXX>  \n"
}

`mkdir -m 755 -p $outdir` unless (-d "$outdir");
$infa=abs_path($infa);
$outdir=abs_path($outdir);

my ($snpdata,$ref);
open IN,"$Bin/snpdata.config" or die ;
while (<IN>){
	chomp ;
	my @cut = split (/\t/,$_) ;
	my $id = @cut[0] ;
	if ($id eq $strain){
		$snpdata=$cut[1];
		$ref=$cut[2];	
		last;
	}
}
close IN ;
$/="\n" ;
print "$strain\t$snpdata\t$ref\n";
if(!defined $ref){
	print STDERR "the species is not in the snpdatabase!";
	exit 0;
}

print "sh $Bin/run_Mummer.snp.sh ref:$ref infa:$infa $outdir $prefix\n" ;
system ("sh $Bin/run_Mummer.snp.sh $ref $infa $outdir $prefix >$outdir/Mummer.log 2>$outdir/Mummer.error");
my %ha ;
open IN,"$outdir/$prefix.snps.xls" or die ;
while(<IN>){
	chomp ;
	my @l =  split (/\t/,$_) ;
	$ha{$l[0]}{$l[1]} = $l[3] ;		
}
close IN ;
open OUT,">$outdir/tmp.snp.fa" or die $!;
print OUT ">$prefix\n" ;
open IN,"<$snpdata/pos.txt" or die $!;
<IN> ;
my $seq ;
while (<IN>){
	chomp ;
	my @l  = split (/\t/,$_) ;
	if (exists $ha{$l[0]}{$l[1]}){
		$seq .= "$ha{$l[0]}{$l[1]}"	 ;	
	}else{
		$seq .= "$l[2]" ;
	}
}
print OUT "$seq\n" ;
close IN ;
close OUT ;
my $snpbase="$snpdata/snp.fa";
system ("cat $outdir/tmp.snp.fa $snpbase >$outdir/snp.fa") ;
system ("cd $outdir && python3 $Bin/cmp.py $outdir/snp.fa >$outdir/top10.list") ;
system ("cd $outdir && perl $Bin/get_fasta_by_idlist.pl $outdir/top10.list $outdir/snp.fa $outdir ") ;
system ("cd $outdir && sh $Bin/phylip.tree.sh >phylip.log 2>phylip.err") ;
system ("perl $Bin/closest_snp_tre.pl -indir $outdir/") ;
#system ("/public/Biosoft/convert/svg2xxx $outdir/closeclosest_snp_tre.svg $outdir/") ;


