MODULE aol;
IMPORT  Files, args, ConvTypes, IntStr, Out, TextRider, StdChannels,
BootSAX0 := BootAVX0;

PROCEDURE Showhelp;
BEGIN
Out.String ('usage:'); Out.Ln;
Out.String ('oal startaddress(decimal) Outputfilename Mainmodulename'); Out.Ln;
Out.String ('example:'); Out.Ln;
Out.String (' oal 0 out.bin mainmodulename'); Out.Ln;

END Showhelp;


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
  *)
  PROCEDURE LinkX(VAR linker: BootSAX0.Linker(*; addHeaderFile: BOOLEAN*));  
  VAR   fileOut,fileIn, fileHeader: ARRAY 256 OF CHAR; base: LONGINT;
    success: BOOLEAN; intRes: LONGINT;
    str : ARRAY 255 OF CHAR; res : ConvTypes.ConvResults;
  BEGIN
    success := TRUE;
    (*
    IF addHeaderFile THEN
      context.arg.GetString( fileHeader );
    ELSE*)
      fileHeader := "";
    (*END;*)
    IF args.argscount() < 3 THEN Out.String ('Error processing: wrong number of arguments'); Out.Ln; Showhelp; HALT(0); END;
    args.arg(1, str);
    IntStr.StrToInt(str, base, res);
    IF res # IntStr.strAllRight THEN Showhelp; HALT(0) END;
    args.arg(2, fileOut); 
    Out.String ('first arg is '); Out.Int(base, 0); Out.Ln;
    Out.String ('second arg is '); Out.String (fileOut); Out.Ln;
    (*context.arg.GetInteger( base, TRUE );  
    context.arg.GetString( fileOut );*)
    (*Files.Delete(fileOut, intRes);*)        (* Try to delete an existing output file *)
    linker.Begin (base, fileOut, fileHeader, success);
    args.arg(3, fileIn);
    Out.String ('3 '); Out.String (fileIn); Out.Ln;
    linker.Link (fileIn, success);
    (*
    WHILE (context.arg.res = AosIO.Ok) & success DO
      context.arg.GetString( fileIn );
      IF fileIn[0] # 0X THEN linker.Link (fileIn, success) END;
    END;*)
    IF success THEN linker.End; END;
  END LinkX; 
 (* 
  PROCEDURE LinkXFile*( context: Commands.Context );
  VAR linker: BootSAX0.Linker;
  BEGIN NEW (linker, log, FALSE, TRUE); linker.InitLinker; (* nc translation from ao init procedure *)
    LinkX(linker,FALSE, context)
  END LinkXFile;
  *)
  PROCEDURE LinkXLoader*;
  VAR linker: BootSAX0.Linker;
  w: TextRider.Writer;
  BEGIN 
  w := TextRider.ConnectWriter(StdChannels.stderr);
  NEW (linker); linker.InitLinker(w, TRUE, FALSE); (* nc '&' issue *)
    LinkX(linker);
  END LinkXLoader;
  (*
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
BEGIN 
LinkXLoader;
END aol.
