#!/usr/bin/perl -w
#author: liangqian at 20190617
use strict;
use Getopt::Long;
use Cwd 'abs_path';
use File::Basename ;
use FindBin '$Bin';
use GACP qw(parse_config);
my ($query,$in,$outdir,$type,$cutoff,$q_16S,$db_16);

GetOptions(
        "query:s"=>\$query,
	"in:s"=>\$in,
	"16S:s"=>\$q_16S,
	"outdir:s"=>\$outdir,
	"type:s"=>\$type,
	"db_16:s"=>\$db_16,
	"cutoff:s"=>\$cutoff,
);

if (!defined $query || !defined $in || !defined $outdir){
	print "author:liangqian \nusage :perl $0 -query input.fa -in kmerfinder's result(without -w) -16S input.16S.fa -outdir\n";
	exit 1;
}
my $config_file = "$Bin/config_db.txt";
#
#
my $fastANI=parse_config($config_file,"fastANI");
$type = parse_config($config_file,"type");
my $rename=parse_config($config_file,"rename");
$db_16 =parse_config($config_file,"db_16");
my $blastn=parse_config($config_file,"blastn");
$cutoff||=95;
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
        my @li=(split /\s+/,$temp[-1],3)[0,1];
        my $sp=join " ",@li; $sp=~s/\[//g;$sp=~s/\]//g;
        #print $sp."\n";
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


if(defined $q_16S){
	system("$blastn -query $q_16S -db $db_16 -outfmt 6 -evalue 1e-5 -max_target_seqs 30 -num_threads 8 -out $outdir/16S.blast.out");
	system("awk -F \"\t\" 'NR==FNR{a[\$1]=\$2;}NR>FNR{print \$0\"\t\"a[\$2]}' $db_16.des $outdir/16S.blast.out >$outdir/16S.blast.out.annot");
	open AN,"<$outdir/16S.blast.out.annot" or die $!;
	open OUT5,">$outdir/16S.top20.txt" or die $!;
	my %tag1;my %j;my %top20_16S;my %outtag;
       	while(<AN>){
		chomp;
		my @cut=split /\t/,$_;
		my @li=(split /\s+/,$cut[-1],3)[0,1];
	        my $sp=join " ",@li; $sp=~s/\[//g;$sp=~s/\]//g;
		if(!exists $tag1{$sp}){
               		$j{$cut[0]}++;
               		$tag1{$sp}=1;
        	}
		if($j{$cut[0]}<=20){
	        	if(!exists $top20_16S{$sp}){
	           	my $line=join ("\n",@{$typedir{$sp}}) if (exists $typedir{$sp});
            		$line.="\n".join ("\n",@{$typedir{$typename{$sp}}}) if (exists $typename{$sp} && !exists $top20_16S{$typename{$sp}} && exists $typedir{$typename{$sp}});
           		if(!exists $outtag{$line}){
				print OUT5 "$line\n";
				$outtag{$line}=1;
			}
            		$top20_16S{$sp}=1;
            		$top20_16S{$typename{$sp}}=1 if (exists $typename{$sp});
         		if(exists $synonym{$sp}){
                		my $temp_line='';
                		foreach my $temp_sp(@{$synonym{$sp}}){
                                $temp_line="\n".join("\n",@{$typedir{$temp_sp}}) if (exists $typedir{$temp_sp});
                        	}
				if(!exists $outtag{$temp_line}){
                       	 		print OUT5 $temp_line."\n";
					$outtag{$temp_line}=1;
				}
                	}
            		}
			
		}

		
	}
	close AN;
	`sed -i /^\$/d  $outdir/16S.top20.txt`;	
}

my $top20_file;
if(-e "$outdir/16S.top20.txt" ){
	`cat $outdir/top20.txt $outdir/16S.top20.txt |sort -u >$outdir/all.top20.txt`;
	$top20_file="$outdir/all.top20.txt";
}else{
	$top20_file="$outdir/top20.txt";
}

open OUT,">$outdir/fastANI.sh" or die $!;

open T,"<$top20_file" or die $!;
my @Tline=<T>;
close T;
for(my $i=0;$i<=$#Tline;$i++){
        chomp $Tline[$i];
        print OUT "$fastANI -q $query -r $Tline[$i] --fragLen 1000 -o $outdir/fastani.result.temp.$i\n";
}
close OUT;
system("sh $outdir/fastANI.sh >$outdir/fastANI.sh.o 2>$outdir/fastANI.sh.e");
system("cat $outdir/fastani.result.temp.* |sort -k3nr,3 >$outdir/fastani.result && rm $outdir/fastani.result.temp.*");


my ($gg,$ani)=(split /\t/,`head -n 1 $outdir/fastani.result`)[1,2];
my $species=$spname{$gg};
$species= $typename{$species} if(exists $typename{$species});
if($ani<$cutoff){
	system("echo 'The ANI is less than 95,pleack check the genome sequence,it may be polluted!' >$outdir/LowANIWarnings.txt");
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
