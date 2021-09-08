#!usr/bin/perl
use strict ;
use Getopt::Long;
use File::Basename;
my ($unigene,$genome, $out) ;
GetOptions(
	"unigene:s"=>\$unigene,
	"genome:s"=>\$genome,
  "out:s"=>\$out
);

usageall()if(!defined $unigene||!defined $genome||!defined $out);
sub usageall{
	die qq/
	perl get_genes_stats.pl -unigene <unigenes fasta file> -genome <genome fasta file> -out <out file> 
\n/;
}

open FASTA,"<$genome" or die $!;
$/=">";
<FASTA>;
$/="\n";
my ($genome_len,$genome_GC_num);
while(<FASTA>){
    chomp;
    my $id=$_;
    $/=">";
    my $seq1=<FASTA>;
    $/="\n";
    $seq1=~s/>$//g;$seq1=~s/\s+//g;
    my $len=length($seq1);
    $genome_len+=$len;
    $genome_GC_num += $seq1 =~ tr/gcGC/gcGC/;
}
close FASTA;

open OUT,">$out";
my ($gene_num,$gene_len,$ave_len,$gene_GC_num,$gene_GC,$gene_genome,$inter_len,$inter_GC_num,$inter_GC,$inter_genome);
my %h1;

open FASTA,"<$unigene" or die $!;
$/=">";
<FASTA>;
$/="\n";
while(<FASTA>){
    $gene_num+=1;
    chomp;
    my $id=$_;
    $/=">";
    my $seq1=<FASTA>;
    $/="\n";
    $seq1=~s/>$//g;$seq1=~s/\s+//g;
    my $len=length($seq1);
    $gene_len+=$len;
    $gene_GC_num+= $seq1 =~ tr/gcGC/gcGC/
}
close FASTA;
$inter_GC_num=$genome_GC_num-$gene_GC_num;
$inter_len=$genome_len-$gene_len;
$ave_len=sprintf("%.2f",$gene_len/$gene_num);
$gene_GC=sprintf("%.2f",100*$gene_GC_num/$gene_len);
$inter_GC=sprintf("%.2f",100*$inter_GC_num/$inter_len);
$gene_genome=sprintf("%.2f",100*$gene_len/$genome_len);
$inter_genome=sprintf("%.2f",100*$inter_len/$genome_len);
$gene_len=&digitize($gene_len);
$ave_len=&digitize($ave_len);
$inter_len=&digitize($inter_len);
print OUT "Gene_num\t$gene_num\n";
print OUT "Gene_total_length(bp)\t$gene_len\n";
print OUT "Gene_average_length(bp)\t$ave_len\n";
print OUT "GC_content_in_gene_region(%)\t$gene_GC\n";
print OUT "Gene/Genome(%)\t$gene_genome\n";
print OUT "Intergenetic_region_length(bp)\t$inter_len\n";
print OUT "GC_content_in_intergenetic_region(%)\t$inter_GC\n";
print OUT "Intergenetic/Genome(%)\t$inter_genome\n";

close OUT ;

sub     digitize
{
    my $v = shift or return '0';
    $v =~ s/(?<=^\d)(?=(\d\d\d)+$)     #处理不含小数点的情况
            |
            (?<=^\d\d)(?=(\d\d\d)+$)   #处理不含小数点的情况
            |
            (?<=\d)(?=(\d\d\d)+\.)    #处理整数部分
            |
            (?<=\.\d\d\d)(?!$)        #处理小数点后面第一次千分位，例子中就是.127后面的逗号
            |
            (?<=\G\d\d\d)(?!\.|$)     #处理小数点后第一个千分位以后的内容，或者不含小数点的情况
            /,/gx;
    return $v;
}

