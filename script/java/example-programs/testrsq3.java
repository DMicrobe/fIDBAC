
import java.io.*;
import java.util.Date;
import iubio.bioseq.*;
import iubio.readseq.*;
class testrsq3 {
 public static void main(String[] args) {
	 try {
		 // your data goes here
	 Bioseq seq = new Bioseq( "ccggagtgaggagcaacatgaactacgtgggactgggacttatcattgtgctgagctgcc");
	 BasicBioseqDoc seqdoc= new BasicBioseqDoc("DMU57488");
	 seqdoc.addDocField( seqdoc.kAccession, "U57488");
	 seqdoc.addComment("Just a test sequence");
	 seqdoc.addDate( new Date("February 11, 1997"));
	 seqdoc.addSequenceStats( seq);
	 seqdoc.addFeature("gene", new SeqRange("18..1684"));
	 seqdoc.addFeatureNote("symbol", "est-6");
	 seqdoc.addFeature("intron", new SeqRange("1405..1455"));
	 BioseqRecord  seqrec= new BioseqRecord( seq, seqdoc);
 
		 // now write to a file
	 BioseqWriterIface writer= BioseqFormats.newWriter(
		 BioseqFormats.formatFromName("XML"));
	 writer.setOutput( new FileWriter("myseq.xml")) ;
	 writer.writeHeader();
	 if (writer.setSeq( seqrec)) writer.writeSeqRecord();
	 else System.err.println("Failed to write " +seqrec); // or throw exception
	 writer.writeTrailer();
	 writer.close();
	 } catch (Exception e) {  e.printStackTrace(); }
 }           
}  
