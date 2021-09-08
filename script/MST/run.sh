cd $2
rm -rf MST
perl /public/Users/liangq/pipeline/fBac_bin/0.Online/MST/ST2matrix.pl  $1 $3  >MST.matrix
/public/Biosoft/MSTgold_package/MSTgold-linux  -ft M -f MST.matrix  -m 100 -n 1 -r 10 -t 60 -d 0.005 -b 30 -s 100 >log 2>err
mv MST/MST*1.dot MST/MST_1.dot
mv MST/MST\ consensus\ network.dot  MST/MST_consensus_network.dot
mv MST/MST\ report.txt  MST/MST_report.txt
perl /public/Users/liangq/pipeline/fBac_bin/0.Online/MST/edit_dot.pl MST/MST_1.dot  MST >>log 2>>err
/public/Biosoft/graphviz-2.40.1/local/bin/dot -Gname MST/MST_1.fin.dot -T svg -o   MST/MST.svg >MST/log 2>MST/err
/public/Biosoft/graphviz-2.40.1/local/bin/dot -Gname MST/MST_1.fin.dot -T png -o MST/MST.png >>MST/log 2>>MST/err
echo $2
