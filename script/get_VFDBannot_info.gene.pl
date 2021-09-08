#!usr/bin/perl -w
use strict;
use Getopt::Long;
#use Support_Program;

=head1 Name

   get_VFDBannot_info.pl

=head1 Description

   
=head1 Options
   
   perl get_annot_info.pl [options]
   -nohead   do not show the first instruction line
   -input    input the BLAST result with the m8 option
   -id       input the id file of the database (id	annot_information)
   -coverage alignment/query_length, cutoff which less than, default 80 
   -identity identity, cutoff which less than, default 80 
   -out      give the output files name and the path
   -eval     float or exponent,to filter the alignments which worse than the E-value cutoff
   -topmatch integer, to set the top boundary about how many results that one query matched one subjects to dispaly
   -q        query FASTA file
   -help     output the help information

=head1 Usage

   perl get_VFDBannot_info.pl -nohead -input blast.m8.xls -out ../kegg.out.xls -id id.xls -q query.fa

=cut

my ($input,$id,$out,$help,$identity,$topmatch,$eval,$nohead,$protein, $coverage,$query);
GetOptions(
  "input:s"=>\$input,
	"id:s"=>\$id,
	"out:s"=>\$out,
	"identity:i"=>\$identity,
	"topmatch:i"=>\$topmatch,
	"e:f"=>\$eval,
	"nohead:s"=>\$nohead,
	"coverage:s"=>\$coverage,
	"q:s"=>\$query,
	"help"=>\$help
);
die `pod2text $0` if($help);
die `pod2text $0` unless(defined $input && defined $id && defined $out && defined $query);

$coverage ||= 60 ;
$identity ||= 85 ;
$topmatch ||= 1 ;

my %len ;
open QUE, "$query" or die;
$/=">";<QUE>;
while (<QUE>){
	chomp;
	my ($id, @l)=split(/\n/, $_);
	my $seqs=join("", @l);
	$seqs =~ s/\n//g;
	my $acc = (split /\s+/, $id)[0] ;
	my $length = length $seqs;
	$len{$acc} = $length ;
	#print "$id...$length...\n";
	
}
close QUE;

$/="\n";
my %hash_id;
open INI,"<$id" || die "Can't open the id file $id,maybee you nedd help from zhangfx!  $!";
while(<INI>){
    chomp;
	next if(/^(\s+)$/ || /^#/);
	my @ids = split /\t/,$_,2;
	$ids[1] = "---" unless(defined $ids[1]);
	if (!$ids[0]){next;}
	$hash_id{$ids[0]} = $ids[1];
}
open INR,"<$input" || die "Can't open the input m8's blast file $input! $!";
open OUT1,">$out.info.txt" or die ;
open OUT2, ">$out.filter.txt" or die ;
print OUT1 "Query_id\t%Identity\tE-value\tRelated genes\tVirulence factors\tClass\tDescription\tStrain\n" unless(defined $nohead);
print OUT2 "Query_id\t%Identity\tE-value\tRelated genes\tVirulence factors\tClass\tDescription\tStrain\n" unless(defined $nohead);
my %tag ;
while(<INR>){
    	chomp;
	next if(/^(\s+)$/ || /^#/);
	my @evals = split /\t/,$_;
	my $q_len=int($len{$evals[0]}/3);
	next if(defined $eval && $evals[10] > $eval);
	if(!exists $tag{$evals[0]}){
		$tag{$evals[0]} = 1 ;
    if(exists $hash_id{$evals[1]}){
			print OUT1 "$evals[0]\t$evals[2]\t$evals[10]\t$hash_id{$evals[1]}\n";
		}
		if (exists $hash_id{$evals[1]} && $evals[3]/$q_len*100 >= $coverage && $evals[2]>= $identity){
			print OUT2 "$evals[0]\t$evals[2]\t$evals[10]\t$hash_id{$evals[1]}\n";
		}
	}else{
		$tag{$evals[0]} += 1 ;
		my $num = $tag{$evals[0]};
		if ($num <= $topmatch){
			if(exists $hash_id{$evals[1]}){
				print OUT1 "$evals[0]\t$evals[2]\t$evals[10]\t$hash_id{$evals[1]}\n";
			}
			if (exists $hash_id{$evals[1]} && $evals[3]/$q_len*100 >= $coverage && $evals[2] >=$identity){
				print OUT2 "$evals[0]\t$evals[2]\t$evals[10]\t$hash_id{$evals[1]}\n";
			}
		}
	}
}
