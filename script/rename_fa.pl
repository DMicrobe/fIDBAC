#!usr/bin/perl
use strict ;
use File::Basename ;

my $file = shift ;
my $prefix = shift ;
$prefix ||="for_prokka";
my %ha ;
my $i = 0 ;
my $name ;
open IN,"$file" or die ;
$/=">";<IN>;
while (<IN>){
	chomp ;
	my ($tag, $seq) = split /\n/,$_,2 ;
	my $id = (split /\s+/, $tag)[0] ;
	my $len = length $id ;
	if ($len <= 20){
		print ">$id\n$seq";
		print STDERR "$id\t$id\n";
	}else{
		$name = "${prefix}_${i}";
		print ">$name\n$seq";
		print STDERR "$id\t${prefix}_${i}\n";
  	$i++ ;
  }
}
close IN ;
