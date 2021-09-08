// testrsq.java
// example biosequence input to output format conversion
// compile as: javac -classpath readseq.jar:$CLASSPATH  testrsq.java
// run as:     jre -cp .:readseq.jar testrsq  inputfile(s)...

import java.io.*;
import iubio.readseq.*;

class testrsq {
  public static void main(String[] args) {
    try {
    int outid= BioseqFormats.formatFromName("fasta");
    BioseqWriterIface seqwriter= BioseqFormats.newWriter(outid);
    seqwriter.setOutput( System.out);
    seqwriter.writeHeader();
    Readseq rd= new Readseq();
    for (int i=0; i<args.length; i++) {
      rd.setInputObject( args[i] );
      if (rd.isKnownFormat() && rd.readInit())
        rd.readTo( seqwriter);
      }
    seqwriter.writeTrailer();
    }
  catch (Exception e) { e.printStackTrace(); }
  }
}   
