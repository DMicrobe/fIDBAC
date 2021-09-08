#!usr/bin/perl -w
use strict;
use Getopt::Long;

my ($input,$anno,$out,$identity,$coverage);
GetOptions(
  "input:s"=>\$input,
	"anno:s"=>\$anno,
	"out:s"=>\$out,
	"identity:s" =>\$identity,
	"coverage:s"=>\$coverage,
);
usageall()if(!defined $input ||! defined $anno ||! defined $out);
sub usageall{
	die qq/perl get_CARDannot_info.pl -input <input file> -anno <anno file> -out <out file>\n/;
}
$coverage ||= 60 ;
$identity ||= 90 ;

my (%ha, %hash_id, %mutations, %count) ;
open INI,"<$anno" or die ;
while(<INI>){
    chomp;
	next if(/^(\s+)$/ || /^#/);
	my @ids = split /\t/,$_;
	$ids[1] = "---" unless(defined $ids[1]);
	$hash_id{$ids[0]} = "$ids[1]\t$ids[2]\t$ids[3]\t$ids[4]\t$ids[6]\t$ids[5]";
	if ($ids[7] ne "--"){
			$mutations{$ids[0]} = $ids[7] ;
	}
}
open INR,"<$input" or die;
open OUT1,">$out.info.xls" or die ;
open OUT2, ">$out.filter.homolog.xls" or die ;
open OUT3, ">$out.filter.variant.xls" or die;
print OUT1 "Query_id\tSubject_id\t%Identity\tE-value\tScore\tName\tAMR Gene Family\tDrug Class\tResistance Mechanism\tModel Type\tDescription\n" ;
print OUT2 "Query_id\tSubject_id\t%Identity\tE-value\tScore\tName\tAMR Gene Family\tDrug Class\tResistance Mechanism\tModel Type\tDescription\n" ;
print OUT3 "Query_id\tSubject_id\t%Identity\tE-value\tScore\tName\tAMR Gene Family\tDrug Class\tResistance Mechanism\tModel Type\tMutations\tDescription\n" ;
my $index ;
my $pos; 
my %parameter ;
my $n = 0 ;
while(<INR>){
  chomp;
	next if(/^(\s+)$/ || /^#/);
	my @cut = split /\t/,$_;
	my $q_len=$cut[1];
	my $start = $cut[6] ;
	my $end = $cut[7];
	my $align_seq = $cut[14] ;
	my $align_subject = $cut[15] ;
	my $count = $align_subject =~ s/\-/\-/g;
	my $ali_str = $align_seq ;
	$ali_str =~ s/\W+//g;
	my $ali_len = length $ali_str ;
	
	if (exists $mutations{$cut[4]}){
		my @vars = split (/\;/, $mutations{$cut[4]});
  	foreach my $k(@vars){
  		$k =~ s/\)//;
  		my ($type, $mut)=split (/\(/, $k);
  		if ($type eq "single resistance variant" || $type eq "nonsense mutation"){
	  		my $alt = $2 if ($mut =~ /([A-Za-z]+)([0-9]+)([A-Za-z]+)/) ; 
	  		my $aa = $3 ;  
			  if ($alt >= $start && $alt <= $end){
			  	for(my $i = $alt; $i <= $alt+$count; $i++){
			  		my $subject = substr($align_subject, 0, $i-$start+1);
			  		$n=$subject=~s/\-//g;
			  		my $alt_new = $i-$n;  
#			  		last if ($alt == $alt_new);  
						if ($alt == $alt_new){
							my $len = ($alt - $start + 1) + $n ;
							$ha{$cut[4]} = $len;
#							print "single: $cut[4]...$count...$i...$start...$n...$alt...$alt_new...$len\n";
							last ;
						}
			  	}
			    $pos = $ha{$cut[4]} ;  #print "$cut[4]...$mut...$pos\n";
			    my $str = substr($align_seq, $pos-1, 1); 
			    if ($aa eq $str){ $index = 1;push @{$parameter{$cut[0]}}, $mut; }else{$index = 0; }
			    $count{$cut[0]}+=$index;
			    #print "$cut[0]...$cut[4]...$pos...$k...$1..$aa...$str\t$index\n";
			  }
		  }elsif($type eq "multiple resistance variants"){
		  	my @all = split (/\,/, $mut);
		  	my $num = @all ;
		  	my $sign = 0 ;
		  	foreach my $key(@all){
		  		next if ($key=~/\W+/);
		  		my $alt = $2 if ($key =~ /([A-Za-z]+)([0-9]+)([A-Za-z]+)/) ; 
		  		my $aa = $3 ; 
		  		if ($alt >= $start && $alt <= $end){
		  			for(my $i = $alt; $i <= $alt+$count; $i++){
			  			my $subject = substr($align_subject, 0, $i-$start+1);
			  			$n=$subject=~s/\-//g;
			  			my $alt_new = $i-$n;  
#			  			last if ($alt == $alt_new);  
							if ($alt == $alt_new){
								my $len = ($alt - $start + 1 ) + $n ;
								$ha{$cut[4]} = $len;
#								print "multiple: $cut[4]...$count...$i...$start...$n...$alt...$alt_new...$len\n";
								last ;
							}
			  		}
			  		$pos = $ha{$cut[4]} ; 
			  		my $str = substr($align_seq, $pos-1, 1);
			  		my $str1 = substr($align_subject, $pos-1, 1);
		  			if ($aa eq $str){$sign++;}
		  		}
		  	}
		  	if ($sign == $num){$index = 1; push @{$parameter{$cut[0]}}, $mut;}else{$index = 0 ;}
		  	$count{$cut[0]}+=$index;
		  }elsif($type eq "frameshift mutation"){
		  	 my $alt = $2 if ($mut =~ /([A-Za-z]+)([0-9]+)([A-Za-z]+)/) ; 
		  	 if ($alt >= $start && $alt <= $end){
			  	 for(my $i = $alt; $i <= $alt+$count; $i++){
			  		 my $subject = substr($align_subject, 0, $i-$start+1);
			  		 $n=$subject=~s/\-//g;
			  		 my $alt_new = $i-$n;   
						 if ($alt == $alt_new){
							 my $len = ($alt - $start + 1) + $n ;
							 $ha{$cut[4]} = $len;
#							 print "single: $cut[4]...$count...$i...$start...$n...$alt...$alt_new...$len\n";
							 last ;
						 }
			  	 }
			  	$pos = $ha{$cut[4]} ;  
			  	my $str_q = substr($align_seq, 0, $pos); 
			  	my $str_s = substr($align_subject, 0, $pos); 
			  	$str_q=~s/\-//g; $str_s=~s/\-//g;
		  	  my $qlen = length $str_q ;
		  	  my $slen = length $str_s ;
		  	  my $indel = abs ($qlen - $slen);
		  	 ###
		  	 if (($indel%3) == 0 ){$index = 0;}else{$index = 1; push @{$parameter{$cut[0]}}, $mut;}
		  	 $count{$cut[0]}+=$index;
		   }
		 }
	 }
	 if (exists $count{$cut[0]}){
		  if(exists $hash_id{$cut[4]} && $count{$cut[0]} > 0){
				print OUT1 "$cut[0]\t$cut[4]\t$cut[8]\t$cut[13]\t$cut[12]\t$hash_id{$cut[4]}\n";
			}
			if (exists $hash_id{$cut[4]} && $cut[11]*100/$q_len >= $coverage && $count{$cut[0]} > 0 && $cut[8] >= $identity){
				my $para = join (";", @{$parameter{$cut[0]}});
				my ($name, $gene, $drug, $resistance, $model, $des)=split(/\t/, $hash_id{$cut[4]});
				print OUT3 "$cut[0]\t$cut[4]\t$cut[8]\t$cut[13]\t$cut[12]\t$name\t$gene\t$drug\t$resistance\t$model\t$para\t$des\n";
			}
		}
	}else{
			if(exists $hash_id{$cut[4]}){
				print OUT1 "$cut[0]\t$cut[4]\t$cut[8]\t$cut[13]\t$cut[12]\t$hash_id{$cut[4]}\n";
			}
			if (exists $hash_id{$cut[4]} && $cut[11]*100/$q_len >= $coverage && $cut[8] >= $identity){
				print OUT2 "$cut[0]\t$cut[4]\t$cut[8]\t$cut[13]\t$cut[12]\t$hash_id{$cut[4]}\n";
			}
	}
}
close INR;
