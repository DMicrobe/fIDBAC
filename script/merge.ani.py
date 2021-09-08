import os
import sys
import re

ani=sys.argv[1]
gani=sys.argv[2]
out=open(sys.argv[3],"w")
sample=sys.argv[4]

keys1=[]
ani1={}
ani2={}
with open (ani,'r') as f1:
     num=0
     for line in f1:
          num=num+1
          if num>=2:
              line=line.strip("\n")
              cut=line.split("\t")
              ani1[cut[1]]=cut[2]
              keys1.append(cut[1])
out.write("GENOME1\tGENOME2\tOrthoANI\tANI(1->2)\tAF(1->2)\n")
with open (gani,'r') as f2:
     num=0
     for line in f2:
          num=num+1
          if num>=2:
              if line != '\n': 
                  line=line.strip("\n")
                  cut=line.split("\t")
                  for key in keys1:
                      #print(cut[1]+"****"+key)
                      if re.search(key,cut[1]):
                          out.write(sample+"\t"+key+"\t"+ani1[key]+"\t"+cut[2]+"\t"+cut[4]+"\n")
out.close()
