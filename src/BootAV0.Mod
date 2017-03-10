MODULE BootAV0;      (*NW 13.7.98 / 18.8.99 / 20.2.07  Boot linker for Strong Arm*)
  IMPORT Files, TextRider, BinaryRider    (* AosSerials *) (* fof removed  Files, Texts, Oberon, V24 *) ;

(* V24:
  PROCEDURE Receive (portNo: LONGINT; VAR x: SYSTEM.BYTE; VAR res: LONGINT);
  PROCEDURE Send(portNo: LONGINT; x: SYSTEM.BYTE; VAR res: LONGINT);
  PROCEDURE Start(portNo, bps, data, parity, stop: LONGINT; VAR res: LONGINT); *)
  
  (* fof replaced 
    Texts.WriteInt(W, => W.Int(
    Texts.WriteLn(W => W.Ln(
    Texts.WriteString(W, =>  W.String(
    Texts.WriteHex(W, => W.Hex(
    Texts.Write(W, => W.Char(
    Texts.Append(Oberon.Log, W.buf) => W.Update()
    Texts.Writer => AosIO.Writer 
    Files.File => AosFS.File
    Files.Rider => AosFS.Reader
    Files.Old => AosFS.Old 
    Files.Set => AosFS.OpenReader
    Files.ReadLInt(R, => R.RawLInt(
    Files.ReadString(R, => R.RawString( 

    V24.Available(port  => port.Available(
    V24.Receive(port, => port.ReceiveChar(
    V24.Send(port, => port.SendChar(
    
  *) 

  CONST portNo= 1; (* fof *)
  TYPE Name = ARRAY 32 OF CHAR;
    Module = POINTER TO ModuleDesc;
      ModuleDesc = RECORD
        name: Name;
        key:  LONGINT;
        dbase, pbase: LONGINT;
        next: Module;
        entry: ARRAY 60 OF LONGINT
      END ;

  VAR 
    (*port: AosSerials.Port; (* fof *) *)
    root: Module;
    base, org, res: LONGINT;
    listflag: BOOLEAN;
    W: TextRider.Writer;
    code: ARRAY 8192 OF LONGINT;

  PROCEDURE ThisFile(name: ARRAY OF CHAR): Files.File;
    VAR i: INTEGER; res: Files.Result;
  BEGIN i := 0;
    WHILE name[i] # 0X DO INC(i) END ;
    name[i] := "."; name[i+1] := "a"; name[i+2] := "r"; name[i+3] := "m"; name[i+4] := 0X;
    RETURN Files.Old(name,{Files.read,Files.write},res)
  END ThisFile;

(* nc
  PROCEDURE SendWord(x: LONGINT);
    VAR i: INTEGER;
  BEGIN i := 4;
    REPEAT port.SendChar( CHR(x), res); x := x DIV 100H; DEC(i) UNTIL i = 0
  END SendWord;

  PROCEDURE SendCode(len, adr, entry: LONGINT);
    VAR i, del, xsum: LONGINT; ch: CHAR;
  BEGIN
    WHILE port.Available() > 0 DO port.ReceiveChar( ch, res) END ;
    SendWord(len*4); SendWord(adr); SendWord(entry);
    xsum := len*4 + adr + entry; i := 0;
    WHILE i < len DO
      SendWord(code[i]); xsum := code[i] + xsum; INC(i)
    END ;
    SendWord(-xsum); del := 50000;
    REPEAT DEC(del) UNTIL (port.Available() > 0) OR (del = 0);
    IF del > 0 THEN port.ReceiveChar( ch, res); W.Char( ch)
    ELSE W.String( " timeout")
    END
  END SendCode; 
end nc *)

  PROCEDURE ListCode(len, adr, entry: LONGINT);
    VAR i: LONGINT;
  BEGIN W.WriteLn(); i := 0;
    WHILE i < len DO
      W.WriteHex( adr + org,1); W.WriteChar( 9X); W.WriteHex( code[i],1);
      W.WriteLn(); INC(adr, 4); INC(i)
    END ;
    W.WriteString( "Start at"); W.WriteHex( entry,1); W.WriteLn()
  END ListCode;

  PROCEDURE Fixup(fixloc, offset, base: LONGINT; VAR entry: ARRAY OF LONGINT);
    VAR instr, next, pno, vno, reg, disp: LONGINT;
  BEGIN
    WHILE fixloc # 0 DO
      instr := code[fixloc]; next := instr MOD 10000H;
      pno := instr DIV 10000H MOD 100H;
      IF instr DIV 1000000H MOD 100H = 0EBH THEN  (* case  BL *)
        instr := instr DIV 1000000H * 1000000H + (entry[pno] + offset - fixloc - 2) MOD 1000000H
      ELSIF instr DIV 1000000H = 0 THEN (*indir. variable address*) instr := entry[pno] + base
      ELSE (*indir. proc. address*) instr := entry[pno]*4 + base
      END ;
      code[fixloc] := instr; fixloc := next
    END
  END Fixup;
  
  PROCEDURE FixSelf(fixloc, base: LONGINT);
    VAR instr, next: LONGINT;
  BEGIN
    WHILE fixloc # 0 DO
      instr := code[fixloc]; next := instr MOD 10000H;
      code[fixloc] := instr DIV 10000H + base; fixloc := next
    END
  END FixSelf;
  
  PROCEDURE ThisMod(VAR modname: ARRAY OF CHAR): Module;
    VAR mod, imp: Module;
      nofimp, nofentries, codelen, fix, fixself, i: LONGINT;
      R: BinaryRider.Reader; F: Files.File;
      name: Name;
      key, offset, datasize: LONGINT;
      import: ARRAY 16 OF Module;
      fixroot: ARRAY 16 OF LONGINT;
      err: BOOLEAN;
  
  BEGIN mod := root;
    WHILE (mod # NIL) & (mod.name # modname) DO mod := mod.next END ;
    IF mod = NIL THEN  (*load*)
      F := ThisFile(modname);
      IF F # NIL THEN
        (*AosFS.OpenReader(R, F, 0);*)
	R := BinaryRider.ConnectReader(F); R.SetPos(0);	
        NEW(mod); mod.next := root; root := mod;
        R.ReadString( mod.name); R.ReadLInt( mod.key);
        R.ReadLInt( fixself);
        W.WriteString( "module "); W.WriteString( mod.name); W.WriteHex( mod.key,1);
        W.WriteLn(); R.ReadString( name); err := FALSE; i := 0;
        WHILE (name[0] # 0X) & ~err DO
          imp := ThisMod(name);
          IF imp # NIL THEN
            IF key = imp.key THEN
              import[i] := imp; fixroot[i] := fix; INC(i)
            ELSE err := TRUE;
              W.WriteString( name); W.WriteString( " wrong version");
              W.WriteLn(); (*W.Update()*)
            END ;
          ELSE err := TRUE;
            W.WriteString( name); W.WriteString( " not found");
            W.WriteLn()
          END ;
          R.ReadString( name); (*W.Update()*)
        END ;
        nofimp := i;
        IF ~err THEN
          R.ReadString( name);
          WHILE name[0] # 0X DO  (*commands; not yet implemented*)
            R.ReadLInt( offset); R.ReadString( name)
          END ;
          R.ReadLInt( nofentries); R.ReadLInt( mod.entry[0]); i := 0;
          WHILE i < nofentries DO INC(i); R.ReadLInt( mod.entry[i]) END ;
          mod.dbase := base; R.ReadLInt( datasize); base := base + datasize; mod.pbase := base;
          R.ReadLInt( codelen); base := base + codelen*4; i := 0;
          WHILE i < codelen DO R.ReadLInt( code[i]); INC(i) END ;
          FixSelf(fixself, mod.pbase); i := 0;
          WHILE i < nofimp DO
            offset := import[i].pbase - mod.pbase;
            Fixup(fixroot[i], (import[i].pbase - mod.pbase) DIV 4, import[i].pbase, import[i].entry); INC(i)
          END ;
          W.WriteString( "    loading "); W.WriteString( mod.name);
          W.WriteLInt( codelen*4, 6);
          W.WriteHex( mod.dbase,1); W.WriteHex( mod.pbase,1);
          W.WriteHex( mod.entry[0]*4 + mod.pbase,1);
          IF ~listflag THEN (* SendCode(codelen, mod.pbase, mod.entry[0]*4 + mod.pbase)   nc *)
          ELSE ListCode(codelen, mod.pbase, mod.entry[0]*4 + mod.pbase)
          END ;
          W.WriteLn(); (*W.Update()*)
        END
      ELSE W.WriteString( name); W.WriteString( " not found");
        W.WriteLn(); (*W.Update()*)
      END
    END ;
    RETURN mod
  END ThisMod;

  PROCEDURE Link*(i: LONGINT; file: ARRAY OF CHAR);
  VAR main: Module;   
  BEGIN
    listflag := i < 0; base := ABS(i);
    main := ThisMod(file); root := NIL; 
  END Link;
  
  PROCEDURE Init*(VAR w: TextRider.Writer);
  BEGIN
    W := w; 
  END Init;
  
  (* fof moved to gui dependent modules OSACompiler and OSACompiler0  
  PROCEDURE Link*;
    VAR main: Module; S: Texts.Scanner;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Int THEN
      listflag := S.i < 0; base := ABS(S.i); Texts.Scan(S);
      IF S.class = Texts.Name THEN main := ThisMod(S.s); root := NIL END
    END
  END Link;
  *) 

  (* nc
  PROCEDURE Start*;
  BEGIN 
    port := AosSerials.GetPort(portNo);
    IF port # NIL THEN
      port.Open(19200, 8, AosSerials.ParNo, AosSerials.Stop1, res)
    END;
  END Start;
  *)
  
BEGIN (* fof removed * Texts.OpenWriter(W); *) root := NIL; (*Start nc *)
END BootAV0.

