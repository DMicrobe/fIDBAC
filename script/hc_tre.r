args<-commandArgs(T)

library(ape)
a=read.table(args[1],header=T)
d=dist(a)
hc=hclust(d,"complete")
tre=as.phylo(hc)
write.tree(tre,args[2])

