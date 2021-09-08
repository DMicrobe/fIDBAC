// features.java
// example biosequence features extraction with iubio.readseq package
// compile as: javac -classpath readseq.jar:$CLASSPATH  features.java
// run as: jre -cp .:readseq.jar features find=exon,CDS,... inputfile(s)


import java.io.*;
import java.util.*;
import iubio.bioseq.*;
import iubio.readseq.*;
import flybase.Utils;

public class features {
  public static void main( String[] args) 
  {
    if (args==null || args.length==0) System.out.println(
      "Usage: jre -cp .:readseq.jar features find=exon,CDS,... inputfile(s)");
    else try {
      Hashtable feathash= new Hashtable();
      Vector names= new Vector();
      PrintStream out= System.out;
      for (int iarg= 0; iarg < args.length; iarg++) {
        if (args[iarg].startsWith("find=")) {
          String[] ss= Utils.splitString( args[iarg].substring(5), " ,;:");
          out.println("Find features:");
          for (int k=0; k<ss.length; k++) { feathash.put( ss[k], ss[k]); out.println(ss[k]); }
          }
        else names.addElement(args[iarg]);  
        }
      Readseq rd= new Readseq();
      Enumeration en= names.elements();
      while (en.hasMoreElements()) {
        String name= rd.setInputObject( en.nextElement());
        out.println("Reading from " + name);
        if ( rd.isKnownFormat() && rd.readInit() )  {
          while (rd.readNext()) {
            SeqFileInfo sfi= rd.nextSeq();
            BioseqRecord bsrec= new BioseqRecord(sfi);
            out.println(bsrec);
            FeatureItem[] fits= bsrec.findFeatures( feathash);
            if (fits==null) out.println("  No such features found.");
            else {
              out.println("  Extracted features");
              for (int k= 0; k<fits.length; k++) out.println( fits[k]);
              out.println("  Extracted sequence");
              try { 
                Bioseq bseq= bsrec.extractFeatureBases( feathash);
                out.println(bseq); out.println();
                }
              catch (SeqRangeException sre) { out.println(sre.getMessage()); }
              }
            }
          }
        }
      }
    catch (Exception ex) { ex.printStackTrace(); }
  }
}


/* example output:

Find features:
exon
CDS
Reading from gbinv1s.seq
iubio.readseq.BioseqRecord: id=AA18SRN, length=1079, title=A.australis gene for 18S ribosomal RNA (partial).
  No such features found.
iubio.readseq.BioseqRecord: id=AA18SRRN, length=1812, title=A.australis gene for 18S ribosomal RNA.
  No such features found.
iubio.readseq.BioseqRecord: id=AA18SRRNA, length=1950, title=Aedes albopictus gene for 18s rRNA.
  No such features found.
iubio.readseq.BioseqRecord: id=AA58SRRN, length=155, title=Aedes albopictus gene for 5.8S ribosomal RNA.
  No such features found.
iubio.readseq.BioseqRecord: id=AAAAGC, length=348, title=Anadara trapezia alpha globin mRNA, 3' end.
  Extracted features
iubio.readseq.FeatureItem: name=CDS, location=join(<31..63,64..177)
iubio.readseq.FeatureNote: name=/codon_start, value=1
iubio.readseq.FeatureNote: name=/product, value="alpha globin"
iubio.readseq.FeatureNote: name=/db_xref, value="PID:g402359"
iubio.readseq.FeatureNote: name=/translation, value="INRKISGDAFGSIIEPMKETLKARMGSYYSDDVAGAWAALIGVV QAAL"
iubio.readseq.FeatureItem: name=exon, location=1..63
iubio.readseq.FeatureNote: name=/note, value="Bases 1-30 are PCR-primer sequence and have not been determined independently"
iubio.readseq.FeatureNote: name=/number, value=2
iubio.readseq.FeatureItem: name=exon, location=64..177
iubio.readseq.FeatureNote: name=/number, value=3
  Extracted sequence
tgtgttgtagaaaaatttgccgtcaaccatatcaacaggaaaatcagcggtgacgcattcgggtcaatcattgaaccaatgaaggagacactgaaggccaggatgggcagttattacagtgatgatgtcgctggagcatgggccgctctgattggtgtagttcaggctgctttgtaatcaatcattgaaccaatgaaggagacactgaaggccaggatgggcagttattacagtgatgatgtcgctggagcatgggccgctctgattggtgtagttcaggctgctttgtaa

iubio.readseq.BioseqRecord: id=AAABDA, length=1759, title=A.aegypti abd-A gene for abdominal-A protein homologue (partial).
  Extracted features
iubio.readseq.FeatureItem: name=CDS, location=1016..1239
iubio.readseq.FeatureNote: name=/partial, value=
iubio.readseq.FeatureNote: name=/gene, value="abd-A"
iubio.readseq.FeatureNote: name=/codon_start, value=3
iubio.readseq.FeatureNote: name=/product, value="abdominal-A homologue"
iubio.readseq.FeatureNote: name=/db_xref, value="PID:g5554"
iubio.readseq.FeatureNote: name=/db_xref, value="SWISS-PROT:P29552"
iubio.readseq.FeatureNote: name=/translation, value="PNGCPRRRGRQTYTRFQTLELEKEFHFNHYLTRRRRIEIAHALC LTERQIKIWFQNRRMKLKKELRAVKEINEQ"
iubio.readseq.FeatureItem: name=exon, location=1016..1239
iubio.readseq.FeatureNote: name=/gene, value="abd-A"
  Extracted sequence
gtcccaacggatgcccgcgtcgacgaggccggcaaacgtacacccgcttccagacgctcgagctggagaaagagttccacttcaaccactacctgacccggcgacggaggatcgaaattgcgcacgccctgtgtctgaccgagcggcagatcaaaatctggttccaaaatcgccggatgaagctgaagaaggaactgcgggcggtgaaggaaattaacgaacag


*/
