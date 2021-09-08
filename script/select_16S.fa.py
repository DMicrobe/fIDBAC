#!/public/Biosoft/local/bin/python
#-*- coding: utf-8 -*-

import os
import sys
import re
from Bio import SeqIO
import gzip

##sys.argv[1]: *_rna_from_genomic.fna.gz from NCBI ,or prokka's result
out=open(sys.argv[2],'w')
if re.search(".gz",sys.argv[1]):
    with gzip.open(sys.argv[1], "rt") as handle:
        for seq_record in SeqIO.parse(handle, "fasta"):
            if re.search("16S ribosomal RNA",str(seq_record.description)) or re.search("ribosomal RNA 16S$",str(seq_record.description)) or re.search("16S ribosomal RNA\]",str(seq_record.description)) or re.search("16s_rRNA",str(seq_record.description)):
                if not re.search("23S",str(seq_record.description)):
                    out.write(">"+str(seq_record.description)+"\n"+str(seq_record.seq)+"\n")
     

else:
    for seq_record in SeqIO.parse(sys.argv[1], "fasta"):
        if re.search("16S ribosomal RNA",str(seq_record.description)) or re.search("ribosomal RNA 16S$",str(seq_record.description)) or re.search("16S ribosomal RNA\]",str(seq_record.description)) or re.search("16s_rRNA",str(seq_record.description)):
            if not re.search("23S",str(seq_record.description)):
                out.write(">"+str(seq_record.description)+"\n"+str(seq_record.seq)+"\n")
out.close()
        
