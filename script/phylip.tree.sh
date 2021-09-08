#!bin/csh/
binpath=$(cd "$(dirname "$0")"; pwd)
echo $binpath
java -jar $binpath/java/readseq.jar  -a snp.top10.fa  -inform=8 -f=12 -o snp.top10.phy
/public/Biosoft/miniconda3/bin/seqboot <<EOF
snp.top10.phy
R
100
y
5
y
EOF
mv outfile 1
/public/Biosoft/miniconda3/bin/dnadist <<EOF
1
M
D
1000
y
EOF
mv  outfile  2

/public/Biosoft/miniconda3/bin/neighbor <<EOF
2
M
1000
5
Y
EOF
mv outfile  302
mv outtree  3 
/public/Biosoft/miniconda3/bin/consense <<EOF
3
Y
EOF
mv outfile  402
mv outtree  4
/public/Biosoft/miniconda3/bin/drawgram  <<EOF
4
/public/Biosoft/miniconda3/bin/font1
P
W
2000
2000
y
EOF
mv plotfile plotfile.bmp
