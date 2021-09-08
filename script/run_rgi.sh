#!/bin/bash
export PATH="/sugon/Users/liangq/softwave/miniconda3/bin:$PATH"
#export PYTHONPATH=/sugon/Users/liangq/softwave/miniconda3/lib/python2.7/site-packages:$PYTHONPATH
source  /public/Biosoft/miniconda3/bin/activate RGI

index=/public/Database/CARD/20210423/aro_index.tsv
pro=$1
outdir=$2
if [ ! -d $outdir ];then
	mkdir -m 755 -p $outdir
fi

/public/Biosoft/miniconda3/envs/RGI/bin/rgi  main -i $pro -t protein -o $outdir/output -n 12 --clean
perl /public/Users/liangq/pipeline/fBac_bin/6.ARDB_7.VFDB/format_RGIresult.pl $index $outdir/output.txt $outdir/ARoutput.result.txt
conda /public/Biosoft/miniconda3/bin/deactivate
