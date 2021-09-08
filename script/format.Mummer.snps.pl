#!/usr/bin/perl -w

use strict;
# example input file
#/public/Users/liangq/test/popluation/3.snp_MUMmer/genome/A1.fa /public/Users/liangq/test/popluation/3.snp_MUMmer/genome/A297.fa
#NUCMER
#
#    [P1]  [SUB]  [P2]      |   [BUFF]   [DIST]  |  [LEN R]  [LEN Q]  | [FRM]  [TAGS]
#========================================================================================
#   49949   T .   50274     |      195      195  |  3909008    50468  |  1  1  CP010781.1	FBWR01000001.1
#   91996   A .   36390     |    22317    36390  |  3909008   159004  |  1  1  CP010781.1	FBWR01000074.1
#  114313   C G   58707     |    22317    58707  |  3909008   159004  |  1  1  CP010781.1	FBWR01000074.1

my ($in,$out)=@ARGV;
open IN,"<$in" or die $!;

for(my $i=0;$i<5;$i++){
	<IN>;
}

open OUT,">$out" or die $!;

print OUT "refername\tPostion\tref\talt\tquery_name\tquery_pos\n";

while(<IN>){
	chomp;
	s/^\s+(\d+)/$1/;
	my @cut=split /\s+/,$_;
	if($cut[1] eq "." || $cut[2] eq "."){
		next;
	}else{
		print OUT "$cut[-2]\t$cut[0]\t$cut[1]\t$cut[2]\t$cut[-1]\t$cut[3]\n";
	}
}

close IN;
