#!usr/bin/perl
use strict ;
my $list = shift ;
my $fa = shift ;
my $outdir = shift ;
my %ha;
open IN,"$list" or die ;
while (<IN>){
	chomp ;
	my @l = split (/\t/,$_) ;
	$ha{$l[0]} = 1 ;
}
close IN ;

open OUT1,">$outdir/snp.top10.fa" or die ;
open OUT2,">$outdir/rename.txt" or die ; 
$/=">" ; <IN> ;
open IN,"$fa" or die ;
my $count=0 ;
while (<IN>){
	chomp ;
	my @l = split (/\n/,$_) ;
	my $id = shift  @l ;
	my @tmps = split(/\s+/,$id) ;
	my $ids = $tmps[0] ;
#	if ($ids =~ /subsp\._|substr\._/){
#		my @m= split (/\._/,$ids) ;
#		$ids = $m[1] ;
#	}
	my $seq = join ("",@l ) ;
	my $tmpid = "A$count" ;
	if (exists $ha{$ids}){
		if ($ids =~ /subsp\._|substr\._/){
			my @m= split (/\._/,$ids) ;
			$ids = $m[1] ;
		}
		print OUT2 "$tmpid\t$ids\n" ;
		print OUT1 ">$tmpid\n$seq\n" ;
		$count++ ;
	}

}
