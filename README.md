# fIDBAC
fIDBAC integrated an accuracy bacterial identification, automated strain typing and downstream AR/VF gene prediction analysis in a single, coherent workflow, the website is [http://fbac.dmicrobe.cn/](http://fbac.dmicrobe.cn/)

## Installtion

 First download part of the database and code, and then install the dependent software mentioned in the requirements.txt file.
  ```
  git clone https://github.com/DMicrobe/fIDBAC.git
  
  ```
### Requirements
* perl
* Python3\
 The packages that need to be installed are "Biopython scipy skbio gzip Levenshtein".
* NCBI BLAST+ [2.10.1](ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST)
* FastANI [here](https://github.com/ParBLiSS/FastANI)
* Prokka [1.14.6](https://github.com/tseemann/prokka)
* Prodigal [V2.6.3](http://prodigal.ornl.gov)
* RGI [here](https://card.mcmaster.ca/)
* Phylip [here](https://evolution.genetics.washington.edu/phylip.html)
* MUMmer [3.23](http://mummer.sourceforge.net/)
* ANIcalculator [v1.0](https://ani.jgi.doe.gov/html/download.php)

You can also install this softwares with using conda.Due to dependency conflicts, we recommend installing **RGI** independent of other software. After the software are installed, write this software path to the file [**config_db.txt**](https://github.com/DMicrobe/fIDBAC/blob/master/script/config_db.txt).
  
## Download data
 * Download Type strains genome and gene files in [12784.genome.txt](https://github.com/DMicrobe/fIDBAC/blob/master/12784.genome.txt) . Construct a configuration file, format reference file, write ACC ID, genome and gene path into the file [type](https://github.com/DMicrobe/fIDBAC/blob/master/example/type.example.list.txt).
 * Download kmerdb and close snp data [here](http://fbac.dmicrobe.cn/about/) .
 * Download PubMLST database [here](https://pubmlst.org/static/data/dbases.xml) . 
 
 
## Test
```
perl script/fIDBAC.pl  -input example/example.fa -outdir ./ -temp ./
```


