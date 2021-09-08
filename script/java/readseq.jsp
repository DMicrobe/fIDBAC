<%@ page import="java.io.*,java.util.*,java.net.*,javax.servlet.http.*,javax.servlet.jsp.*" %>
<%@ page import="iubio.readseq.*,iubio.bioseq.*" %>
<%! ///////////// static/global code ////////////////// 
// readseq.jsp
// using http://iubio.bio.indiana.edu/soft/molbio/readseq/java/readseq.jar
// readseq-2.1.23 patched to work inside servlets (ClassLoader issue)

String TEST_SEQ="http://iubio.bio.indiana.edu/soft/molbio/readseq/java/test-seq.gb";
String HOME_URL="http://iubio.bio.indiana.edu/soft/molbio/readseq/java/";

BioseqRecord testSeq()  throws Exception
{
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
  return seqrec;
}

String selectFormat(String param, String current) 
{
  boolean isout= (!param.startsWith("in"));
  StringBuffer sb= new StringBuffer();
  sb.append("<SELECT name=\""+param+"\">\n");
  String selname= BioseqFormats.formatName( BioseqFormats.getFormatId(current));
  int n= BioseqFormats.nFormats();
  for (int i= 1; i<=n; i++) {
    boolean  cando;
    if (isout) cando= BioseqFormats.canwrite(i);
    else cando= BioseqFormats.canread(i);
    if (cando) {
      String nm= BioseqFormats.formatName(i); 
      String vn= BioseqFormats.formatNameFromIndex(i);
      String sel= ( selname.equals(nm) ) ? "SELECTED " : "";
      int x=nm.indexOf('|'); if(x>0) nm= nm.substring(0,x); 
      sb.append( "<OPTION "+sel+"value=\""+nm+"\">" + vn);
      sb.append('\n');
      }
    }
  sb.append("</SELECT>\n");
  return sb.toString();
}

boolean nullstr(String s) { return (s==null||s.trim().length()==0||"null".equals(s)); }

Object writeSeq(Object seqrec, String format, JspWriter out) throws Exception
{
  //ByteArrayOutputStream os= new ByteArrayOutputStream();
  try {
    BioseqWriterIface writer= BioseqFormats.newWriter(
      BioseqFormats.getFormatId(format) // "GenBank" "EMBL" "fasta" "XML"
      ); 
    writer.setOutput( out) ; //writer.setOutput( os) ;
    writer.writeHeader();

    if(seqrec instanceof List) 
     for (int i=0, ns= ((List)seqrec).size(); i<ns; i++) {
      if( writer.setSeq( (SeqFileInfo)((List)seqrec).get(i)) ) writer.writeSeqRecord();
      }
    else if (writer.setSeq( (SeqFileInfo)seqrec)) writer.writeSeqRecord();
    else out.println("Failed to write " +seqrec); // or throw exception
    
    writer.writeTrailer();
    }
  catch (Exception e) {
    out.println("Failed to write " +seqrec); // or throw exception
    out.println("Exception: "+e);
    }
  return "";  //return os.toString();
}

//////////// end static application scope //////////////////
%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
<title>ReadSeq</title> 
<link rel="stylesheet" type="text/css" href="stylesheet.css" />
</head><body>

<h1><%= Readseq.version %></h1>
<% 
String self_url= request.getRequestURI();
String format= request.getParameter("format"); if(nullstr(format)) format="EMBL";
String input = request.getParameter("in");  if(nullstr(input)) input="";
%>

<h3>Example:</h3>
<a href="<%= self_url %>?format=embl&in=<%= TEST_SEQ %>">
readseq.jsp?format=embl&amp;in=<%= TEST_SEQ %></a> <br>
<i>Using software from </i><a href="<%= HOME_URL %>"><%= HOME_URL %></a>
<p>

<form method="get" action="<%= request.getRequestURL() %>">
Format: <%= selectFormat("format",format) %>  <input type="submit"value="Go" />
In: <input name="in" value="<%= input %>" size="60" /> <br> 
</form>

<h3>Reformat:<hr></h3> 
<% 
  ArrayList seqlist= new ArrayList();
  if (nullstr(input)) seqlist.add( testSeq() );
  else {
  Readseq rd= new Readseq();
  String seqname= rd.setInputObject( input );
  if ( rd.isKnownFormat() && rd.readInit() )  {
	  while (rd.readNext()) seqlist.add( rd.nextSeq() );
	  }
  }
%>
<pre n=80><%= writeSeq( seqlist, format, out)%></pre>

</body>
</html>


