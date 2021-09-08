#!usr/bin/perl
use strict ;
use List::Util qw/max min/;
my $dot = shift ;
my $outdir = shift ;
open OUT1,">$outdir/id_rep.txt" or die ;
open OUT2,">$outdir/MST_1.fin.dot" or die ; 
open IN,"$dot" or die ;
my @len;
while (<IN>){
	chomp ;
	my $l = $_ ;
	if (/>/) {
		$l =~ s/\.000000// ;
		my $len  ;
		if ($l =~ /label = \"(\w+)\"/) {
			if($1>=1 && $1<=5){
				$len=0.5+$1/10;
			}elsif($1>5 && $1<15){
				$len=1+$1/20;
			}elsif($1>15 && $1<=30){
				$len=1.75+$1/30;
			}elsif($1>50 && $1<=80){
				$len=1.75+$1/30+$1/50;
			}elsif($1>80 && $1<=100){
				$len=2+$1/50+$1/100
			}elsif($1>100 && $1<=1000){
				$len=2+$1/100+$1/1000;
			}elsif($1>1000 && $1<=5000){
				$len=2+$1/100+$1/1000+$1/5000;
			}elsif($1>5000 && $1<=10000){
				$len=2+$1/1000+$1/5000+$1/10000;	
			}elsif($1>10000 && $1<100000){
				$len=2+$1/2000+$1/5000+$1/10000+$1/100000;
			}else{
				$len=2+$1/2000+$1/5000+$1/10000+$1/100000+1;
			}
		     push @len,$1;	
		}
		$l =~ s/\]/,color = "Snow4", len=$len,weight = 80]/ ;  
	}elsif(/model/){
		$l = "model = circuit;\npack = true;\noverlap_shrink = true ;" ;
	}elsif(/digraph|layout|overlap/){
		$l = $_ ;	
	}elsif(/graph/){
		next ;
	}elsif(/splines/){
		$l = "splines = true;" ;
	}elsif(/^$/){
		next ;
		print "oK\n" ;
	}
	else{
		$l =~ s/\]/,shape = circle,color="dimgray", fillcolor="DeepPink1", style=filled]/ ;
		$l =~ s/style = solid,// ;
		my $width_ori = 0.55 ;
		my $width ;
		my $id_ex; 
		if (/label = \"(\S+)\"/) {
			my @samples = split (/\//,$1) ;
			$id_ex = $samples[0] ;
			my $num = @samples ;
			$width = $width_ori+$num*0.02 ;
#			$1 = "\[width = $width, label = \"$id_ex\",shape = circle,color=\"DeepPink\", fillcolor=\"DeepPink\", style=filled\];" ;
			print OUT1 "$id_ex\t$1\n" ;
		}
		 $l =~ s/width = 0.05/width = $width/ ; 
		 $l =~ s/label = \"(\S+)\"/label = \"$id_ex\"/ 
	}	
	print OUT2 "$l\n" ;

}
close IN;
close OUT1;
close OUT2;
my $min_len=min @len;
my $max_len=max @len;
print "$min_len\t$max_len\n";
if($min_len>10 || $max_len>100){
	open IN2,"<$outdir/MST_1.fin.dot" or die $!;
        open OUT3,">$outdir/MST_1.fin.dot.temp" or die $!;
	while (<IN2>){
        chomp ;
        my $l = $_ ;
        if (/>/) {
		my $len;
		if($l=~ /len=(\S+),/){
			$len=$1/$min_len+1;
			print "$1\t$len\n";
			$l=~s/len=\S+,/len=$len,/;
			print OUT3 "$l\n";
		}else{
			print OUT3 "$l\n";
		}
	}else{
		print OUT3 "$l\n";
	}
      }
      close IN2;
        close OUT3;
	system("mv $outdir/MST_1.fin.dot.temp $outdir/MST_1.fin.dot");
}
