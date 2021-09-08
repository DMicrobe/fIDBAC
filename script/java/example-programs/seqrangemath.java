import java.io.*;
import iubio.bioseq.*;
import iubio.readseq.*;
class seqrangemath {
	public static void main(String[] args) {
		try {
		flybase.Debug.setState(true);
		System.out.println("Test SeqRange math");
		System.out.println("== rev 6 =============");
		testSReverse();
		System.out.println("======================");
		} catch (Exception e) { e.printStackTrace(); }
	}   
	   	
	static String[] testsr= new String[] {
		"10..60",
		"complement(10..60)",
		"join(1..5,20..40,55..60)",
		"complement(1..5,20..40,55..60)",
		"join(1000..1500,2000..2500,3000..3100)",
		"complement(join(1000..1500,2000..2500,3000..3100))",
		};
	static String[] subrs= new String[] {
		"-100..10",
		"1..end",
		"end..end+100",
		"-100..end+100",
		"join(-100..10,end..end+100)",
		};
		
	static void testSReverse() { testSReverse( testsr, subrs); }
	static void testSReverse(String[] seqranges, String[] subranges) {
		System.out.println("Test SeqRange.subrange()");
		for (int i= 0; i<seqranges.length; i++) try {
			SeqRange sr= new SeqRange(seqranges[i]);
			SeqRange rev= sr.reverse(); // need to test !
			SeqRange rerev= rev.reverse();
			System.out.println("sr= "+sr+", rev="+rev+" rerev="+rerev);
			
			for (int k=0; k<subranges.length; k++) {
				SeqRange subr= new SeqRange(subranges[k]);
				SeqRange newsr= sr.subrange(subr);
				System.out.println( sr+" & subrange("+subr+")  = "+newsr);
				}
			System.out.println();
			} catch (Exception e) { e.printStackTrace(); }
		}        
}  