#!usr/bin/perl
use strict ;
#author : modified  by liangqian  at 20181206
use Getopt::Long ;
my ($indir);
GetOptions(
	"indir:s"=>\$indir,
);	
usageall()if(!defined $indir);
sub usageall{
	die qq/
	perl $0 -indir <>
\n/;
}

#########
my (%ha,@samples);
my $top10 = "$indir/rename.txt" ;
my ($target,%rename) ;
open IN ,"$top10" or die ;
my $count =0 ;
while (<IN>){
	chomp ;
	my @l = split (/\t/,$_) ;
	if ($count ==0 ){
		$target = $l[1] ;
		$rename{$l[0]} = $l[1] ;
	}
	$rename{$l[0]} = $l[1] ;
	$count++ ;
}
close IN ;


my $line ;
my $tre = "$indir/4" ;
open IN,"$tre" or die ;
while (<IN>) {
	chomp ;
	$line .= $_ ;
}
close IN ;
$line =~ s/\;// ;
my @l = split (/\(|\,/,$line) ;
my $count ;
my $i ;for ($i=0;$i<=@l-1;$i++){
       #print "a\t$l[$i]-----\n";
	if ($l[$i] eq "") {
		$count++ ;
	}else{
	my @tmps = split (/\:/,$l[$i]) ;
	my $sample = $tmps[0] ; 
	$ha{$sample}{f} = $count ;
        #print "b\t$sample\t$count--------\n";
	push (@samples,$sample) ;
	
	}
}
my $countr =0  ;
my @m = split (/\)|\,/,$line) ;
my $i ;for ($i=0;$i<=@m-1;$i++){
        #print "c\t$m[$i]----\n";
	if ($m[$i] =~ /^:/){
		$countr++ ;
	}else{
		my @tmps = split (/\:/,$m[$i]) ; 
		my $sample = $tmps[0] ; $sample =~ s/\(//g ;
		$ha{$sample}{r} = $countr ;
		#print "d\t$sample\t$countr--------\n";
	}

}

my $max =0 ;

foreach my $sample (@samples){
	my $tmps = $ha{$sample}{f} >$ha{$sample}{r} ? ($ha{$sample}{f} -  $ha{$sample}{r}): ($ha{$sample}{r} -  $ha{$sample}{f}) ;
	if ($max <$tmps) {
		$max = $tmps ;
	}else{
		
	}
}


print "$max\n";

my $subx = 80 ; 
my $suby = 40 ;
my $sample_num = @samples ;
my $svg ;
my $W=$max*$subx ;
my $H=$sample_num*$suby;
my ($edgeTop,$edgeBottom,$edgeLeft,$edgeRight) = (60,80,60,200);
my $width=$W+$edgeLeft+$edgeRight;
my $height=$H+$edgeTop+$edgeBottom;
$svg .=<<SVG;# code
<?xml version="1.0" encoding="utf-8" ?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg width="$width" height="$height" version="1.1" xmlns="http://www.w3.org/2000/svg">
SVG

my @l = split (/\(|\)|\,/,$line) ;@l = grep{$_} @l ;@l=grep(/[^;]/,@l); 
my $sample_count = 0 ;
my $shuzhicount = 0; 
my @shuzhis ;
my $i ;for ($i=0;$i<=@l-1 ; $i++){
	#print "***$l[$i]***\n" ;
	if ($l[$i] !~ /^:/){
		my @tmps = split (/\:/,$l[$i]) ; 
		my $sample = $tmps[0] ;
		$shuzhicount++ ;
		push (@shuzhis,$shuzhicount) ;
 		print "$max\t$sample\t$ha{$sample}{f}\t$ha{$sample}{r}\n";
                my $diff = $ha{$sample}{f} >$ha{$sample}{r} ? ($ha{$sample}{f} -  $ha{$sample}{r}): ($ha{$sample}{r} -  $ha{$sample}{f}) ;
		my $diff2=$max-$diff;
		$ha{$shuzhicount}{x1} = $edgeLeft+($diff-1)*$subx ; $ha{$shuzhicount}{x2} = $ha{$shuzhicount}{x1}+$subx ;
		$ha{$shuzhicount}{y1} = $edgeTop+$sample_count*$suby;  $ha{$shuzhicount}{y2} = $ha{$shuzhicount}{y1} ;
		$svg .= "<path stroke=\"#26a67a\" stroke-width=\"2\" d=\"M$ha{$shuzhicount}{x1} $ha{$shuzhicount}{y1} L$ha{$shuzhicount}{x2} $ha{$shuzhicount}{y2} \" />\n";
                if($diff2>0){
 		 $ha{$shuzhicount}{x3}=$ha{$shuzhicount}{x2}+$diff2*$subx;$ha{$shuzhicount}{y3}=$ha{$shuzhicount}{y2};
 		 $svg .= "<path stroke=\"#26a67a\" stroke-width=\"2\" stroke-dasharray=\"5,5\" d=\"M$ha{$shuzhicount}{x2} $ha{$shuzhicount}{y2} L$ha{$shuzhicount}{x3} $ha{$shuzhicount}{y3}\"/>\n";
		}
		my $name = $rename{$sample} ; 
		
		my $col = "black" ;
		my $x_yrxt = $ha{$shuzhicount}{x2}+8 ;
                my $y_yrxt = $ha{$shuzhicount}{y2}+4 ;
	   	$x_yrxt = $ha{$shuzhicount}{x3}+8 if(exists $ha{$shuzhicount}{x3});
		$y_yrxt = $ha{$shuzhicount}{y3}+8 if(exists $ha{$shuzhicount}{y3});
		if ($name eq $target ){
                        $col = "red" ;
			$x_yrxt=$x_yrxt+4;
			my $x1=$x_yrxt-6;my $y1=$y_yrxt-14;my $x2=$x1-5;my $y2=$y_yrxt-4;my $x3=$x1+5;my $y3=$y2;
			$svg .= "<path style=\"fill:red;stroke:none;stroke-width:0\" d=\"M$x1 $y1 L$x2 $y2 L$x3 $y3 Z\" />\n";
			#print "<path style=\"fill:red;stroke:none;stroke-width:0\" d=\"M$x1 $y1 L$x2 $y2 L$x3 $y3 Z\" />\n";
			$x_yrxt=$x_yrxt+4;
			$y_yrxt =$y_yrxt-2;
			my $text_name="Your Sequence";
			$svg .= "<text fill=\"$col\" font-family=\"Arial\" font-size=\"14.00\" stroke=\"none\" text-anchor=\"start\" x=\"$x_yrxt\" y=\"$y_yrxt\">$text_name</text>\n" ;
                }else{
			$svg .= "<text fill=\"$col\" font-family=\"Arial\" font-size=\"14.00\" stroke=\"none\" text-anchor=\"start\" x=\"$x_yrxt\" y=\"$y_yrxt\">$name</text>\n" ;
		}
		$sample_count++ ;
#		print "shuzhicount:$shuzhicount\nshuzhis:@shuzhis\n" ;
	}else{
		my $shuzhitmp1 = pop @shuzhis ;
		my $shuzhitmp2	= $shuzhis[-1] ;
#		print "###$shuzhitmp1\t$shuzhitmp2###\n" ;
#		$svg .= "<line stroke=\"#26a67a\" stroke-width=\"4\" x1=\"$ha{$shuzhitmp1}{x1}\" x2=\"$ha{$shuzhitmp2}{x1}\" y1=\"$ha{$shuzhitmp1}{y1}\" y2=\"$ha{$shuzhitmp2}{y1}\" />\n";
		$svg .= "<path stroke=\"#26a67a\" stroke-width=\"2\" d=\"M$ha{$shuzhitmp1}{x2} $ha{$shuzhitmp1}{y2}  L$ha{$shuzhitmp1}{x1} $ha{$shuzhitmp1}{y1} L$ha{$shuzhitmp2}{x1} $ha{$shuzhitmp2}{y1} L$ha{$shuzhitmp2}{x2} $ha{$shuzhitmp2}{y2}\"  fill=\"none\"/>\n";
		#$svg .= "<path stroke=\"none\" stroke-width=\"1\" d=\"M$ha{$shuzhitmp1}{x2} $ha{$shuzhitmp1}{y2}  V$ha{$shuzhitmp1}{x1}  H$ha{$shuzhitmp2}{y1} \" />\n";

		 $ha{$shuzhis[-1]}{x2} = $ha{$shuzhis[-1]}{x1};
		$ha{$shuzhis[-1]}{x1} =  $ha{$shuzhis[-1]}{x1} - $subx ;
		$ha{$shuzhis[-1]}{y1} = $ha{$shuzhitmp2}{y1}+($ha{$shuzhitmp1}{y1}-$ha{$shuzhitmp2}{y1})/2;  $ha{$shuzhis[-1]}{y2} = $ha{$shuzhis[-1]}{y1} ;
#		$svg .= "<line stroke=\"#26a67a\" stroke-width=\"4\" x1=\"$ha{$shuzhis[-1]}{x1}\" x2=\"$ha{$shuzhis[-1]}{x2}\" y1=\"$ha{$shuzhis[-1]}{y1}\" y2=\"$ha{$shuzhis[-1]}{y2}\" />\n";
		$svg .= "<path stroke=\"#26a67a\" stroke-width=\"2\"  d=\"M$ha{$shuzhis[-1]}{x1} $ha{$shuzhis[-1]}{y1}  L$ha{$shuzhis[-1]}{x2} $ha{$shuzhis[-1]}{y2} \" />\n";
		
			
	}


}
	my $shuzhitmp1 = pop @shuzhis ;
	my $shuzhitmp2  = $shuzhis[-1] ;
#	$svg .= "<line stroke=\"#26a67a\" stroke-width=\"4\" x1=\"$ha{$shuzhitmp1}{x1}\" x2=\"$ha{$shuzhitmp2}{x1}\" y1=\"$ha{$shuzhitmp1}{y1}\" y2=\"$ha{$shuzhitmp2}{y1}\" />\n";
	$svg .= "<path stroke=\"#26a67a\" stroke-width=\"2\" d=\"M$ha{$shuzhitmp1}{x2} $ha{$shuzhitmp1}{y2}  L$ha{$shuzhitmp1}{x1} $ha{$shuzhitmp1}{y1} L$ha{$shuzhitmp2}{x1} $ha{$shuzhitmp2}{y1} L$ha{$shuzhitmp2}{x2} $ha{$shuzhitmp2}{y2}\"  fill=\"none\"/>\n";

	$ha{$shuzhis[-1]}{x2} = $ha{$shuzhis[-1]}{x1};
	$ha{$shuzhis[-1]}{x1} =  $ha{$shuzhis[-1]}{x1} - $subx/2 ;
	$ha{$shuzhis[-1]}{y1} = $ha{$shuzhitmp2}{y1}+($ha{$shuzhitmp1}{y1}-$ha{$shuzhitmp2}{y1})/2;  $ha{$shuzhis[-1]}{y2} = $ha{$shuzhis[-1]}{y1} ;
	$svg .= "<line stroke=\"#26a67a\" stroke-width=\"2\" x1=\"$ha{$shuzhis[-1]}{x1}\" x2=\"$ha{$shuzhis[-1]}{x2}\" y1=\"$ha{$shuzhis[-1]}{y1}\" y2=\"$ha{$shuzhis[-1]}{y2}\" />\n";

#	print "final :@shuzhis\n" ;

open OUT, ">$indir/closeclosest_snp_tre.svg" or die ;
print OUT "$svg\n" ;
print OUT "</svg>\n" ;
close OUT ;

