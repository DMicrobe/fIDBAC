#!/usr/bin/perl -w
#author: liangqian at 20190617
use strict;
use Getopt::Long;
use Cwd 'abs_path';
use File::Basename ;
use FindBin '$Bin';

my ($query,$in,$outdir,$type,$cutoff);
#my $in=shift;#kmerfinder result , no parameter  -w 
#my $outdir=shift;

GetOptions(
        "query:s"=>\$query,
	"in:s"=>\$in,
	"outdir:s"=>\$outdir,
	"type:s"=>\$type,
	"cutoff:s"=>\$cutoff,
);

my $fastANI="/sugon/Users/liangq/softwave/miniconda3/bin/fastANI";
$type ||= "/sugon/Database/Bacteria/Type/rename/type.dir.20190117.rename.list";
my $rename="/sugon/Database/Bacteria/Type/rename/equivalent";
$cutoff||=96.5;
my %typename;

open RE,"<$rename" or die $!;
my %synonym;
while(<RE>){
        chomp;
        my @cut=split /\t/,$_;
        $typename{$cut[1]}=$cut[0];
	push @{$synonym{$cut[0]}},$cut[1];
}
close RE;
`mkdir -m 755 -p $outdir` unless(-d "$outdir");
my (%typedir,%typegene,%spname);
&STRAIN($type,\%typedir,\%typegene,\%spname);
open IN,"<$in" or die $!;
<IN>;
my $i=0;
my (%tag,%top1,%top3,%top10,%top20);
open OUT1,">$outdir/top1.txt" or die $!;
open OUT2,">$outdir/top3.txt" or die $!;
open OUT3,">$outdir/top10.txt" or die $!;
open OUT4,">$outdir/top20.txt" or die $!;

while(<IN>){
	chomp;
        my @temp=split /\t/;
        my @li=(split /\s+/,$temp[9],3)[0,1];
        my $sp=join " ",@li; $sp=~s/\[//g;$sp=~s/\]//g;
        next if (!exists $typedir{$sp} && !exists $typename{$sp} && !exists $synonym{$sp});
        push  @{$typedir{$sp}},'' if (!exists $typedir{$sp});
        if(exists $typename{$sp}){
	push  @{$typedir{$typename{$sp}}},'' if (!exists $typedir{$typename{$sp}});
	}
        if(!exists $tag{$sp}){
               $i++;
               $tag{$sp}=1;
        }
        last if ($i>20);
        if($i==1){
           if(!exists $top1{$sp} ){
		my $line=join ("\n",@{$typedir{$sp}});
		$line.="\n".join ("\n",@{$typedir{$typename{$sp}}}) if (exists $typename{$sp} && !exists $top1{$typename{$sp}});
		print OUT1 "$line\n";
                 $top1{$sp}=1;
                $top1{$typename{$sp}}=1 if (exists $typename{$sp});
            if(exists $synonym{$sp}){
                my $temp_line='';
                foreach my $temp_sp(@{$synonym{$sp}}){
                        $temp_line="\n".join("\n",@{$typedir{$temp_sp}}) if (exists $typedir{$temp_sp});
                }
                 print OUT1 $temp_line."\n";
                }

               }
       }
      if($i<=3){
      	if(!exists $top3{$sp}){
            my $line=join ("\n",@{$typedir{$sp}});
	    $line.="\n".join ("\n",@{$typedir{$typename{$sp}}}) if (exists $typename{$sp} && !exists $top3{$typename{$sp}});
	    print OUT2 "$line\n";
            $top3{$sp}=1;
            $top3{$typename{$sp}}=1 if (exists $typename{$sp});
            if(exists $synonym{$sp}){
                my $temp_line='';
                foreach my $temp_sp(@{$synonym{$sp}}){
                        $temp_line="\n".join("\n",@{$typedir{$temp_sp}}) if (exists $typedir{$temp_sp});
                }
                 print OUT2 $temp_line."\n";
          	}

           }
       }
      if($i<=10){
      	if(!exists $top10{$sp}){
	  my $line=join ("\n",@{$typedir{$sp}});
	  $line.="\n".join ("\n",@{$typedir{$typename{$sp}}}) if (exists $typename{$sp} && !exists $top10{$typename{$sp}});
	   print OUT3 "$line\n"; 
           $top10{$sp}=1;
           $top10{$typename{$sp}}=1 if (exists $typename{$sp});
            if(exists $synonym{$sp}){
                my $temp_line='';
                foreach my $temp_sp(@{$synonym{$sp}}){
                        $temp_line="\n".join("\n",@{$typedir{$temp_sp}}) if (exists $typedir{$temp_sp});
                }
                 print OUT3 $temp_line."\n";
            }
	}
        }
      if($i<=20){
        if(!exists $top20{$sp}){
            my $line=join ("\n",@{$typedir{$sp}});
	    $line.="\n".join ("\n",@{$typedir{$typename{$sp}}}) if (exists $typename{$sp} && !exists $top20{$typename{$sp}});
	   print OUT4 "$line\n";
            $top20{$sp}=1;
            $top20{$typename{$sp}}=1 if (exists $typename{$sp});
	    if(exists $synonym{$sp}){
		my $temp_line='';
		foreach my $temp_sp(@{$synonym{$sp}}){
			$temp_line="\n".join("\n",@{$typedir{$temp_sp}}) if (exists $typedir{$temp_sp});
		}
		 print OUT4 $temp_line."\n";
	  }
          }
      }

}

close IN;
close OUT1;
close OUT2;
close OUT3;
close OUT4;
`sed -i /^\$/d  $outdir/top1.txt`;
`sed -i /^\$/d  $outdir/top3.txt`;
`sed -i /^\$/d  $outdir/top10.txt`;
`sed -i /^\$/d  $outdir/top20.txt`;
open OUT,">$outdir/fastANI.sh" or die $!;
print OUT "$fastANI -q $query --refList $outdir/top20.txt --fragLen 1000 -o $outdir/fastani.result\n";
close OUT;
system("sh $outdir/fastANI.sh >$outdir/fastANI.sh.o 2>$outdir/fastANI.sh.e");
my ($gg,$ani)=(split /\t/,`head -n 1 $outdir/fastani.result`)[1,2];
my $species=$spname{$gg};
$species= $typename{$species} if(exists $typename{$species});
if($ani<$cutoff){
	system("echo 'The ANI is less than 96.5,pleack check the genome sequence,it may be polluted!' >$outdir/LowANIWarnings.txt");
}

system("echo $species >$outdir/fastANISpecies");

sub STRAIN{
        my ($file, $hash, $gene,$name) = @_ ;
        open IN, "$file" or die $! ; 
        my $head = <IN>; chomp $head;
        while (<IN>){
                chomp ;
                my @cut = split (/\t/, $_);
		#print "$cut[1],$cut[3],$cut[4]\n";
		$cut[1]=~s/\[//g;$cut[1]=~s/\]//g;
		my $genome=$cut[3];
		$$name{$genome}=$cut[1];
		push @{$$hash{$cut[1]}},$genome;
                my $genefile = $cut[4] ;
                if (!exists ($$gene{$cut[1]})){
                $$gene{$cut[1]}=$genefile;
                }else{
                 my $gene1=$$gene{$cut[1]};
                  my $gene2="$genefile;$gene1";
                  $$gene{$cut[1]}=$gene2;
                }
        }
        close IN ;
}
