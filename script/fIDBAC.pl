#!/usr/bin/perl -w
#author:liangq at 20181126 ,modified by liangqian ,at 20181206
use strict ;
use Getopt::Long ;
use Cwd 'abs_path';
use File::Basename ;
use File::Path 'mkpath';
use FindBin '$Bin';
use Data::Dumper;
use List::Util qw/max min/;
use lib $Bin;
use threads;
use GACP qw(parse_config);

sub usage {
	print STDERR << "USAGE";
description: Species identification and MLST classification for the submit genome file
usage: perl $0 [<options>]
options:
   -input   input genome FASTA files to process
   -outdir  output dir, default current
   -evalue  expectation value, default is 1e-5, only active when blobtools needed
   -taxdump taxonomy infomation path, only active when blobtools needed
   -ANI     ANI value, default is 95 of percent 
   -AF      AF value, default is 0.6
   -type    list of type strain
   -help|?  print help information
   -run     Run Type; local or qsub ,default local

e.g.:
	perl $0 -input sample.fasta -evalue 1e-5 -outdir . -temp temp
		
USAGE
	exit 0;
}

usage() if(@ARGV<1);

my ($input, $outdir, $evalue, $taxdump, $ANI, $AF, $type,$tempdir);
GetOptions(
	"input:s" =>\$input,	
	"outdir:s"=>\$outdir,
	"evalue:s"=>\$evalue,
	"taxdump:s" =>\$taxdump,
	"type:s"=>\$type,
        "temp:s"=>\$tempdir,
);

### the default parameter
$evalue = 1e-5 if (!defined $evalue);
$outdir ||= ".";
$outdir = abs_path($outdir) ;
my $config_file = "$Bin/config_db.txt";
#
my $python3=parse_config($config_file,"python3");
$taxdump ||=parse_config($config_file,"taxdump");
my $kmerdb||=parse_config($config_file,"kmerdb");
$type ||= parse_config($config_file,"type");
my $rename=parse_config($config_file,"rename");
my $pubMLSTdb = parse_config($config_file,"pubMLSTdb");
my $pubMLST_list = parse_config($config_file,"pubMLST_list");
my $ANIcalculator = parse_config($config_file,"ANIcalculator");
my $orthoANI= parse_config($config_file,"orthoANI");
my $LPSN = parse_config($config_file,"LPSN");
my $blast = parse_config($config_file,"blast");
my $kmerfinder = parse_config($config_file,"kmerfinder");
my $prokka = parse_config($config_file,"prokka");


my %rename = (
   "Clostridioides_difficile"=>"Clostridium_difficile",
   "Mycobacteroides_abscessus"=>"Mycobacterium_massiliense",
     "Brucella_abortus"=>"Brucella_spp.",
   "Brucella_canis"=>"Brucella_spp.",
   "Brucella_ceti"=>"Brucella_spp.",
   "Brucella_inopinata"=>"Brucella_spp.",
   "Brucella_melitensis"=>"Brucella_spp.",
   "Brucella_microti"=>"Brucella_spp.",
   "Brucella_neotomae"=>"Brucella_spp.",
   "Brucella_ovis"=>"Brucella_spp.",
   "Brucella_suis"=>"Brucella_spp.",
   "Brucella_vulpis"=>"Brucella_spp.",
   "Brucella_pinnipedialis"=>"Brucella_spp.",
);

my %typename = (
		"Clostridium difficile" =>"Clostridioides difficile",
		"Bacillus difficilis" =>"Clostridioides difficile",
		"Peptoclostridium difficile" =>"Clostridioides difficile",
		"Propionibacterium acnes" =>"Cutibacterium acnes",
		"Corynebacterium acnes" =>"Cutibacterium acnes",
		"Bacillus acnes"=>"Cutibacterium acnes",

);

open RE,"<$rename" or die $!;
while(<RE>){
	chomp;
	my @cut=split /\t/,$_;
	$typename{$cut[1]}=$cut[0];
}
close RE;

my $time = `date +'\%Y-\%m-\%d \%H:\%M:\%S'`;
print STDERR "start at $time \n";
$time =~ s/\s+/\_/g; $time =~ s/\-/\_/g; $time =~ s/\:/\_/g; $time =~ s/\_$//; 

my (%hash, %tmp,%types, %typesgene) ;
&STRAIN($type,\%types,\%typesgene);
&pubMLST($pubMLST_list, \%hash) ;

my $sample = basename $input ;
	$sample =~ s/\.fa$//; $sample =~ s/\.fas$//; $sample =~ s/\.fasta$//; $sample =~ s/\.fna$//; $sample =~ s/\.ffn$//;

$input = abs_path ($input);

my $tempfile = "$tempdir/${sample}_${time}";
my $result = "$outdir/${sample}_${time}" ;
mkpath "$result" if (!-d "$result");
mkpath "$tempfile" if (!-d "$tempfile");
 $result=abs_path($result);$tempfile=abs_path($tempfile);
  open KMER, ">$tempfile/kmerfinder.sh" or die ;
 print KMER "$kmerfinder -i $input -t $kmerdb -o $result/$sample.out.txt -x ATGAC \n";
  
system ("sh $tempfile/kmerfinder.sh >$tempfile/kmerfinder.sh.o 2>$tempfile/kmerfinder.sh.e");

open PROKKA, ">$tempfile/prokka.sh" or die;
print PROKKA "perl $Bin/rename_fa.pl $input >$tempfile/$sample.fa 2>$tempfile/Rename_fasta.id\n";
print PROKKA "$prokka $tempfile/$sample.fa --outdir $tempfile/prokka --kingdom Bacteria --prefix $sample\n";
print PROKKA "perl $Bin/rename_gene.pl $tempfile/prokka/$sample.gff $tempfile/prokka/$sample.faa $result/$sample.protein.fa $tempfile/Rename_fasta.id\n";
print PROKKA "perl $Bin/rename_gene.pl $tempfile/prokka/$sample.gff $tempfile/prokka/$sample.ffn $result/$sample.gene.fa $tempfile/Rename_fasta.id\n";

 system ("sh $tempfile/prokka.sh >$tempfile/prokka.sh.o 2>$tempfile/prokka.sh.e");
 system ("perl $Bin/get_genes_stats.pl -unigene $tempfile/prokka/$sample.ffn -genome $input -out $result/Genes_Stats.xls");
close PROKKA;

system ("$python3 $Bin/select_16S.fa.py  $tempfile/prokka/$sample.ffn $tempfile/$sample.16S.fa");
system("perl $Bin/select_kmerfinder_16SAndANI.pl -query $input  -in $result/$sample.out.txt -16S $tempfile/$sample.16S.fa -outdir $result");

my $sign;
my $template=`head -n 1  $result/fastANISpecies`;chomp $template; 
my $name;
if (exists $typename{$template}){
	$name = $typename{$template} ;
}else{
	$name = $template ;
}
		
print STDERR "$name...$template...\n";


print STDERR "[gANI] at $time \n";
my $tt=0;
  if (exists $types{$name}){	
	       my $genomelst=$types{$name};
	       open ANI1,">$tempfile/orthoAni.sh" or die $!;
	       print ANI1 "$python3 $Bin/OrthoANI.all_tre.new.py \"$genomelst\" $input $result $tempfile\n";
		system("sh $tempfile/orthoAni.sh >$tempfile/orthoAni.sh.o 2>$tempfile/orthoAni.sh.e");
               open ANI,">$tempfile/gani.sh" or die $!;
 		 my @genes = split ( "\;", $typesgene{$name});
  	 foreach my $gene(@genes){
			$tt++;
  			my $prefix = basename $gene ;
			print ANI "$ANIcalculator -genome1fna $tempfile/prokka/$sample.ffn -genome2fna $gene -outfile $tempfile/$prefix.ANIcalculator.txt -outdir $tempfile/ani$tt >$tempfile/ANIcalculator.runlog 2>$tempfile/ANIcalculator.err\n";
  			#system ("$ANIcalculator -genome1fna $tempfile/prokka/$sample.ffn -genome2fna $gene -outfile $tempfile/$prefix.ANIcalculator.txt -outdir $tempfile >$tempfile/ANIcalculator.runlog 2>$tempfile/ANIcalculator.err");
 		 }
  	close ANI;
	system("perl $Bin/multi-process.pl -cpu 6 $tempfile/gani.sh >$tempfile/gani.sh.o 2>$tempfile/gani.sh.e ");
  	open ALLANI, ">$result/ANIcalculator.all.txt" or die $!;
  	print ALLANI "GENOME1\tGENOME2\tANI(1->2)\tANI(2->1)\tAF(1->2)\tAF(2->1)\n";
 	  my $ani ;
  	my @anis = glob ("$tempfile/*.ANIcalculator.txt");  
  	$sign = ANI (@anis);
  	close ALLANI ;
  }else{
  	$sign = 0 ;#may be error
        
  }

system("$python3 $Bin/merge.ani.py $result/ANI.all.txt $result/ANIcalculator.all.txt $result/merge.ani.txt $sample");

#if($sign == 0){
   open TAX, ">$result/Taxonomy.txt" or die ;
   open TAXIN, "$LPSN" or die ;
   my %tax ;
   while (<TAXIN>){
        chomp;
        my @cut = split (/\t/, $_);
        my @l=split(/\;/, $cut[1]) ;
        my $species = pop @l ;
        my $taxonomy = join(";", @l);
        $species=~s/\_/ /g;
        if ($species eq $name){
             print TAX "$name\t$taxonomy\n";
        }else{
            #print "there is not exists this species in the Taxonomylist\n";
        }
  }
  close TAXIN ;
  close TAX ;
#}
 #if($sign eq "Low ANI"){
#	system("echo 'The gANI is less than 96.5 or AF is less than 0.6 ,pleack check the genome sequence,it may be polluted!' >$result/LowANIWarnings.txt");	
# }

  
my ($species, $flag) = split (/\t/, MLST ($template));
 if ($flag == 0){
      my $mlstlist = glob "$pubMLSTdb/$species/*.txt" ;
      system("perl $Bin/run_MLST.pipeline.pl -s $species -t $mlstlist -q $input -o $result \n");
  }else{
      print STDERR "This species is not exists in the pubMLST db\n";
} 


#### AR VF annot#####
print STDERR "[AR VF annot] at $time \n";
system("perl $Bin/AR_VF.run.pl -input $result/$sample.protein.fa -intype gene -anatype all  -outdir $result -temp $tempfile");

### snp MST ############
my $flag_snp=&flag_snpdata($name);
print "$name:flag_snp:$flag_snp\n";
if($flag_snp==1){
	print STDERR "[SNP and MST] at $time \n";
	`mkdir -m 755 -p $result/closest_snp` unless (-d "$result/closest_snp");
	system("perl $Bin/closest_snp.pl -infa $input -species '$name' -outdir $result/closest_snp -prefix Your_Sequences");
	system("perl $Bin/rename_snp.fa.pl $result/closest_snp/snp.top10.fa $result/closest_snp/rename.txt >$result/closest_snp/snp.top10.rename.fa");
	system("sh $Bin/MST/run.sh $result/closest_snp/snp.top10.rename.fa $result fasta");	
}


my $mome = `date +'\%Y-\%m-\%d \%H:\%M:\%S'`;
print STDERR "final at $mome \n";

print $result;
	
 	


############### sub ##############
sub pubMLST{
	my ($file,$hash)=@_;
	open LIST, "$file" or die ;
	while (<LIST>){
		chomp;
		my $species = (split /\t/, $_)[0];
		$$hash{$species} = 1 ;
		}
	close LIST ;
}

sub MLST{
	my $name = shift ;
	my $flag = 0 ;
	my $species ;
	$name =~ s/\s+/\_/g ;
	my $id1 = (split "\_", $name)[0];
	if ($name=~m/sp\./){$name = "$id1.spp.";}
	if (exists $rename{$name}){
		$species = $rename{$name} ;
	}else{
		$species = $name ;
	}
	if (!exists $hash{$species}){
		$flag = 1;
	}else{
		$flag = 0;
	}
	my $ol="$species\t$flag";
	return $ol ;
}

sub flag_snpdata {
	my $sp=shift @_;
	my $flag=0;	
	open IN,"<$Bin/snpdata.config" or die $!;
	while(<IN>){
		chomp;
		my @cut=split /\t/,$_;
		if($sp eq $cut[0]){
			$flag=1;
			last;
		}
	}
	close IN;
	return $flag;
}			
sub STRAIN{
	my ($file, $hash,$hash2) = @_ ;
	open IN, "$file" or die $! ; 
	my $head = <IN>; chomp $head;
	while (<IN>){
		chomp ;
		my @cut = split (/\t/, $_);
		my $genome = $cut[3] ;
		my $gene = $cut[4] ;
                if (!exists($$hash{$cut[1]})){
                $$hash{$cut[1]}=$genome ;
                }else{
                  my $ge1=$$hash{$cut[1]};
                  my $ge2="$genome;$ge1";
                  $$hash{$cut[1]}=$ge2;
                }

		if (!exists($$hash2{$cut[1]})){
		$$hash2{$cut[1]}=$gene ;
		}else{
			my $gene1=$$hash2{$cut[1]};
		  my $gene2="$gene;$gene1";
		  $$hash2{$cut[1]}=$gene2;
		}
	}
	close IN ;
}

sub ANI{
	my @as = @_ ;
	my ($ani, $exit, @ani1, @ani2, @af1, @af2) ;
	foreach my $as(@as){
		open IN, "$as" or die $! ;
		my $head = <IN>; chomp $head ;
		while (<IN>){
			chomp ;
			my @cut = split ;
			push @ani1, $cut[2] ;
			push @ani2, $cut[3] ;
			push @af1, $cut[4] ;
			push @af2, $cut[5] ;
			$ani .= "$_\n";
		}
	}
	print ALLANI "$ani\n";
	my $maxani1 = max @ani1 ;
	my $maxani2 = max @ani2 ;
	my $maxaf1 = max @af1 ;
	my $maxaf2 = max @af2 ;
	if ($maxani1 >= $ANI && $maxani2 >= $ANI && $maxaf1 >= $AF && $maxaf2 >= $AF){
		$exit = 0 ;
	}else{
		$exit = 1 ;# "LOW ANI"
	}
	return $exit ;
	close IN ;
}

sub digit{
	my $name = shift ;
	my $num = shift ;
	my @l=split(/\s+/, $name);
	my $key ; my @temp ;
	for(my $i = 0; $i < $num; $i++){
		my $id=$l[$i];
		push (@temp, $id);
	}
	$key = join(" ", @temp);
  return $key;	
}

