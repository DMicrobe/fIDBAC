#!usr/bin/perl
use strict ;
use File::Basename ;

my $file = shift ;
my $namefile = shift ;
my %name;
open NA,"<$namefile" or die $!;
while(<NA>){
	chomp;
	my @cut=split /\t/,$_ ;
	$name{$cut[0]}=$cut[1]
}
close NA;

my %ha ;
my $i = 0 ;
my $name ;
open IN,"$file" or die ;
$/=">";<IN>;
while (<IN>){
	chomp ;
	my ($tag, $seq) = split /\n/,$_,2 ;
	my $id = (split /\s+/, $tag)[0] ;
	print ">$name{$id}\n$seq";
}
close IN ;
