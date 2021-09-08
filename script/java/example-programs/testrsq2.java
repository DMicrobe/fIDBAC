import java.io.*;
import iubio.bioseq.*;
import iubio.readseq.*;
class testrsq2 {
	public static void main(String[] args) {
		try {
			// your data goes here
		Object inputObject= new FileReader("myseq.embl");
		Readseq rd= new Readseq();
		String seqname= rd.setInputObject( inputObject );
			//Readseq.setInputObject() accepts many basic Java objects including 
			//  Reader, File, URL, InputStream, String, char[], byte[], 
			//  and an Enumeration of these objects
		System.out.println("Reading from "+seqname);
	
		if ( rd.isKnownFormat() && rd.readInit() )  {
			while (rd.readNext()) {
				BioseqRecord seqrec= new BioseqRecord(rd.nextSeq());

				// do something with seqrec....
				FeatureItem[] fits= seqrec.findFeatures( new String[]{"CDS", "intron"});
				if (fits==null) System.out.println("  No such features found.");
				else {
					System.out.println("  Extracted features and their sequence");
					for (int k= 0; k<fits.length; k++) try {
						System.out.println( fits[k]);
						Bioseq bseq= seqrec.extractFeatureBases( fits[k]);
						System.out.println(bseq); System.out.println();
						}
					catch (SeqRangeException sre) { System.out.println(sre.getMessage()); }
					}
				}
			 } 
		} catch (Exception e) { e.printStackTrace(); }
	}   
}  