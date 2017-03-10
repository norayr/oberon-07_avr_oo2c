MODULE aoc;   (**  AUTHOR "fof"; PURPOSE "";  **)

IMPORT (*AosIO, AosTexts, Commands, AosTextUtilities, 
  UTF8Strings, AosFS, AosOut,*)
  Files, TextRider, (*ProgramArgs,*) args, StdChannels, Out,
  BootSA0 := BootAV0, BootSAX0 := BootAVX0, OSAS0 := OAVS0, OSAP0 := OAVP0;  

VAR 
  log: TextRider.Writer;   (* logger to AosOut *)
TYPE 
  Buffer = POINTER TO ARRAY OF CHAR;  
 
   PROCEDURE Showhelp ;
   BEGIN

   Out.String ('usage: '); Out.Ln;
   Out.String ('aoc options modulename'); Out.Ln;
   Out.String ('aoc modulename options'); Out.Ln;
   Out.Ln;
   END Showhelp;

  (* 
  PROCEDURE GetOptions(VAR S: TextRider.Reader;  VAR opts: ARRAY OF CHAR );  
  VAR i: LONGINT;  ch: CHAR;  
  BEGIN 
    i := 0;  
    (*WHILE opts[i] # 0X DO INC( i ) END;  *) Out.Ln; Out.String ('skipping blank');
    REPEAT
       S.ReadChar(ch);
       Out.String ('ch='); Out.Char(ch); Out.Ln;
    UNTIL ch # ' ';  (*ch := S.	Peek();  *) S.ReadChar(ch);
    Out.Ln; Out.String ("ch= "); Out.Char(ch); Out.Ln;
    WHILE (ch = "-") DO  Out.String ("while ch = - DO "); Out.Ln;
      S.ReadChar( ch );   (* skip \ *) Out.String ('read '); Out.Char(ch); Out.Ln;
      S.ReadChar( ch );                Out.String ('read '); Out.Char(ch); Out.Ln;
      WHILE ch > " " DO 
         opts[i] := ch; Out.String ('opts['); Out.Int(i,0); Out.String(']='); Out.Char(ch); Out.Ln;
         INC( i );  Out.String ('inc(i)'); Out.Ln;
         S.ReadChar( ch ) ; Out.String ('read char '); Out.Char(ch); Out.Ln;
      END;  
      opts[i] := " ";  INC( i );  S.ReadLn;  (*ch := S.Peek()*) S.ReadChar(ch);
    END;  
    opts[i] := 0X; Out.String ('opts['); Out.Int(i, 0); Out.String (']=0X'); Out.Ln;
  END GetOptions;  
*)
  PROCEDURE ParseOptions( (*CONST*) VAR options: ARRAY OF CHAR;  breakpc: LONGINT;  
                          VAR log: TextRider.Writer;  VAR newSF: BOOLEAN );  
  VAR i: LONGINT;  ch: CHAR; 


  BEGIN 
    (*defaults*)
    newSF := FALSE;  i := 1;  
    REPEAT 
      ch := options[i];  INC( i );  
      CASE ch OF 
      "s":       newSF := TRUE;  
      ELSE 
        IF ch > " " THEN log.WriteString( "Option not found:" );  log.WriteChar( ch );  log.WriteLn;  END;  
      END;  
    UNTIL ch = 0X;  
  END ParseOptions;  

   PROCEDURE Module*(VAR r: TextRider.Reader; VAR  log: TextRider.Writer;  
                      (*CONST*) VAR options: ARRAY OF CHAR;  breakpc: LONGINT;  VAR error,trapped: BOOLEAN );  
  VAR newSF: BOOLEAN;
  BEGIN  (*{EXCLUSIVE}  *)
    trapped := TRUE;
    ParseOptions( options, breakpc, log, newSF);  OSAP0.Init( r, log, newSF, breakpc );  
    OSAP0.Module;  error := OSAS0.error;  
    trapped := FALSE; 
  (*FINALLY 
    IF trapped THEN 
      error := TRUE; AosOut.String("Compiler trapped"); AosOut.Ln; 
    END;*) 
  END Module;  


  PROCEDURE CompileAsciiFile*( VAR name, opt: ARRAY OF CHAR;  pc: LONGINT;  
                                log: TextRider.Writer;  VAR error,trap: BOOLEAN );  
  VAR f: Files.File;  r: TextRider.Reader;  res : Files.Result;
  BEGIN 
    f := Files.Old( name, {Files.read, Files.write}, res );  
    IF res # Files.done THEN 
      log.WriteString ('file '); log.WriteString( name );  log.WriteString( " not found" );  log.WriteLn;   error := TRUE;  
      RETURN 
    END;  
    log.WriteString( name );  (*AosF.OpenReader( r, f, 0 );  *)
    r := TextRider.ConnectReader(f); r.SetPos(0);
    Module( r, log, opt, pc, error,trap );  
  END CompileAsciiFile;  

  PROCEDURE Compile*;  
  VAR 
    globalOpt, localOpt: ARRAY 32 OF CHAR;  
    count: LONGINT;  
    name: ARRAY 64 OF CHAR;  
    error,trap: BOOLEAN;  
    (*r : TextRider.Reader;*)
  BEGIN
    error := FALSE;  globalOpt := "";  name := ''; localOpt := '';
    (*r := TextRider.ConnectReader(ProgramArgs.args);
    IF r = NIL THEN Out.String ("Error connecting reader to arguments"); Out.Ln; HALT(0); END;
    IF ProgramArgs.args.ArgNumber() < 1 THEN Out.String ("Error processing: wrong number of arguments"); Out.Ln; Showhelp; HALT(0) END;*)
    IF args.argscount() < 1 THEN Out.String ("Error processing: wrong number of arguments"); Out.Ln; Showhelp; HALT(0) END;
    args.arg(1, name); 
    IF ((name[0] = '-') OR (name[0]='/') OR (name[0]='\')) THEN 
    COPY(name, globalOpt); name := '';
    args.arg(2, name);
    ELSE
    args.arg(2, globalOpt);
    END;
 
    (*r.ReadLn; IF r.res # TextRider.done THEN Out.String ('error reading argument'); Out.Ln END;*)
    (*r.ReadString(name); Out.String ('read name='); Out.String (name); Out.Ln;
    IF ((name[0] = '-') OR (name[0]='/') OR (name[0]='\')) THEN 
    COPY(name, globalOpt);
    r.ReadString(name);
    IF r.res # TextRider.done THEN Out.String ('error: no module name provided'); Out.Ln; HALT(0) END;
    ELSE
    r.ReadString(globalOpt);
    END;*)
    (*GetOptions(s, globalOpt );  count := 0;  
    WHILE ~error & (s.res = TextRider.done) DO 
      s.ReadString( name );  
      IF name # "" THEN 
        INC( count );  COPY( globalOpt, localOpt );  GetOptions(s, localOpt );  
	*)
        COPY(globalOpt, localOpt); 
	(*Out.String ("localopt="); Out.String (localOpt); Out.Ln; Out.String ("globalopt="); Out.String (globalOpt); Out.Ln;
	Out.String ('name='); Out.String( name); Out.Ln;*)
	CompileAsciiFile( name, localOpt, MAX( LONGINT ), log, error,trap );  
      (*END;  
    END*)
  END Compile;  
(*
  PROCEDURE Link*( context: Commands.Context );  
  VAR 
    name: ARRAY 64 OF CHAR; base: LONGINT;  
  BEGIN 

    context.arg.GetInteger( base, TRUE );  
    (* 
    log.String( "base=" );  log.Hex( base, 10 );  log.Ln;  
    *)
    BootSA0.Init( log );  context.arg.GetString( name );  
    IF context.arg.res = 0 THEN BootSA0.Link( base, name );  END;  
    
    (* for multiple files: 
    MinosBootLinker.StartLink( base, log );  error := FALSE;  
    WHILE (S.res = 0) & ~error DO 
      S.SkipWhitespace;  S.String( name );  
      IF name # "" THEN MinosBootLinker.LinkModule( name );  ELSE error := TRUE;  END;  
    END;  
    MinosBootLinker.EndLink();  RETURN NIL;  
    *)
  END Link;  
  
  PROCEDURE LinkX( linker: BootSAX0.Linker; addHeaderFile: BOOLEAN; context: Commands.Context );  
  VAR   fileOut,fileIn, fileHeader: ARRAY 256 OF CHAR; base: LONGINT;
    success: BOOLEAN; intRes: LONGINT;
  BEGIN
    success := TRUE;
    
    IF addHeaderFile THEN
      context.arg.GetString( fileHeader );
    ELSE
      fileHeader := "";
    END;
    context.arg.GetInteger( base, TRUE );  
    context.arg.GetString( fileOut );
    AosFS.Delete(fileOut, intRes);        (* Try to delete an existing output file *)
    linker.Begin (base, fileOut, fileHeader, success);
    WHILE (context.arg.res = AosIO.Ok) & success DO
      context.arg.GetString( fileIn );
      IF fileIn[0] # 0X THEN linker.Link (fileIn, success) END;
    END;
    IF success THEN linker.End; END;
  END LinkX; 
  
  PROCEDURE LinkXFile*( context: Commands.Context );
  VAR linker: BootSAX0.Linker;
  BEGIN NEW (linker, log, FALSE, TRUE); linker.InitLinker; (* nc translation from ao init procedure *)
    LinkX(linker,FALSE, context)
  END LinkXFile;
  
  PROCEDURE LinkXLoader*( context: Commands.Context );
  VAR linker: BootSAX0.Linker;
  BEGIN NEW (linker, log, TRUE, FALSE); linker.InitLinker; (* nc '&' issue *)
    LinkX(linker, FALSE, context)
  END LinkXLoader;
  
  PROCEDURE LinkLoad*(base: LONGINT; w: AosIO.Writer; CONST fileOut, fileIn: ARRAY OF CHAR; VAR success: BOOLEAN);
    VAR
      link r: BootSAX0.Linker;
  BEGIN
    NEW (linker, w, TRUE, FALSE); linker.InitLinker; (* nc '&' issue *)
    linker.Begin (base, fileOut, "", success);
    IF success THEN
      linker.Link (fileIn, success);
      IF success THEN
        linker.End
      END
    END
  END LinkLoad;
  
  PROCEDURE LinkXImage*( context:Commands.Context );
  VAR linker: BootSAX0.Linker;
  BEGIN NEW (linker, log, TRUE, TRUE); linker.InitLinker (* nc '&' issue *)
    LinkX(linker, FALSE, context)
  END LinkXImage;
*)
  PROCEDURE SetLog*;  
  BEGIN 
  log := TextRider.ConnectWriter(StdChannels.stderr);
  END SetLog;  

BEGIN 
  SetLog;  
  Compile;
END aoc.
