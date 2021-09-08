import sys
import  Levenshtein
f = open(sys.argv[1])
head = f.readline()
seq = f.readline() 
head=head.strip('\n')
head=head.strip('>')
dict = {}
while True:
    a = f.readline()
    a=a.strip('\n')
    a=a.strip('>')
    line = f.readline()
    if not line: break
    num = Levenshtein.hamming(seq,line)
    dict[a] = num 
f.close()

L = sorted(dict.items(),key=lambda item:item[1],reverse=False)
L = L[:10]
dictdata = {}
print (head + "\t" + '0')
for l in L:
	dictdata[l[0]] = l[1]
	print (l[0] + "\t" + str(l[1]))
