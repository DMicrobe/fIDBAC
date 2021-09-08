#!/usr/bin/perl -w
#author : liangqian 

use strict;
use Getopt::Long;
use File::Basename;
use FindBin '$Bin';
my ($specise,$stype,$query,$outdir,$sample);

GetOptions(
	"s:s"=>\$specise,
	"t:s"=>\$stype,
	"q:s"=>\$query,
	"o:s"=>\$outdir,

);

if(!defined $specise || !defined $stype ){
	die "####author : liangqian\nperl $0 -s \"Acinetobacter_baumannii\" -t /public/Database/PubMLST/Acinetobacter_baumannii/abaumannii.txt  -q contig.fa -o outdir\n";
	exit 0;
}
`mkdir -m 755 -p $outdir` unless(-d $outdir);
`mkdir -m 755 -p $outdir/tmp` unless(-d "$outdir/tmp");
my $dbDir="/public/Database/PubMLST/$specise";


my @genefa=glob("$dbDir/*.tfa");
my $num=@genefa;

my %stype;
open IN,"<$stype" or die $!;

my $head=<IN>;chomp $head;
my @head=split /\t/,$head;
my @gene;
for(my $i=1;$i<=$num;$i++){
	push @gene,$head[$i];
}

open SH1,">$outdir/tmp/blast.sh" or die $!;
my $gene_table=join "\t",@gene;
my @allenumber;
my (%gene,@align);
foreach my $key(@gene){
	my $fa="$dbDir/$key.tfa";
	print SH1 "blastn -task megablast -evalue 1e-5  -num_threads 8 -max_target_seqs 2 -outfmt 6 -query $query -db $fa -out $outdir/tmp/$key.blast\n";

}
close SH1;
system("sh $outdir/tmp/blast.sh >$outdir/tmp/blast.sh.log 2>$outdir/tmp/blast.sh.e");

foreach my $key(@gene){
	my $len="$dbDir/$key.tfa.len";
	open LEN,"<$len" or die $!;
        while(<LEN>){
		chomp;
		my @len=split /\t/,$_;
		$gene{$len[0]}=$len[1];
	}
	close LEN;
	my @line=split /\n/,`sort -V -k12nr,12 $outdir/tmp/$key.blast`;
	if(@line==1){
		push @align,$line[0];
		my @temp=split /\t/,$line[0];
		my ($target,$identity,$mis,$gap)=($temp[1],$temp[2],$temp[4],$temp[5]);
		my $alle;
		if(($identity>=100 && $mis==0 && $gap==0 && $temp[8]==1 && $temp[9]==$gene{$target} ) or ($identity>=100 && $mis==0 && $gap==0  && $temp[8]==$gene{$target} && $temp[9]==1) ){
			if($target=~/_\d+$/){
				$alle=(split /_/,$target)[-1];
			}elsif($target=~/-\d+$/){
				$alle=(split /-/,$target)[-1];
			}
			push @allenumber,$alle;
			#print "$alle\n";
		}else{
			push @allenumber,"NA";
		}
	}else{
		my $alle;
		foreach my $line(@line){
			my @temp=split /\t/,$line;
			next if ($temp[3]<$gene{$temp[1]});
			next if (defined $alle);
			push @align,$line;
                	my ($target,$identity,$mis,$gap)=($temp[1],$temp[2],$temp[4],$temp[5]);
                	if(($identity>=100 && $mis==0 && $gap==0 && $temp[8]==1 && $temp[9]==$gene{$target} ) or ($identity>=100 && $mis==0 && $gap==0  && $temp[8]==$gene{$target} && $temp[9]==1) ){
                        	if($target=~/_\d+$/){
                                	$alle=(split /_/,$target)[-1];
                        	}elsif($target=~/-\d+$/){
                                	$alle=(split /-/,$target)[-1];
                        	}
                        	push @allenumber,$alle;
                        	#print "$alle\n";
                	}else{
                        	push @allenumber,"NA";
                	}
		#$tagalle=$alle if (defined $alle);		
		}
		if(!defined $alle){
			push @allenumber,"NA";
		}
	}

}
my $alle_1=join "-",@allenumber;
#print "$alle_1\n";
my $alle_table=join "\t",@allenumber;
open OUT1,">$outdir/MLST.align.result.xls" or die $!;
open OUT2,">$outdir/MLST.STtype.txt" or die $!;
print OUT1 "Query\tTarget\tidentity(%)\tAlignment length\tmismatches\tgap opens\tStart position in query\tEnd position in query\tStart position in target\tEnd position in target\tE-value\tscore\n";
my $ali=join "\n",@align;
print OUT1 $ali."\n";
close OUT1;
my $sty;
if($alle_1=~/NA/){
	print OUT2 "There is no matching MLST in database!";
	$sty="--";
}else{
	while(<IN>){
		chomp;
		my @cut=split /\s+/,$_;
		my $temp=join "-",@cut[1..$num];
		#print "$temp\n";
		if($alle_1 eq $temp){
			#print "$alle_1\t$temp\n";
			#print OUT2 "ST $cut[0]\n";
			$sty=$cut[0];
			last;
		}
	}
}
print OUT2 "ST\t$gene_table\n$sty\t$alle_table\n";
close OUT2;

