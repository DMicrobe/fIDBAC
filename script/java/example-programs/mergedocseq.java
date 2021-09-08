// mergedocseq.java
// example biosequence program to merge documentation with sequence files (e.g., gcg format)
// compile as: javac -classpath readseq.jar:$CLASSPATH  mergedocseq.java
// run as: jre -cp .:readseq.jar mergedocseq input1 input2 ...
// assumes input in two parts:  my.seq and my.seq.doc, where .doc is EMBL format document


import java.io.*;
import java.util.*;
import iubio.bioseq.*;
import iubio.readseq.*;
import flybase.Utils;

public class mergedocseq {
	static String outformat= "embl";
	
  public static void main( String[] args) 
  {
    if (args==null || args.length==0) System.out.println(
      "Usage: jre -cp .:readseq.jar [out=output-file] [format=output-format] inputfile(s)");
    else try {
   		Vector names= new Vector();
      PrintStream out= System.out;
      for (int iarg= 0; iarg < args.length; iarg++) {
        String arg= args[iarg];
        if (arg.startsWith("format=")) 
 					outformat=arg.substring("format=".length());
        else if (arg.startsWith("out=")) {
 					String outfile=arg.substring("out=".length());
 					out= new PrintStream(new FileOutputStream(outfile));
 					}
       	else names.addElement(arg);  
        }

	    BioseqWriterIface writer= BioseqFormats.newWriter(
	    		BioseqFormats.formatFromName(outformat));
	    writer.setOutput(out);
	    writer.writeHeader();
    
    	Readseq rd= new Readseq();
      Enumeration en= names.elements();
      while (en.hasMoreElements()) {
      	String name= (String) en.nextElement();
        String seqname= rd.setInputObject( name );
        String docname= name + ".doc";
        System.err.println("Merging " + docname + " with " + seqname);
        if ( rd.isKnownFormat() && rd.readInit() )  {
          while (rd.readNext()) {
            SeqFileInfo sfi= rd.nextSeq();
            sfi.seqdoc= parseDoc( new EmblDoc(), docname);
						if (writer.setSeq( sfi)) writer.writeSeqRecord();
						else System.err.println("Failed to write " +sfi); // or throw exception
            }
          }
        }
    	writer.writeTrailer();
    	writer.close();
 		}
    catch (Exception ex) { ex.printStackTrace(); }
  }
  
	static BioseqDoc parseDoc( BioseqDoc doc, String docfile) throws Exception
	{
 	 	BufferedReader docf= new BufferedReader( new FileReader(docfile));
 	 	String line;
 	 	while ((line= docf.readLine()) != null) {
 	 			// this assumes line is in format of current BioseqDoc
 	 		doc.addDocLine(line);
 	 			// or if data line needs parsing, do things like this:
 	 		//doc.addDocField( doc.getFieldName( BioseqDoc.kName), value, BioseqDoc.kField, false);
 	 		}
 	 	docf.close();
 	 	return doc;
	}

}
