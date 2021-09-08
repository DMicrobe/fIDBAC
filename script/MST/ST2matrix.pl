#!usr/bin/perl
use strict ;
my $infile = shift ;
my  $type = shift ;#fasta or genotype
my @samples ;
my %ha ;
my $len ;
my %ex ;
if ($type eq "fasta"){
open IN,"<$infile" or die ;
$/=">" ; <IN> ;
while (<IN>){
	chomp ;
	my @l = split ("\n",$_) ;
	my $id = shift @l ;
	push(@samples,$id) ;
	my $seq = join ("",@l) ;
	my $tmp = join ("\t",@l) ;$ex{$id} = $tmp ;
	my @ns = split ("",$seq) ;
	$len = @ns ;
	my $i ; for ($i=0;$i<=@ns-1;$i++){
		$ha{$id}{$i} = $ns[$i] ;
	}
}
close IN ;

}elsif($type eq "genotype"){
	open IN,"<$infile" or die ;	
	<IN> ;
	while (<IN>){
		chomp ;
		my @l = split (/\t/,$_) ;
		my $id = shift @l ;
		push(@samples,$id) ;
		#my $ss = shift @l ;
		my $tmp = join ("\t",@l) ;$ex{$id} = $tmp ;
		$len = @l ;
		my $i ;for ($i=0 ; $i<=@l-1; $i++){
			$ha{$id}{$i} = $l[$i] ;
		}
	}

	close IN ;
	
}

my @SP ;

my $p=0 ;
my $m ;for ($m=0;$m<=@samples-1;$m++){
	if($p==1){
		$m-- ;
	}
	my $sp1 = $samples[$m] ;
#	my $p = 0 ;
	my $new_name ;
	my @tmps ;
	my @as ;
	my $n  ; for ($n=$m+1;$n<=@samples-1;$n++){
		my $sp2 = $samples[$n] ;
		if ($ex{$sp1} eq $ex{$sp2}) {
			push (@tmps,$sp2) ;
			push (@as,$n) ;
			$p=1 ;
				
		}else{

		}
		
	}
	if ($p==1){
		my $tmp = join("\/",@tmps) ;
		$new_name = "$sp1\/$tmp" ;
		push (@SP,$new_name);
		$ex{$new_name} = $ex{$sp1} ;
		my $ss; for ($ss=0;$ss<=$len-1;$ss++){
			$ha{$new_name}{$ss} = $ha{$sp1}{$ss} ;
		}
		my $tt;for ($tt=0;$tt<=@as-1;$tt++){
			undef(@samples[$as[$tt]]) ;
		}
		undef(@samples[$m]) ;
	}else {
					
		
	}
#	print "sp1:$sp1\t$new_name\n" ;
	@samples= grep {$_} @samples;
#	print "samples:$p...@samples...\n" ;	
#	print "samples:@samples\n@SP\n" ;

}




my $tt ;for ($tt=0;$tt<=@samples-1;$tt++){
	push(@SP,$samples[$tt]) ;
}
#@SP=(@SP,@samples) ;


#print "OK\n" ;

my $head =$SP[0];
my $t ; for ($t=1;$t<=@SP-1;$t++){
	$SP[$t] =~ s/\/$// ;
        $head .= "\t$SP[$t]" ;
}
print "$head\n" ;

my $m ;for ($m=0 ; $m<=@SP-1;$m++){
	my $sp1 = $SP[$m] ;
	my $line ;
	my $n  ; for ($n=0;$n<=@SP-1;$n++){
		my $sp2 = $SP[$n] ;
		my $count =0 ;
	#	print "samples:$sp1\t$sp2\n" ;
	#	print "$len\n" ;
		my $i ; for ($i=0;$i<=$len-1;$i++){
		#	print "$ha{$sp1}{$i}...$ha{$sp2}{$i}\n" ;
			if ($ha{$sp1}{$i} ne $ha{$sp2}{$i}){
				$count++ ;
			}	
		}
		if ($n==0){
			$line = $count ;
		}else{
			$line .= "\t$count" ;
		}
	}
	print "$line\n" ;
	
}

