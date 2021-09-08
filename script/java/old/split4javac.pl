#!/usr/local/bin/perl
# split4javac.pl

=head1
	
 split4javac.pl -- split java source code into a bunch of piddly little files 
 named after each public class/interface; suitable to run thru javac.
 
 Sun javac places a big time-wasting restriction on software engineers
 when it requires each public interface/class be in a file of the same name.java.
 I don't believe in wasting my time like that (neither does Metrowerks Codewarrior, 
 thanks so much), in putting up with this sort of source code to file system
 dependency, not to mention the OS-file system problems with name case and
 length.  But others sometimes want to javac my code, so...use split4javac.pl

  FlyBase java source tree results: 
    Done -- processed 304 source files to 1692 split files. 
  (doesn't that 6-fold increase in file number suggest time costs to you?)

 from Don Gilbert (software@bio.indiana.edu), may 2001


=cut



$debug= 1;
# $macos= 1;
$in = 'MacHome:bio:djava:javapps:rseq:rseq.mcp.xml';
$outpath= 'MacHome:rseq-split7:';
$addlist= 'MacHome:bio:djava:javapps:rseq:src:split4javac.addlist';

use POSIX;
use Getopt::Std;    
# use File::Basename;

$osname= $^O; #  MacOS|VMS|AmigaOS|os2|RISCOS|MSWin32|MSDOS?
$osfilesep= getOsFileSep($osname);
$macos= 1 if ($osname =~ m/MacOS/i);

$targpatt= 'Release';
$inpath='';

# only care about ones that can be in class/interface declaration
@javareswds= qw(public abstract static interface class final const extends implements);
# these are not part of class/interface but may be around..
@javareswd1= qw(import package private protected super void);

%opt=();

unless($macos) {
Getopt::Std::getopts('Da:i:o:t:',\%opt);

die "usage: $0 
-i input-java-source-folder-OR-jar-OR-codewar-project-xml 
-o output-path-to-create
-t target-name-IF-xml
-a add-listed-classes-to-split
-D -- debug
" 
  unless($opt{o} && $opt{i});

$in = $opt{i};
$outpath= $opt{o};
$addlist= $opt{a};
$targpatt= $opt{t} || $targpatt;
$debug= $opt{D} || $debug;
}

@fns= ();

$outpath .= $osfilesep unless($outpath =~ m,$osfilesep$,);
die "output-path-to-create $outpath already exists; I won't overwrite" 
  if (-e $outpath) ;

if (-d $in) {
  $in .= $osfilesep unless($in =~ m,$osfilesep$,);
  $inpath= $in;
  scanDirForJava( $in, '');
  }
  
elsif ($in =~ m/\.xml$/) {
  open(IN,$in) || die "open $in";
  $inpath= $in; $inpath =~ s,[\w\.]+\.xml$,,;
  
  while (<IN>) {
    if (m,<TARGET>,) { $intarg= 1; }
    elsif (m,</TARGET>,) { $intarg= 0; }
    elsif ($intarg == 1 && m,<NAME>, && m,$targpatt,) { $intarg= 2; }
    elsif ($intarg == 2 && m,<FILE>,)  { $intarg= 3; $accpath= '';  %fkv=(); }
    elsif ($intarg == 3 && m,</FILE>,) { 
      $intarg= 2; 
      $fn  = $fkv{PATH};
      if ($fn =~ m,\.java$,) {
        $fsep= getOsFileSep( $fkv{PATHFORMAT} );
        $acp= $fkv{ACCESSPATH};
        # assume $inpath ends with $osfilesep
        $acp =~ s/^:// if ($fsep eq ':');  # MacOS -- PathRelative
        $fn  =~ s/^:// if ($fsep eq ':');  # MacOS  -- PathRelative
        $fn= $acp . $fn;
        $fn =~ s,$fsep,$osfilesep,g;  
        ## ?? only prepend $inpath if <PATHTYPE>PathRelative && <PATHROOT>Project
        unless(-r "$inpath$fn") { warn "cant read $inpath$fn\n"; }
        else { push(@fns, $fn); }
        }
      }
    
    elsif ($intarg == 3) {
      if (m,<([^>]+)>([^<]+),) {
        $key= $1; $val= $2;
        $fkv{$key}= $val;
        }
      
#     <FILE>
#         <PATHTYPE>PathRelative</PATHTYPE>   ??
#         <PATHROOT>Project</PATHROOT>        ??
#         <ACCESSPATH>:src:</ACCESSPATH>      **
#         <PATH>:iubio:readseq:XmlDoc.java</PATH>  **
#         <PATHFORMAT>MacOS</PATHFORMAT>      ??
#         <FILEKIND>Text</FILEKIND>
#         <FILEFLAGS>Debug</FILEFLAGS>
#     </FILE>

      }
      
    }
  close(IN);
  }
elsif ($in =~ m/\.(jar|zip)$/) {
  die "jar input not ready";
  }
else {
  die "cant do anything for $in";
  } 

my $dnos= $outpath; $dnos =~ s/$osfilesep$//;
die "cant create folder $dnos" unless( mkdir($dnos, 0777) );

	# get list of package classes to split out
	# class iubio.readseq.TestBiobase is defined in BioseqReader.java
	# class iubio.readseq.ReadseqException is defined in Writeseq.java
# undef %addlist;
if ($addlist) {
	if (open(A,$addlist)) {
		while(<A>) { 
			chomp(); s/^\s*//; next unless(/^\w/); 
			next if (/it should be defined in a file called/);
			s,Warning : ,,;
			s, is defined in .+,,;
			s,(^|\s)(class|interface|public|abstract)\s,,g;
			s/^\s*//; s,\s*$,,;
			$addlist{$_}= 1; 
			warn "adding split for '$_'\n" if $debug;
			}
		close(A);
		}
	else { warn "cant read add-list from $addlist\n"; }
}
	
$javareservedpatt= join('|',@javareswds, @javareswd1);
$ndone= $nwrit= 0; 
$depth= 0;
$packagepath= ''; # $osfilesep; #??

foreach $jinfile (@fns) {
  $jinfullpath= "$inpath$jinfile";
  unless(open(IN,$jinfullpath)) { warn "cant open $jinfullpath\n"; next; }
  my @tm= localtime( $^T + 24*60*60*(-M $jinfullpath) );
  $jindate= POSIX::strftime("%d-%B-%Y",@tm); # fix; add hr-min-sec?

  split4javac( *IN);  $ndone++;
  close(IN); 
}

warn "Done -- processed $ndone source files to $nwrit split files.\n";
exit;

#----------
 
sub getOsFileSep {
  my($osname)= @_;
  my $fsep;
  if ($osname =~ m/MacOS/i) { $fsep= ':';  }
  elsif ($osname =~ m/MS(Win|DOS)/i) { $fsep= '\\'; }
  else  { $fsep= '/'; } # default to unix
  return $fsep;
}

sub scanDirForJava {
  my($maindir, $subdir)= @_;
  $subdir .= $osfilesep unless($subdir eq '' || $subdir =~ m,$osfilesep$,);
  my $indir= $maindir.$subdir;
  local(*DIR);
  opendir(DIR,$indir) || die "opendir $indir";
  my $fn;
  while ($fn= readdir(DIR)) {
    next if ($fn =~ m/^\./);
    my $fullp= $indir.$fn;
    if (-d $fullp) {
      scanDirForJava( $maindir, $subdir.$fn);  
      }
    elsif ($fn =~ m,\.java$,) { 
      push(@fns, $subdir.$fn); 
      }
    }
  closedir(DIR);
}

sub maskstrings {  # this one is bad
  my $p;
  while( $_[0] =~ m,"([^"]+)",g) {
    $p= $1; $p =~ tr/0-9/x/c; $_[0] =~ s,"([^"]+)",x$px,;
    }
  while( $_[0] =~ m,'([^']+)',g) {
    $p= $1; $p =~ tr/0-9/x/c; $_[0] =~ s,'([^']+)',x$px,;
    }
}

sub maskastring {
  my($j)= @_;
  my ($p, $qq, $q, $e, $b, $c);
  $q = index($j, '\'');
  $qq= index($j, '"');
  if ($q<0 && $qq<0) { return $j; }
  elsif ($q>=0 && ($q<$qq || $qq<0)) { $b= $q;  $c= '\''; }
  else { $b= $qq; $c= '"'; }
  $e= $b+1; 
  ESCAN: {
    $e= index($j,$c,$e);
    if ($e>0) {
      if (substr($j,$e-1,1) eq '\\') { 
        # warn "Backslash in '$j': [".substr($j,$e-1,2)."]\n" if $debug;
        $e++; redo ESCAN; 
        }
      else { $e++; } # skip past $q
      } 
    else { $e= $b+1; } # skip past $q
    }
  $p= substr($j,$b,$e-$b); $p =~ tr/0/x/c; #+1
  $j= substr($j,0,$b) . $p . substr($j,$e); #+1
  # if ($j =~ m,['"],) { $j= maskastring($j);} # let caller do loop
  return $j;
}



sub checkjava {
  my($j, $jo, $inh, $outh)= @_;
  local(*OUT);
  
  $j= checkdepth($j);
  if ($olddepth==0) {
    ## $j is now clean enough to check to check for publics
    
    if (!$outh && $j =~ m,(^|\s)package\s+([\w\_\.]+),) {
      $jpackage= $2;
      my $ppath = $jpackage;
      $ppath =~ s/\./$osfilesep/g;
      $ppath .= $osfilesep;
      if ($ppath ne $packagepath) {
        warn "new package $jpackage ; subpath $ppath\n" 
          if ($oldpackagepath ne $ppath && $debug);
        $packagepath= $ppath;
        }
      }
      
    elsif ($j =~ m,(^|\s)public\s,) {
      my $newname= '';
			($newname, $j, $jo)= getPubName( $inh, $j, $jo);	        
      if ($newname) {
				$outh= startSplitFile($outh, $newname);
        }
      }
      
		elsif (defined %addlist && $j =~ m,(^|\s)(class|interface)\s,) {
			my $newname= '';
			($newname, $j, $jo)= getPubName( $inh, $j, $jo);	
			if ($newname && ($addlist{$newname} || $addlist{"$jpackage.$newname"})) {
				$outh= startSplitFile($outh, $newname);
				}
			}
     	
    }
  outline($outh, $jo);
  return $outh;
}     

sub startSplitFile {
  my($outh, $newname)= @_;
  local(*OUT);
	if ($outh) { close($outh); $outh= ''; }
	$pubname= $newname;
	$pubfile= "$outpath$packagepath$pubname.java";
	mkdirs( $outpath, $packagepath);
	warn "writing to $pubfile\n" if $debug;
	open(OUT,">$pubfile") || die "cant write $pubfile";
	$nwrit++; push(@outfiles, $pubfile);
	$outh= *OUT;  
	print $outh "//$packagepath$pubname.java\n";
	print $outh "//split4javac// $jinfile date=$jindate\n\n";
	print $outh @outsave if scalar(@outsave);
	print $outh "//split4javac// $jinfile line=$atline\n";
	return $outh;
}


sub getPubName {
  my($inh, $j, $jo)= @_;
	my $newname= '';
	my $addline= 0;
ADDPUBLINE: {
	my @wds= split(' ',$j);
	foreach my $w (@wds) {
		next if ($w =~ /^($javareservedpatt)$/);
		$newname= $w; last;
		}
	unless($newname) { 
		## urk - public can be lines above its name
		if ($addline<2) { 
			my $add= <$inh>; $addline++;
			$jo .= $add; $j .= $add;
			$j= checkdepth($j);
			redo ADDPUBLINE; 
			}
		warn "Missed name in $j\n"; 
		}
	}
	return ($newname, $j, $jo);
}


sub split4javac { # $inhand, $injavasrc, $outpath?
  my($inh)= @_;
  
  @outsave= ();  
  $depth= 0;
  $atline= 0;
  $outh= undef; # need global?
  $pubname= ''; # need global?
  $jpackage= '';# need global?
  $oldpackagepath= $packagepath;
  $packagepath= ''; #??
  
	local(*OUT);
  my ( $cc, $cd, $cs,  $j, $jo);
  my $incom= 0;
  
  warn "reading '$jinfile'\n" if $debug;  
  while (<$inh>) {
    $j = $_;  ## parsed line
    $jo= $_;  ## original
    $atline++;
    
  RECHECK: {
    # maskstrings($j) if ($j =~ m,['"],); # -- bad
    while ($j =~ m,['"],) { $j= maskastring($j); }  
    
    if ($incom) {
      ## $cd= index($j,'//'); these don't apply inside of /* */
      $cc= index($j,'*/');
      # if ($cd>=0 && ($cd<$cc || $cc<0)) { $j= substr($j,0,$cd); } else
      if ($cc>=0) { 
        $j= substr($j,0,$cc); 
        my $jlen= length($j);
        my $jo1= substr($jo, 0, $jlen );
        outline($outh, $jo1); # dump last of comment
        
        $incom= 0;
        $jo= substr($jo, $jlen, length($jo) - $jlen);
        $j= $jo;  
        redo RECHECK;
        }
      }
    else {
      $cd= index($j,'//');
      $cc= index($j,'/*');
      if ($cd>=0 && ($cd<$cc || $cc<0)) { $j= substr($j,0,$cd); }
      elsif ($cc>=0) { 
        $j= substr($j,0,$cc); 
        my $jlen= length($j);
        my $jo1= substr($jo, 0, $jlen );
        $outh= checkjava( $j, $jo1, $inh, $outh); # need to check part before cmt
        
        $incom= 1;
        $jo= substr($jo, $jlen, length($jo) - $jlen);
        $j= $jo; ## need to reprocess ? yes
        redo RECHECK; ## urk - handle /* blah */  BUT need to also check pre /* for java
        }
      }
    }
    
    if ($incom) {
      outline($outh, $jo);
      }
    else {
      $outh= checkjava( $j, $jo, $inh, $outh);
      }
    }
    
  if (!$outh && ( scalar(@outsave) ) ) {   
    warn "\nError: failed to write any publics for '$jinfile'\n";
    warn " n outsaved=".scalar(@outsave)."\n";  
    $pubname= $jinfile;
    my $at = rindex($pubname,$osfilesep);
    if ($at>=0) { $pubname= substr($pubname,$at+1); }
    $pubfile= "$outpath$packagepath$pubname";
    mkdirs( $outpath, $packagepath);
    warn "writing to $pubfile\n" if $debug;
    open(OUT,">$pubfile") || die "cant write $pubfile";
    $outh= *OUT;  $nwrit++; push(@outfiles, $pubfile);
    print $outh "//$packagepath$pubname\n";
    print $outh "//split4javac// $jinfile date=$jindate\n\n";
    print $outh @outsave if scalar(@outsave);
    print $outh "//split4javac// $jinfile line=$atline\n";
    outline($outh, "\n");
    }
    
  if ($outh) { close($outh); $outh= ''; }
}


sub checkdepth {
  ## don't care about any depth > 1 ? but need to count all {} pairs
  my ($j)= @_;
  my ($bo, $bc);
  $bo= index($j,'{');
  $bc= index($j,'}');
  my $isopen= ($bo>=0 && ($bc<0 || $bc>$bo));
  my $cbo= $j =~ tr/{/{/;
  my $cbc= $j =~ tr/}/}/;
  my $newdepth = $depth + $cbo - $cbc;
  if ($newdepth < 0) {
    die "bracket depth < 0 at ".$j."[$atline] of $jinfile \n";
    $newdepth= 0;
    }
  if ($depth==0 && $isopen) {
    $j= substr($j,0, $bo); 
    $olddepth= $depth;
    }
  else { $olddepth= $newdepth; } #??
  $depth= $newdepth;
  return $j;
}

sub mkdirs {
  my($maind, $subd)= @_;
  my $dd='';
  my @subd= split(/$osfilesep/,$subd);
  foreach my $d (@subd) {
    $dd .= $d . $osfilesep;
  	my $dnos= "$maind$dd";  $dnos =~ s/$osfilesep$//;
    unless (-d $dnos) { 
      warn "mkdirs $dnos\n" if $debug;
      unless( mkdir( $dnos, 0777)) { die "cant mkdir $dnos\n"; }
      }
    }
}

sub outline { # ($outh, $string)
  my($outh, $string)= @_;
  if (!$string) { }
  elsif ($outh) {
#   if (defined @outsave) { while (shift(@outsave)) { print $outh $_; } @outsave= undef; }
    print $outh $string;
    }
  else {
    push( @outsave, $string);
    }
}

__END__

split4javac --
  in: read by lines, skip count /* */ and //-- eol
  
      count {} pairs, only want top level  
#----------

$backslash= '\\';
# print "bs = '$backslash' \n";
# exit;

$pat="else if (s.charAt(e)=='\\'') { at++; e= s.indexOf('\\'',at+1); }";
$mpat= $pat;
 
print "Pattern: '$pat'\n";
while ($mpat =~ m,['"],)  { $mpat= maskastring1($mpat); }
print "Masked : '$mpat'\n";

sub maskastring1 {
  my($j)= @_;
  my ($p, $qq, $q, $e, $b, $c);
  $q = index($j, '\'');
  $qq= index($j, '"');
  if ($q<0 && $qq<0) { return $j; }
  elsif ($q>=0 && ($q<$qq || $qq<0)) { $b= $q;  $c= '\''; }
  else { $b= $qq; $c= '"'; }
  $e= $b+1; 
  ESCAN: {
#   my $e1= index($j,$c,$e);
#   warn " index('$j','$c',$e) = $e1\n";
#   $e= $e1;
    $e= index($j,$c,$e);
    if ($e>0) {
      if (substr($j,$e-1,1) eq '\\') { 
        # warn "Backslash in '$j': [".substr($j,$e-1,2)."]\n" if $debug;
        $e++; redo ESCAN; 
        }
      else { $e++; } # skip past $q
      } 
    else { $e= $b+1; } # skip past $q
    }
  $p= substr($j,$b,$e-$b); $p =~ tr/0/x/c; #+1
  $j= substr($j,0,$b) . $p . substr($j,$e); #+1
  # if ($j =~ m,['"],) { $j= maskastring($j);}
  return $j;
}


exit;
#--------

  
  
======== Readseq source split =============
# adding split for 'iubio.readseq.TestBiobase'
# adding split for 'iubio.readseq.OutBiobase'
# adding split for 'iubio.readseq.TestGcgBase'
# adding split for 'iubio.readseq.GcgOutBase'
# adding split for 'iubio.readseq.PaupOutBase'
# adding split for 'iubio.readseq.PhylipSeqWriter'
# adding split for 'iubio.readseq.ReadseqException'
# adding split for 'iubio.readseq.RsInput'
# adding split for 'iubio.readseq.ToDegappedBase'
# adding split for 'iubio.readseq.ToLowercaseBase'
# adding split for 'iubio.readseq.ToUppercaseBase'
# adding split for 'iubio.readseq.ToTranslatedBase'
# adding split for 'iubio.readseq.PrettySeqWriter'
# adding split for 'iubio.readseq.PearsonSeqWriter'
# reading 'src:Acme:Fmt.java'
# new package Acme ; subpath Acme:
# mkdirs MacHome:rseq-split7:Acme
# writing to MacHome:rseq-split7:Acme:Fmt.java
# reading 'src:readseqmain.java'
# writing to MacHome:rseq-split7:run.java
# writing to MacHome:rseq-split7:help.java
# writing to MacHome:rseq-split7:app.java
# writing to MacHome:rseq-split7:cgi.java
# reading 'src:iubio:bioseq:BaseKind.java'
# new package iubio.bioseq ; subpath iubio:bioseq:
# mkdirs MacHome:rseq-split7:iubio
# mkdirs MacHome:rseq-split7:iubio:bioseq
# writing to MacHome:rseq-split7:iubio:bioseq:BaseKind.java
# reading 'src:iubio:bioseq:Bioseq.java'
# writing to MacHome:rseq-split7:iubio:bioseq:Bioseq.java
# reading 'src:iubio:readseq:BioseqDoc.java'
# new package iubio.readseq ; subpath iubio:readseq:
# mkdirs MacHome:rseq-split7:iubio:readseq
# writing to MacHome:rseq-split7:iubio:readseq:BioseqDocVals.java
# writing to MacHome:rseq-split7:iubio:readseq:BioseqDoc.java
# reading 'src:iubio:readseq:BioseqDocItems.java'
# writing to MacHome:rseq-split7:iubio:readseq:PrintableDocItem.java
# writing to MacHome:rseq-split7:iubio:readseq:DocItem.java
# writing to MacHome:rseq-split7:iubio:readseq:FeatureNote.java
# writing to MacHome:rseq-split7:iubio:readseq:FeatureItem.java
# reading 'src:iubio:readseq:XmlDoc.java'
# writing to MacHome:rseq-split7:iubio:readseq:XmlDoc.java
# reading 'src:iubio:readseq:BioseqReaderIface.java'
# writing to MacHome:rseq-split7:iubio:readseq:BioseqIoIface.java
# writing to MacHome:rseq-split7:iubio:readseq:MessageApp.java
# writing to MacHome:rseq-split7:iubio:readseq:BioseqReaderIface.java
# writing to MacHome:rseq-split7:iubio:readseq:OutBiobaseIntf.java
# writing to MacHome:rseq-split7:iubio:readseq:BioseqWriterIface.java
# reading 'src:iubio:readseq:BioseqRecord.java'
# writing to MacHome:rseq-split7:iubio:readseq:BioseqRecord.java
# reading 'src:iubio:readseq:BlastOutputFormat.java'
# writing to MacHome:rseq-split7:iubio:readseq:BlastOutputFormat.java
# reading 'src:iubio:readseq:CommonSeqFormat.java'
# writing to MacHome:rseq-split7:iubio:readseq:PlainSeqFormat.java
# writing to MacHome:rseq-split7:iubio:readseq:IgSeqFormat.java
# writing to MacHome:rseq-split7:iubio:readseq:PearsonSeqFormat.java
# writing to MacHome:rseq-split7:iubio:readseq:PearsonSeqWriter.java
# writing to MacHome:rseq-split7:iubio:readseq:GenbankSeqFormat.java
# writing to MacHome:rseq-split7:iubio:readseq:PirSeqFormat.java
# writing to MacHome:rseq-split7:iubio:readseq:NbrfSeqFormat.java
# writing to MacHome:rseq-split7:iubio:readseq:EmblSeqFormat.java
# writing to MacHome:rseq-split7:iubio:readseq:FitchSeqFormat.java
# writing to MacHome:rseq-split7:iubio:readseq:ZukerSeqFormat.java
# writing to MacHome:rseq-split7:iubio:readseq:Asn1SeqFormat.java
# writing to MacHome:rseq-split7:iubio:readseq:StriderSeqFormat.java
# writing to MacHome:rseq-split7:iubio:readseq:GcgSeqFormat.java
# writing to MacHome:rseq-split7:iubio:readseq:TestGcgBase.java
# writing to MacHome:rseq-split7:iubio:readseq:GcgOutBase.java
# writing to MacHome:rseq-split7:iubio:readseq:AcedbSeqFormat.java
# reading 'src:iubio:readseq:InterleavedSeqReader.java'
# writing to MacHome:rseq-split7:iubio:readseq:InterleavedSeqReader.java
# writing to MacHome:rseq-split7:iubio:readseq:InterleavedSeqWriter.java
# writing to MacHome:rseq-split7:iubio:readseq:Phylip2SeqFormat.java
# writing to MacHome:rseq-split7:iubio:readseq:PhylipSeqFormat.java
# writing to MacHome:rseq-split7:iubio:readseq:PhylipSeqWriter.java
# writing to MacHome:rseq-split7:iubio:readseq:ClustalSeqFormat.java
# writing to MacHome:rseq-split7:iubio:readseq:OlsenSeqFormat.java
# writing to MacHome:rseq-split7:iubio:readseq:MsfSeqFormat.java
# writing to MacHome:rseq-split7:iubio:readseq:PaupSeqFormat.java
# writing to MacHome:rseq-split7:iubio:readseq:PaupOutBase.java
# writing to MacHome:rseq-split7:iubio:readseq:PrettySeqFormat.java
# writing to MacHome:rseq-split7:iubio:readseq:PrettySeqWriter.java
# reading 'src:iubio:readseq:BioseqReader.java'
# writing to MacHome:rseq-split7:iubio:readseq:BioseqReader.java
# writing to MacHome:rseq-split7:iubio:readseq:TestBiobase.java
# reading 'src:iubio:readseq:BioseqWriter.java'
# writing to MacHome:rseq-split7:iubio:readseq:BioseqWriter.java
# writing to MacHome:rseq-split7:iubio:readseq:OutBiobase.java
# writing to MacHome:rseq-split7:iubio:readseq:ToUppercaseBase.java
# writing to MacHome:rseq-split7:iubio:readseq:ToLowercaseBase.java
# writing to MacHome:rseq-split7:iubio:readseq:ToDegappedBase.java
# writing to MacHome:rseq-split7:iubio:readseq:ToTranslatedBase.java
# reading 'src:iubio:readseq:XmlPrintWriter.java'
# writing to MacHome:rseq-split7:iubio:readseq:XmlPrintWriter.java
# reading 'src:iubio:readseq:XmlSeqFormat.java'
# writing to MacHome:rseq-split7:iubio:readseq:XmlSeqFormat.java
# reading 'src:iubio:readseq:XmlSeqReader.java'
# writing to MacHome:rseq-split7:iubio:readseq:XmlSeqReader.java
# reading 'src:iubio:readseq:XmlSeqWriter.java'
# writing to MacHome:rseq-split7:iubio:readseq:XmlSeqWriter.java
# reading 'src:iubio:readseq:GFFSeqFormat.java'
# writing to MacHome:rseq-split7:iubio:readseq:GFFSeqFormat.java
# reading 'src:iubio:readseq:FlatFeatFormat.java'
# writing to MacHome:rseq-split7:iubio:readseq:FlatFeatFormat.java
# reading 'src:iubio:readseq:GenbankDoc.java'
# writing to MacHome:rseq-split7:iubio:readseq:GenbankDoc.java
# reading 'src:iubio:readseq:EmblDoc.java'
# writing to MacHome:rseq-split7:iubio:readseq:EmblDoc.java
# writing to MacHome:rseq-split7:iubio:readseq:SwissDoc.java
# reading 'src:iubio:readseq:BioseqDocImpl.java'
# writing to MacHome:rseq-split7:iubio:readseq:BioseqDocImpl.java
# reading 'src:iubio:readseq:WriteseqOpts.java'
# writing to MacHome:rseq-split7:iubio:readseq:WriteseqOpts.java
# reading 'src:iubio:readseq:ScfTraceFormat.java'
# writing to MacHome:rseq-split7:iubio:readseq:ScfTraceFormat.java
# reading 'src:iubio:readseq:readseqapp.java'
# writing to MacHome:rseq-split7:iubio:readseq:app.java
# reading 'src:flybase:AppResources.java'
# new package flybase ; subpath flybase:
# mkdirs MacHome:rseq-split7:flybase
# writing to MacHome:rseq-split7:flybase:AppResources.java
# reading 'src:flybase:Args.java'
# writing to MacHome:rseq-split7:flybase:Args.java
# reading 'src:flybase:Debug.java'
# writing to MacHome:rseq-split7:flybase:Debug.java
# reading 'src:flybase:DocFormat.java'
# writing to MacHome:rseq-split7:flybase:DocFormat.java
# reading 'src:flybase:Environ.java'
# writing to MacHome:rseq-split7:flybase:Environ.java
# reading 'src:flybase:FastHashtable.java'
# writing to MacHome:rseq-split7:flybase:FastHashtable.java
# reading 'src:flybase:FastProperties.java'
# writing to MacHome:rseq-split7:flybase:FastProperties.java
# reading 'src:flybase:FastStack.java'
# writing to MacHome:rseq-split7:flybase:FastStack.java
# reading 'src:flybase:FastVector.java'
# writing to MacHome:rseq-split7:flybase:FastVector.java
# reading 'src:flybase:Native.java'
# writing to MacHome:rseq-split7:flybase:Native.java
# reading 'src:flybase:OpenString.java'
# writing to MacHome:rseq-split7:flybase:OpenString.java
# reading 'src:flybase:SortVector.java'
# writing to MacHome:rseq-split7:flybase:CompareTo.java
# writing to MacHome:rseq-split7:flybase:Comparator.java
# writing to MacHome:rseq-split7:flybase:ObjectComparator.java
# writing to MacHome:rseq-split7:flybase:StringComparator.java
# writing to MacHome:rseq-split7:flybase:ComparableVector.java
# writing to MacHome:rseq-split7:flybase:CompareStrings.java
# writing to MacHome:rseq-split7:flybase:SortedEnumeration.java
# writing to MacHome:rseq-split7:flybase:QSortVector.java
# writing to MacHome:rseq-split7:flybase:SortVector.java
# reading 'src:flybase:Utils.java'
# writing to MacHome:rseq-split7:flybase:Utils.java
# reading 'src:iubio:bioseq:SeqInfo.java'
# new package iubio.bioseq ; subpath iubio:bioseq:
# writing to MacHome:rseq-split7:iubio:bioseq:SeqInfo.java
# reading 'src:iubio:bioseq:SeqRange.java'
# writing to MacHome:rseq-split7:iubio:bioseq:SeqRangeException.java
# writing to MacHome:rseq-split7:iubio:bioseq:SeqRange.java
# reading 'src:iubio:readseq:SeqFileInfo.java'
# new package iubio.readseq ; subpath iubio:readseq:
# writing to MacHome:rseq-split7:iubio:readseq:SeqFileInfo.java
# reading 'src:iubio:readseq:Testseq.java'
# writing to MacHome:rseq-split7:iubio:readseq:Testseq.java
# reading 'src:iubio:readseq:Writeseq.java'
# writing to MacHome:rseq-split7:iubio:readseq:ReadseqException.java
# writing to MacHome:rseq-split7:iubio:readseq:Writeseq.java
# reading 'src:iubio:readseq:Readseq.java'
# writing to MacHome:rseq-split7:iubio:readseq:Readseq.java
# writing to MacHome:rseq-split7:iubio:readseq:RsInput.java
# reading 'src:iubio:readseq:readseqcgi.java'
# writing to MacHome:rseq-split7:iubio:readseq:cgi.java
# reading 'src:iubio:readseq:readseqrun.java'
# writing to MacHome:rseq-split7:iubio:readseq:help.java
# writing to MacHome:rseq-split7:iubio:readseq:run.java
# reading 'src:iubio:readseq:BioseqFormat.java'
# writing to MacHome:rseq-split7:iubio:readseq:BioseqFormat.java
# writing to MacHome:rseq-split7:iubio:readseq:BioseqFormats.java
# reading 'src:iubio:readseq:BasicBioseqDoc.java'
# writing to MacHome:rseq-split7:iubio:readseq:BasicBioseqDoc.java
# Done -- processed 49 source files to 106 split files.
