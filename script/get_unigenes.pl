#!usr/bin/perl
use strict ;
use Getopt::Long;
use File::Basename;
use Bio::SeqIO;
use Bio::SearchIO;
my ($in, $contig, $predict, $out) ;
GetOptions(
	"in:s"=>\$in,
	"contig:s"=>\$contig,
   "out:s"=>\$out
);

usageall()if(!defined $in||!defined $contig||!defined $out);
sub usageall{
	die qq/
	perl get_unigenes.pl -in <predict txt> -contig <contig fasta file> -out <out file> 
\n/;
}

open OUT,">$out" or die ;
open FASTA,"$contig" or die ;
my (%h1,%h2,%h3)=();
my $FASTA=Bio::SeqIO->new(-file=>"$contig", -format=>"fasta");
while(my $seq=$FASTA->next_seq){
    my $id=$seq->id;
    my $seq1=$seq->seq;
    $h1{$id}=$seq1; # print "$id\n";
}

open IN,"$in" or die ;
 my $id; my $s1; my $e1; my $b; my $id1;
while(<IN>){
	chomp;
	 if (/>/){
	 	my @l=split(/\s+/, $_);
  $id=$l[0]; $id=~s/>//; 
  }
  $b=$h1{$id};
	
	if ($_ =~/>(.*)/){
		$id1=$1;  
	}
	else{
		$h2{$id1}=$_; 
	#	print "$id1\t$h2{$id1}\n"; 
	}
	 my $as=$h2{$id}; 
   my ($id2, $s1, $e1, $strand1)=split(/\s+/, $_); 
   next if (abs($e1-$s1) > 10000 || abs($e1-$s1) < 50 );
  if($e1 > $s1){
   my $seq=substr($b,$s1-1,$e1-$s1+1);  
   if (/GLIMMER/ | /orfID.start/ | />/){next;}
     print OUT ">$id.$s1:$e1\n$seq\n";	
   }
   else{
   	my $seq=substr($b,$e1-1,$s1-$e1+1);
   	$seq=reverse($seq); $seq=~tr/ATCG/TAGC/;
   	if (/GLIMMER/ | /orfID.start/ | />/){next;}
     print OUT ">$id.$s1:$e1\n$seq\n";	
   }
  

}


close IN ;
close OUT ;
