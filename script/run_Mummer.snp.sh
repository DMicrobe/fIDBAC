#!/bin/bash
#author liangq 20170213
#description : the pipeline for Mummer call snp by Mummer between two sequence
#$1 reference
#$2 query
#$3 outdir
#$4 sample

if [ $# -lt 2  ];then 
	echo "author: liangqian 20170213
usage:sh $0 <ref.fa> <query.fa> <outdir> <sample>\n" >&2
 	exit 1;
fi

binpath=$(cd "$(dirname "$0")"; pwd)
ref=$1
query=$2
outdir=$3
sample=$4

if [ ! -d $outdir ];then
	mkdir -m 755 -p $outdir
fi
## run call snp
cd $outdir 
/public/Biosoft/MUMmer3.23/nucmer $ref $query --prefix=$sample-ref_qry
/public/Biosoft/MUMmer3.23/delta-filter -r -q $sample-ref_qry.delta >$sample-ref_qry.filter
/public/Biosoft/MUMmer3.23/show-snps -Clr $sample-ref_qry.filter >$sample-ref_qry.snps

## format snp file
perl $binpath/format.Mummer.snps.pl $sample-ref_qry.snps $sample\.snps.xls

