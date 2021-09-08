#!/usr/bin/perl -w
use strict;
use Data::Dumper;
my $gff = shift ;
my $gene = shift ;
my $out = shift ;
my $id=shift;
my %ha ; my $s1 = 0 ;

open GFF,"$gff" or die $!;
while(<GFF>){
	chomp;
	if($_=~m/^\#/){next;}
	my ($chr1, $msu1, $type1, $s1, $e1, $dot1, $strand1, $dot2, $desc1)=split(/\t/, $_);
	if (!$msu1){next;}
  if($type1 eq "CDS"){
	my $gene = $1 if ($desc1=~/ID=([^;]+)/);
	$ha{$gene}=[($s1, $e1, $chr1)] ; 
 }
}
close GFF ;

my %rename;
if(defined $id){
open ID,"<$id" or die $!;
while(<ID>){
	chomp;
	my @cut=split /\t/,$_;
	$rename{$cut[1]}=$cut[0];
}
close ID;
}
open OUT, ">$out" or die ;
open IN,"$gene" or die ;
$/=">";<IN>;
while (<IN>){
	chomp ;
	my ($tag, @seqs) = split (/\n/,$_);
	my $id = (split /\s+/, $tag)[0];
	my $seq = join ("\n", @seqs);
	next if (!exists $ha{$id});
 	my ($s1, $e1, $chr) = @{$ha{$id}} ;
  	print OUT ">$rename{$chr}|$s1:$e1\n$seq\n" if (exists $rename{$chr});
	print OUT ">$chr|$s1:$e1\n$seq\n" if (!exists $rename{$chr});
}
close IN;
close OUT ;
