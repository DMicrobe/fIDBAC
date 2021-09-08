#authpr liangqian at 2020702
import os
import subprocess
import sys, getopt
from threading import *
import time

def make_dir(path):
    if not os.path.exists(path):
        os.makedirs(path)

def rmDirAndFile(path):
    #先把各个目录的文件删除完
    for root, dirs, files  in os.walk(path):
        for file in files:
            filepath = os.path.join(root, file)
            try:
                os.remove(filepath)
            except:
                print("删除文件%s异常" % file)
    #再去删除空目录
    for root, dirs, files in os.walk(path):
        for dir in dirs:
            dirpath = os.path.join(root,dir)
            try:
                os.rmdir(dirpath)
            except:
                import  traceback
                print(traceback.format_exc())

class MyThread(Thread):
    def __init__(self,query,sb,out):
        super().__init__()
        self.q=query
        self.s=sb
        self.temp=out

    def run(self):
        with  sem:
            cmd="perl {bin}/0.Online/Average_Nucleotide_Identity/ANI/ANI.pl -qr {inf} -sb {sb} -od {temp}".format(bin=binpath,inf=self.q,sb=self.s,temp=self.temp)
            os.system(cmd)
            time.sleep(1)

def getani(infile):
    with open(infile) as handle:
        num=0
        ani=''
        for line in handle:
            num=num+1
        if num==2:
            line=line.strip('\n');
            cut=line.split("\t")
            ani=cut[2]
    return float(ani)

def main(argv):
    infile=argv[1]
    infasta=argv[2]
    outdir=argv[3]
    temp=argv[4]
    make_dir(outdir)
    make_dir(temp)
    threads=[]
    cmd="awk -F \"\t\" '{if($3>=95){print $2}}' "+infile+" >"+temp+"/95.genome.lst"
    listfile=temp+"/95.genome.lst"
    os.system(cmd)
    rmd=[]
    if os.path.getsize(listfile) == 0:
        os.system("head -n 5 {in1} |cut -f 2 >{temp}/top5.genome.lst".format(in1=infile,temp=temp))
        listfile=temp+"/top5.genome.lst"
    genomelist=[]
    sample=['input']
    anilist={}
    if os.path.exists(listfile):
        with open (listfile,'r') as handle:
            num=0;
            for line in handle:
                num=num+1
                tempdir=os.path.join(temp,'temp'+str(num))
                line=line.strip('\n')
                key=line.split('/')[-1]
                sample.append(key)
                genomelist.append(line)
                thread = MyThread(infasta,line,tempdir)
                #thread.start()
                threads.append(thread)
                anilist['input|'+key]=tempdir+"/OrthoANI.txt"
                anilist[key+'|input']=anilist['input|'+key]
                rmd.append(tempdir)
    
    for t in threads:
        t.start()
    for t in threads:
        t.join()
    os.system("cat {temp}/temp*/OrthoANI.txt |grep -v \'ANI(%)\' |sort -k3nr,3 |sed \"1 i GENOME1\tGENOME2\tANI(%)\" >{outdir}/ANI.all.txt".format(temp=temp,outdir=outdir))    
    threads2=[] 
    for i in range(len(genomelist)):
        key1=genomelist[i].split('/')[-1]
        for j in range(i+1,len(genomelist)):
            tempdir=os.path.join(temp,'_temp'+str(i)+str(j))
            thread = MyThread(genomelist[i],genomelist[j],tempdir)
            #thread.start()
            threads2.append(thread)
            key2=genomelist[j].split('/')[-1]
            #print(key1,key2)
            anilist[key1+"|"+key2]=tempdir+"/OrthoANI.txt"
            anilist[key2+"|"+key1]=anilist[key1+"|"+key2]
            rmd.append(tempdir)
   
    for t in threads2:
        t.start()

    for t in threads2:
        t.join()

    outani=open(outdir+"/all.ani.dist",'w')
    outani.write("\t"+"\t".join(sample)+"\n")
    for i in sample:
        con=i
        for j in sample:
            if i==j:
                con=con+"\t0"
            else:
                ani=getani(anilist[i+"|"+j])
                dist=str(100-ani)
                con=con+"\t"+dist
        outani.write(con+"\n")
    outani.close()

    for d in rmd:
        rmDirAndFile(d)
 
if __name__ == '__main__':
    if len(sys.argv) < 1 :
        print("python3 OrthoANI.all.py <fastani.result> <query> <outdir> <tempdir>")
        sys.exit()
    binpath = os.path.split(os.path.abspath(__file__))[0]
    sem=Semaphore(12)#最大线程数为12
    main(sys.argv)

