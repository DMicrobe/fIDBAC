#!/usr/bin/perl -w
#author :liangqian
use strict ;
use Getopt::Long ;
use Cwd 'abs_path';
use File::Basename ;
use File::Path 'mkpath';
use FindBin '$Bin';
use Data::Dumper;
use lib $Bin;
use GACP qw(parse_config);

use threads;

sub usage {
	print STDERR << "USAGE";
description: AR of VF gene predict for the submit genome file or gene file
author:liangqian
usage: perl $0 [<options>]
options:
   -input	input genome or gene FASTA files to process
   -intype	genome or gene
   -anatype	resistance gene,virulent factor,all [all]
   -evalue  expectation value, default is 1e-5
   -identity  identity, cutoff which less than, default 80
   -coverage alignment/query_length, cutoff which less than, default 80 
   -outdir  output dir, default current
   -help|?  print help information

e.g.:
	perl $0 -input genome.fasta -intype genome -anatype all  -outdir . -temp tempdir 

		
USAGE
	exit 0;
}

usage() if(@ARGV<1);

my ($input,$type1, $type2, $outdir, $evalue, $identity, $coverage, $run,$tempdir);
GetOptions(
        "input:s"=>\$input,
	"intype:s"=>\$type1,
	"anatype:s"=>\$type2,
	"outdir:s"=>\$outdir,
        "temp:s"=>\$tempdir,
	"evalue:s"=>\$evalue,
	"identity:s"=>\$identity,
	"coverage:s"=>\$coverage,
);

$outdir ||= ".";
$outdir = abs_path($outdir) ;
$tempdir ||= ".";
$tempdir = abs_path($tempdir) ;
$evalue ||= "1e-5";
$identity ||= "80";
$coverage ||= "60";
$type2 ||="all";

my $config_file = "$Bin/config_db.txt";
my $prokka = parse_config($config_file,"prokka");
my $VFDBdb = parse_config($config_file,"VFDBdb");
my $VFDBanno = parse_config($config_file,"VFDBanno");
my $blastn = parse_config($config_file,"blastn");
my $blastp = parse_config($config_file,"blastp");

my $time = `date +'\%Y-\%m-\%d \%H:\%M:\%S'`;
print "start at $time";
$time =~ s/\s+/\_/g; $time =~ s/\-/\_/g; $time =~ s/\:/\_/g; $time =~ s/\_$//;
my ($tempfile,  $result, $sample, $sign, $blast);
$input = abs_path($input);
$sample = basename $input ;
$sample =~ s/\.fa$//; $sample =~ s/\.fas$//; $sample =~ s/\.fasta$//; $sample =~ s/\.fna$//; $sample =~ s/\.ffn$//;
$tempfile = "$tempdir/AR_VF";
$result = "$outdir/AR_VF" ;
mkpath "$result" if (!-d "$result");
mkpath "$tempfile" if (!-d "$tempfile");

my $genefile;
if($type1 eq 'genome'){
      open PROKKA, ">$tempfile/run_prokka.sh" or die $! ; 
      my $max_length = LENGTH ($input) ;
      if ($max_length >= 20){
      	my $key = substr ($sample, 0, 15) ;
      	print PROKKA "perl $Bin/rename_fa.pl $input $key >$tempfile/$sample.rename.fa 2>$tempfile/Rename_fasta.id\n";
        print PROKKA "$prokka $tempfile/$sample.rename.fa --outdir $tempfile/predict --prefix $sample \n";
        print PROKKA "perl $Bin/rename_gene.pl $tempfile/predict/$sample.gff $tempfile/predict/$sample.faa $result/$sample.protein.fa $tempfile/Rename_fasta.id\n";
	print PROKKA "perl $Bin/rename_gene.pl $tempfile/predict/$sample.gff $tempfile/predict/$sample.ffn $result/$sample.gene.fa $tempfile/Rename_fasta.id\n";

	
      }else{
        print PROKKA "$prokka $input --outdir $tempfile/predict --prefix $sample\n";
      print PROKKA "perl $Bin/rename_gene.pl $tempfile/predict/$sample.gff $tempfile/predict/$sample.faa $result/$sample.protein.fa\n";
      print PROKKA "perl $Bin/rename_gene.pl $tempfile/predict/$sample.gff $tempfile/predict/$sample.ffn $result/$sample.gene.fa\n";

      }
 
      close PROKKA ; 
      system ("sh $tempfile/run_prokka.sh >$tempfile/run_prokka.sh.o 2>$tempfile/run_prokka.sh.e");
     $genefile="$result/$sample.protein.fa";
} 

if($type1 eq 'gene'){ 
	$genefile=$input;
}
my $blastall;
my $flag = FLAG ($genefile);
my ($blastag,$blast_VF,$identity_VF,$coverage_VF);
if ($flag eq "gene"){
	system ("perl $Bin/cds2aa.pl $genefile >$tempfile/protein.fa");
	$genefile="$tempfile/protein.fa";

}
	
$blastall=$blastp;
$blast_VF=$blastp;
$identity = "90";
$coverage="80";
$identity_VF="90";
$coverage_VF="80";


open RUN,">$tempfile/run.sh" or die $!;
if($type2 eq 'resistance gene' or $type2 eq 'all'){
        print RUN "#ar\ndate\n";
	print RUN "sh $Bin/run_rgi.sh $genefile $result\n";
      }
if($type2 eq 'virulent factor' or $type2 eq 'all'){
      print RUN "#vf\ndate\n";
      print RUN  "$blast_VF  -evalue $evalue -outfmt 6 -db $VFDBdb -query $genefile -num_threads 8 -out $tempfile/$sample.VFDB.blast\n";
      print RUN "perl $Bin/get_VFDBannot_info.$flag.pl -identity $identity_VF -coverage $coverage_VF  -q $genefile -input $tempfile/$sample.VFDB.blast  -id $VFDBanno -out $result/$sample.VFDB\n";
      close RUN ;
}

close RUN;
system ("sh $tempfile/run.sh >$tempfile/run.sh.o 2>$tempfile/run.sh.e");

print "$result";

sub FLAG{
        my $file = shift ; 
        my $flag ;
        open IN,"$file" or die ;
        $/=">";<IN>;
        while (<IN>){
                chomp ;
                my ($tag, $seq)= split /\n/,$_,2 ;
    $seq=~s/\W+//g;
    $seq= uc $seq; 
    if ($seq=~/E/ || $seq=~/F/ || $seq=~/L/ || $seq=~/I/|| $seq=~/Q/ || $seq=~/P/){
        $flag = "protein";
    }else{
        $flag = "gene";
    }
        }
        return $flag ;
        close IN ;
}



sub LENGTH{
        my $file = shift ;
        my $max = 0 ; 
        my $i = 0 ;
        my $total_length ;
        my $GC ;
        open IN,"$file" or die ;
        $/=">";<IN>;
        while (<IN>){
                chomp ;
                my ($tag, $seq)= split /\n/,$_,2 ;
    my $length = length $tag ;
          if ($length > $max){
                $max = $length ;
          }  
          $i++ ;        
        }

        return $max ;
        close IN ;
}

