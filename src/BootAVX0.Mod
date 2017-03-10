MODULE BootAVX0;      (*NW 13.7.98 / 18.8.99 / 20.2.2007*)
(* Boot linker, generating BootFile, old file format:
    file = {block} lastblock.
    block = len org {codeword}.
    lastblock = 0 entry.  *)

  IMPORT Files, TextRider, BinaryRider, Out;
  
  TYPE Name = ARRAY 32 OF CHAR;
    Command = RECORD name: Name; offset: INTEGER END;
    Module = POINTER TO ModuleDesc;
      ModuleDesc = RECORD
        name: Name;
        key:  LONGINT;
        dbase, pbase: LONGINT;
        size, refcnt: LONGINT;
        next: Module;
        entries: LONGINT;
        entry: ARRAY 256 OF LONGINT;
        constEntry: LONGINT;
        consts: LONGINT;
        command: ARRAY 64 OF Command;
      END ;

    Linker* = POINTER TO RECORD

      first, last: Module;
      base, heap, descriptorBase, bodyBase, pm: LONGINT;
      W: TextRider.Writer;
      Out: Files.File; Rout: BinaryRider.Writer;
      code: ARRAY 8192*10 OF LONGINT;
      plain, descriptors: BOOLEAN; (*descriptors means contain modules' list*)
      tmpName: ARRAY 255 OF CHAR; (* nc for 'End' and 'Begin' methods *)
      END;
    
    PROCEDURE(e: Linker) InitLinker* (VAR w: TextRider.Writer; plain, descriptors: BOOLEAN);
    BEGIN e.W := w;
      e.plain := plain; e.descriptors := descriptors;
    END InitLinker;
    
    PROCEDURE(e: Linker) SetPos (pos: LONGINT);
    BEGIN
      (*Rout.Update;*) e.Out.Flush;
      IF pos > e.Out.Length () THEN
        (*AosFS.OpenWriter(Rout, Out, Out.Length ());*)
	e.Rout := BinaryRider.ConnectWriter(e.Out); e.Rout.SetPos(e.Out.Length());
        pos := pos - e.Out.Length (); REPEAT e.Rout.WriteChar (0X); DEC (pos) UNTIL pos = 0
      ELSE (*AosFS.OpenWriter(Rout, Out, pos)*)
      e.Rout := BinaryRider.ConnectWriter(e.Out); e.Rout.SetPos(pos);
      END;
    END SetPos;

    PROCEDURE(e: Linker) WriteCodeBlock(len, adr: LONGINT);
      VAR i, pos: LONGINT;
    BEGIN
      i := 0;
      IF e.plain THEN 
      (*Out.String ('e.SetPos (adr - e.base)'); Out.Ln; *)
      e.SetPos (adr - e.base) 
      ELSE 
      (*Out.String ('ELSE'); Out.Ln;*)
      e.Rout.WriteLInt (len); e.Rout.WriteLInt (adr) 
      END;
      WHILE i < len DO 
      e.Rout.WriteInt( SHORT(e.code[i])); (*Out.String('SHORT(e.code['); Out.Int(i,0);Out.String(']=');Out.Int(SHORT(e.code[i]),0); Out.Ln;*)
      INC(i) 
      END;
      IF ~e.plain & (len # 0) THEN e.Rout.WriteLInt( 0) END;
      (*e.Out.Flush;*)
    END WriteCodeBlock; 
    
    PROCEDURE(e: Linker) FixupConst(fixloc, database, codelen: LONGINT);
      VAR instr, fixelem, opcode, ll1, ll2, lh1, lh2, offset, adr, r: LONGINT;
    BEGIN
      IF  fixloc # 0 THEN
        fixelem := e.code[fixloc]  MOD 10000H;  
        WHILE fixelem # 0 DO
          instr := e.code[fixelem];
          opcode := instr DIV 1000H MOD 10H;;
          IF (opcode = 9H) THEN (*LDS, STS, CALL, JUMP*)
            IF (instr DIV 10H MOD 10H # 0) THEN (*LDS, STS*)
              e.code[fixelem+1] := database+e.code[fixelem+1]
            END
          ELSIF opcode = 0EH THEN (*LDI r, address of global variable *)
            ll1 := e.code[fixelem] DIV 100H MOD 10H;
            ll2 := e.code[fixelem] MOD 10H;
            lh1 := e.code[fixelem+1] DIV 100H MOD 10H;
            lh2 := e.code[fixelem+1] MOD 10H;
            offset := lh1*1000H+lh2*100H+ll1*10H + ll2;
            r := e.code[fixelem] DIV 10H MOD 10H;
            adr := database+offset;
            ll1 := adr DIV 10H MOD 10H;
            ll2 := adr MOD 10H;
            lh1 := adr DIV 1000H MOD 10H;
            lh2 := adr DIV 100H MOD 10H;
            e.code[fixelem] := opcode * 1000H + ll1*100H + (e.code[fixelem] DIV 10H MOD 10H)*10H + ll2;
            e.code[fixelem+1] := opcode * 1000H + lh1*100H + (e.code[fixelem+1] DIV 10H MOD 10H)*10H + lh2
          END;
          fixloc := fixloc+1;
          fixelem := e.code[fixloc]  MOD 10000H;
        END
      END
    END FixupConst;

    PROCEDURE(e: Linker) FixupAVR(fixloc, database, progbase,codelen: LONGINT);
      VAR instr, fixelem, opcode, ll1, ll2, lh1, lh2, offset, adr, r: LONGINT;
    BEGIN
      WHILE fixloc # 0 DO        
        fixelem := e.code[fixloc]  MOD 10000H;                
        instr := e.code[fixelem];        
        opcode := instr DIV 1000H MOD 10H;
        IF (opcode = 9H) THEN (*LDS, STS, CALL, JUMP*)
          IF (instr DIV 10H MOD 10H # 0) THEN (*LDS, STS*)
            e.code[fixelem+1] := database+e.code[fixelem+1]
          ELSE            
            e.code[fixelem+1] := progbase DIV 2 +e.code[fixelem+1]
          END
        ELSIF opcode = 0EH THEN (*LDI r, address of global variable OR LDI Z, 0*)
          ll1 := e.code[fixelem] DIV 100H MOD 10H;
          ll2 := e.code[fixelem] MOD 10H;
          lh1 := e.code[fixelem+1] DIV 100H MOD 10H;
          lh2 := e.code[fixelem+1] MOD 10H;
          offset := lh1*1000H+lh2*100H+ll1*10H + ll2;
          r := e.code[fixelem] DIV 10H MOD 10H;
          IF (r=0EH) & (ll1= 0) & (ll2 = 0) THEN
            adr := progbase DIV 2
          ELSE
            adr := database+offset
          END;
          ll1 := adr DIV 10H MOD 10H;
          ll2 := adr MOD 10H;
          lh1 := adr DIV 1000H MOD 10H;
          lh2 := adr DIV 100H MOD 10H;
          e.code[fixelem] := opcode * 1000H + ll1*100H + (e.code[fixelem] DIV 10H MOD 10H)*10H + ll2;
          e.code[fixelem+1] := opcode * 1000H + lh1*100H + (e.code[fixelem+1] DIV 10H MOD 10H)*10H + lh2
        ELSIF opcode = 0BH THEN (*OUT ELPM, r; fix up the ROM address by changing the word address to byte addr and the progbase*)
          ll1 := e.code[fixelem+1] DIV 100H MOD 10H;
          ll2 := e.code[fixelem+1] MOD 10H;
          lh1 := e.code[fixelem+2] DIV 100H MOD 10H;
          lh2 := e.code[fixelem+2] MOD 10H;
          adr := progbase DIV 2 + lh1*1000H+lh2*100H+ll1*10H + ll2;
          IF adr > 10000H THEN
            e.code[fixelem-1] := e.code[fixelem-1]+1
          END;
          ll1 := adr DIV 10H MOD 10H;
          ll2 := adr MOD 10H;
          lh1 := adr DIV 1000H MOD 10H;
          lh2 := adr DIV 100H MOD 10H;
          opcode := e.code[fixelem+1] DIV 1000H MOD 10H;
          e.code[fixelem+1] := opcode * 1000H + ll1*100H + (e.code[fixelem+1] DIV 10H MOD 10H)*10H + ll2;
          e.code[fixelem+2] := opcode * 1000H + lh1*100H + (e.code[fixelem+2] DIV 10H MOD 10H)*10H + lh2
        END;
        fixloc := e.code[fixloc+1]
      END
    END FixupAVR;
    
    PROCEDURE(e: Linker) FixupTDAVR(fixloc, progbase: LONGINT);
      VAR instr, fixelem, opcode, ll1, ll2, lh1, lh2, offset, adr, r: LONGINT;
    BEGIN
      WHILE fixloc # 0 DO        
        fixelem := e.code[fixloc]  MOD 10000H;                
        instr := e.code[fixelem];
        e.code[fixelem] := instr + progbase DIV 2;
        fixloc := e.code[fixloc+1]
      END
    END FixupTDAVR;
    
    PROCEDURE(e: Linker) FixupInterrupt(fixloc, progbase: LONGINT);
      VAR index, adr: LONGINT;
    BEGIN
      WHILE (fixloc # 0) & (e.code[fixloc] # 0) DO
        index := e.code[fixloc] MOD 10000H;
        adr := e.code[fixloc+1] MOD 10000H + progbase DIV 2;
        e.SetPos((index-1)*4+2);
        e.Rout.WriteInt(SHORT(adr));
        fixloc := fixloc+2
      END
    END FixupInterrupt;
    
    PROCEDURE(e: Linker) FixupFMU(fixloc, progbase, codelen: LONGINT; VAR entry: ARRAY OF LONGINT);
      VAR next, entryno: LONGINT;
    BEGIN
      WHILE fixloc # 0 DO
        entryno := e.code[fixloc];
        next := e.code[fixloc+1];
        e.code[fixloc] := 940EH;
        e.code[fixloc+1] := progbase DIV 2 +entry[entryno];
        fixloc := next;
      END
    END FixupFMU;
    
    PROCEDURE(e: Linker) FixupImport(fixloc, database, progbase, codelen: LONGINT; VAR entry: ARRAY OF LONGINT);
      VAR instr, fixelem, opcode, entryno, ll1, ll2, lh1, lh2, offset, adr: LONGINT;
    BEGIN
      WHILE fixloc # 0 DO
        fixelem := e.code[fixloc]  MOD 10000H;        
        instr := e.code[fixelem];
        opcode := instr DIV 1000H MOD 10H;
        IF (opcode = 9H) THEN (*LDS, STS, CALL, JUMP*)
          IF (instr DIV 10H MOD 10H # 0) THEN (*LDS, STS*)
            entryno := e.code[fixelem+1] DIV 100H MOD 100H;
            e.code[fixelem+1] := database+entry[entryno] + e.code[fixelem+1] MOD 100H
          ELSE
            entryno := e.code[fixelem+1];
            e.code[fixelem+1] := progbase DIV 2 +entry[entryno]
          END
        ELSIF opcode = 0EH THEN (*LDI r, address of an imported variabe*)
          ll1 := e.code[fixelem] DIV 100H MOD 10H;
          ll2 := e.code[fixelem] MOD 10H;
          lh1 := e.code[fixelem+1] DIV 100H MOD 10H;
          lh2 := e.code[fixelem+1] MOD 10H;
          entryno := lh1*1000H+lh2*100H+ll1*10H + ll2;
          offset := entry[entryno];
          adr := database+offset;
          ll1 := adr DIV 10H MOD 10H;
          ll2 := adr MOD 10H;
          lh1 := adr DIV 1000H MOD 10H;
          lh2 := adr DIV 100H MOD 10H;
          e.code[fixelem] := opcode * 1000H + ll1*100H + (e.code[fixelem] DIV 10H MOD 10H)*10H + ll2;
          e.code[fixelem+1] := opcode * 1000H + lh1*100H + (e.code[fixelem+1] DIV 10H MOD 10H)*10H + lh2
        END;
        fixloc := e.code[fixloc+1]
      END
    END FixupImport;
    
    PROCEDURE(e: Linker) Fixup(fixloc, offset, base: LONGINT; VAR entry: ARRAY OF LONGINT);
      VAR instr, next, pno, vno, reg, disp: LONGINT;
    BEGIN
      WHILE fixloc # 0 DO
        instr := e.code[fixloc]; next := instr MOD 10000H;
        pno := instr DIV 10000H MOD 100H;
        IF instr DIV 1000000H MOD 100H = 0EBH THEN  (* case  BL *)
          instr := instr DIV 1000000H * 1000000H + (entry[pno] + offset - fixloc - 2) MOD 1000000H
        ELSIF instr DIV 1000000H = 0 THEN (*indir. variable address*) instr := entry[pno] + base
        ELSE (*indir. proc. address*) instr := entry[pno]*4 + base
        END ;
        e.code[fixloc] := instr; fixloc := next
      END
    END Fixup;
    
    PROCEDURE(e: Linker) FixSelf(fixloc, base: LONGINT);
      VAR instr, next: LONGINT;
    BEGIN
      WHILE fixloc # 0 DO
        instr := e.code[fixloc]; next := instr MOD 10000H;
        e.code[fixloc] := instr DIV 10000H + base; fixloc := next
      END
    END FixSelf;

    PROCEDURE^ ThisFile(name: ARRAY OF CHAR): Files.File;
  
    PROCEDURE(e: Linker) ThisMod(VAR modname: ARRAY OF CHAR; VAR success: BOOLEAN): Module;
      VAR mod, imp: Module;
        nofimp, nofentries, codelen, fixuplen, fix, fixtd, fixself, fixselftd, fixconst, ifixup,  i: LONGINT;
        R: BinaryRider.Reader; F: Files.File;
        name: Name;
        key, datasize: LONGINT;
        import: ARRAY 16 OF Module;
        fixroot, tdfixroot: ARRAY 16 OF LONGINT;
        temp: INTEGER;
    BEGIN 
      success := TRUE;
      mod := e.first;
      WHILE (mod # NIL) & (mod.name # modname) DO mod := mod.next END ;
      IF mod = NIL THEN  (*load*)
        e.W.WriteString(" trying to load module with name: "); e.W.WriteString(modname); e.W.WriteLn; (*W.Update;*)
        F := ThisFile(modname);
        IF F # NIL THEN
          (*AosFS.OpenReader(R, F, 0);*)
	  R := BinaryRider.ConnectReader(F); R.SetPos(0);
          NEW(mod); mod.next := NIL; mod.refcnt := 0;
          R.ReadString( mod.name); R.ReadLInt( mod.key);
          
          R.ReadInt(temp); fixconst := temp MOD 10000H;
          
          R.ReadInt( temp); fixself := temp MOD 10000H; 
          R.ReadInt(temp); fixselftd := temp MOD 10000H;
          R.ReadInt(temp); ifixup := temp MOD 10000H;
          
          e.W.WriteString( "module "); e.W.WriteString( mod.name); e.W.WriteHex( mod.key,9);
          e.W.WriteLn(); R.ReadString( name); success := TRUE; i := 0;
          WHILE (name[0] # 0X) & success DO
            R.ReadLInt (key); R.ReadInt (temp); fix := temp MOD 10000H; R.ReadInt(temp); fixtd := temp MOD 10000H;
            e.W.WriteString ("    importing "); e.W.WriteString(name); e.W.WriteHex (key, 9);
            e.W.WriteLInt (fix, 6); e.W.WriteLn; (*W.Update;*)
            imp := e.ThisMod(name, success);
            IF imp # NIL THEN
              IF (key = imp.key) THEN
                import[i] := imp; INC (imp.refcnt); fixroot[i] := fix; tdfixroot[i] := fixtd; INC(i)
              ELSE success := FALSE;
                e.W.WriteString( name); e.W.WriteString( " wrong version");
                e.W.WriteLn(); (*W.Update();*)
              END ;
            ELSE success := FALSE;
              e.W.WriteString( name); e.W.WriteString( " not found");
              e.W.WriteLn();
            END ;
            R.ReadString( name); (*W.Update()*)
          END ;
          nofimp := i;
          IF success THEN
            IF e.first = NIL THEN e.first := mod ELSE e.last.next := mod END; e.last := mod;
            i := 0; R.ReadString( mod.command[i].name);
            WHILE mod.command[i].name[0] # 0X DO  (*skip commands*)
              R.ReadInt( mod.command[i].offset); INC (i);
              R.ReadString( mod.command[i].name);
            END ;
            R.ReadLInt( nofentries); R.ReadInt(temp); mod.entry[0] := temp MOD 10000H; 
            i := 0;
            WHILE i < nofentries DO INC(i); R.ReadInt(temp); mod.entry[i] := temp MOD 10000H END ; INC (i); mod.entry[i] := 0; mod.entries := i;
            mod.dbase := e.heap; R.ReadLInt( datasize); INC (e.heap, datasize); mod.pbase := e.pm;
            R.ReadLInt(mod.consts); mod.consts := mod.consts*2; mod.constEntry := mod.pbase+fixconst*2-mod.consts;
            R.ReadLInt(fixuplen);                   
            R.ReadLInt( codelen); 
            mod.size := (codelen-fixuplen)*2; 
            INC (e.pm, mod.size); i := 0;
            WHILE i < codelen DO
               R.ReadInt(temp); e.code[i] := temp MOD 10000H;  
               INC(i) 
            END ;
            e.FixupConst(fixconst, mod.dbase, codelen);
            e.FixupAVR(fixself, mod.dbase+mod.consts, mod.pbase, codelen); 
            e.FixupTDAVR(fixselftd, mod.pbase);
            e.FixupInterrupt(ifixup, mod.pbase);
            
            i := 0;
            WHILE i < nofimp DO
              IF (import[i]^.name = "FPU") OR (import[i]^.name = "MAU") THEN (*fixup the proc call in FPU AND MAU*)
                e.FixupFMU(fixroot[i], import[i].pbase, codelen, import[i].entry)
              ELSE
                e.FixupImport(fixroot[i], import[i].dbase, import[i].pbase, codelen, import[i].entry);
                e.FixupTDAVR(tdfixroot[i], import[i].pbase)
              END;
              INC(i)
            END ;
            e.W.WriteString( "    loading "); e.W.WriteString( mod.name);
            e.W.WriteLInt( mod.size, 6);
            e.W.WriteHex( mod.dbase,9); e.W.WriteHex( mod.pbase,9);
            e.W.WriteHex( mod.entry[0]*2 + mod.pbase,9);
            e.WriteCodeBlock(mod.size DIV 2, mod.pbase)
          END
        ELSE
          e.W.WriteString( modname); e.W.WriteString( " not found");
          success := FALSE;
        END;
        e.W.WriteLn(); (*W.Update();*)
      END ;
      RETURN mod
    END ThisMod;
  
(* nc entered text block here *)

    PROCEDURE(e: Linker) PutCode(c: LONGINT; VAR index: LONGINT);
    BEGIN
      e.code[index] := c; INC(index)
    END PutCode;
  
    PROCEDURE(e: Linker) Put1 (op, dst, imm: LONGINT; VAR index: LONGINT); (*operations with one register and one immediate*)
    BEGIN
      dst := dst -16;
      e.code[index] := op * 1000H + (imm DIV 10H)*100H + dst*10H+(imm MOD 10H); INC(index)
    END Put1; 
    
    PROCEDURE(e: Linker) Put8(op, dst, a: LONGINT; VAR index: LONGINT); (*IN, OUT, 0<=a<=63*)
    BEGIN
      e.code[index] := (op DIV 10H)*1000H+(op MOD 10H)*800H+(a DIV 10H)*200H+(dst DIV 10H)*100H+(dst MOD 10H)*10H+(a MOD 10H);
      INC(index)
    END Put8;
    
    PROCEDURE(e: Linker) Put11(op, k: LONGINT; VAR index: LONGINT); (* BRBS, BRBC, BRCS, BRL0, BREQ, BRMI, BRVS, BRLT, BRHS, BRTS, BRIE, BRCC, BRSH, BRNE, BRPL, BRVC, BRGE, BRHC, BRTC, BRID*)
    VAR 
      temp1, temp2: LONGINT;
      k1, k2, k3: LONGINT;
    BEGIN
      temp1 := (op DIV 10H) MOD 10H;
      temp2 := op MOD 10H;
      k1 := (k DIV 2H) DIV 10H MOD 4H;
      k2 := (k DIV 2H) MOD 10H;
      k3 := k MOD 2H;
      e.code[index] := (op DIV 100H)*1000H+temp1*400H+k1*100H+k2*10H+k3*8H+temp2;
      INC(index);
    END Put11;

(* end nc *)

    PROCEDURE(e: Linker) Bodies;
    VAR len, bs, rampz, pc0, cStart: LONGINT; mod: Module;
    BEGIN
      len := 0; bs := e.pm; mod := e.first;
      WHILE mod # NIL DO
        IF mod.consts # 0 THEN (*Generate code for moving constants from ROM to RAM*)
          rampz := mod.constEntry DIV 10000H MOD 10H;
          cStart := len;
          e.Put1(0EH, 16, rampz, len);
          e.Put8(0B1H, 16, 3BH, len);
          e.Put1(0EH, 30, mod.constEntry MOD 100H, len);
          e.Put1(0EH, 31, mod.constEntry DIV 100H MOD 100H, len);
          e.Put1(0EH, 26, mod.dbase MOD 100H, len);
          e.Put1(0EH, 27, mod.dbase DIV 100H MOD 100H, len);
          e.Put1(0EH, 16, mod.consts MOD 100H, len);
          e.Put1(0EH, 17, mod.consts DIV 100H MOD 100H, len);
          pc0 := len;
          e.PutCode(9007H, len); (*ELPM R0, Z+*)
          e.PutCode(920DH, len); (*ST X+, R0*)
          e.Put1(5H, 16, 1, len);
          e.Put1(4H, 17, 0, len);
          e.Put11(0F11H, pc0-len-1, len);
          INC(e.pm, (len-cStart)*2)
        END;
        e.code[len] := 940EH;(*CALL*)
        e.code[len+1] := mod.pbase DIV 2 + mod.entry[0];
         INC (len, 2); INC (e.pm, 4);
        mod := mod.next;
      END;
      e.code[len] := 940CH;
      e.code[len+1]:= e.pm DIV 2;
      INC (len, 2); INC (e.pm, 4);
      e.WriteCodeBlock (len, bs);
    END Bodies;
    
(* nc move text block up *)

  
    PROCEDURE(e: Linker) String (VAR str: ARRAY OF CHAR; VAR index: LONGINT);
    VAR i, len: LONGINT;
    BEGIN
      len := 0; WHILE str[len] # 0X DO INC (len) END; i := 0;
      WHILE i <= len DO
        e.code[index] := ORD (str[i]) + ORD (str[i+1]) * 100H;
        INC (index); INC (i, 2)
      END;
    END String;
  
    PROCEDURE(e: Linker) ModuleDescriptors;
    VAR mod: Module; len, prevmod, prevcmd, i, cfix, efix: LONGINT; 
    BEGIN
      mod := e.first; len := 0; prevmod := 0;
      WHILE mod # NIL DO
        (* Module *)
    (*W.String (mod.name); W.String (": "); W.Hex (heap + len * 4,9); W.Ln; W.Update;*)
        e.code[len] := prevmod DIV 2; prevmod := e.pm + len * 2; INC (len);
        e.code[len] := mod.key; INC (len);
        e.code[len] := mod.dbase; INC (len);
        e.code[len] := mod.pbase DIV 2; INC (len);
        e.code[len] := mod.size DIV 2; (*code size of words*) INC (len);
        e.code[len] := mod.refcnt; INC (len);
        cfix := len; INC (len);
        efix := len; INC (len);
        e.String (mod.name, len);
        (* Commands *)
        i := 0; prevcmd := 0;
        WHILE mod.command[i].name[0] # 0X DO
    (*W.String ("   "); W.String (mod.command[i].name); W.String (":"); W.Hex (heap + len * 4,10); W.Hex (mod.command[i].offset,10); W.Ln; W.Update;*)
          e.code[len] := prevcmd DIV 2; prevcmd := e.pm + len * 2; INC (len);
          e.code[len] := mod.command[i].offset; INC (len);
          e.String (mod.command[i].name, len); INC (i)
        END;
        IF i # 0 THEN e.code[len] := 0; INC (len) END; (* sentinel *)
        e.code[cfix] := prevcmd DIV 2;
        e.code[efix] := (e.pm + len * 2) DIV 2; i := 0;
        
      (*W.String ("   Entries:"); W.Ln;*)
        WHILE i # mod.entries DO
      (*W.String ("      "); W.Int (i,0); W.String (": "); W.Hex (mod.entry[i], 0); W.Ln;*)
          e.code[len] := mod.entry[i]; INC (len); INC (i);
        END;
        mod := mod.next;
      END;
      e.WriteCodeBlock (len, e.pm);
      INC (e.pm, len * 2);
      e.code[0] := prevmod DIV 2;
            
      e.WriteCodeBlock (1, e.descriptorBase); 
    END ModuleDescriptors;

    PROCEDURE(e: Linker) AddHeader(fileHeader: ARRAY OF CHAR; VAR success: BOOLEAN);
    VAR
      header: Files.File;
      in: BinaryRider.Reader; res: Files.Result;
      data, i: LONGINT;
    BEGIN
      i := 0;
      IF fileHeader # "" THEN
        header := Files.Old(fileHeader,{Files.read,Files.write},res);
        IF header = NIL THEN
          e.W.WriteString("Could not open header file "); e.W.WriteString(fileHeader); e.W.WriteLn; (*W.Update;*)
          success := FALSE;
        ELSE
           (*AosFS.OpenReader(in, header, 0);*)
	   in := BinaryRider.ConnectReader(header); in.SetPos(0);
           WHILE in.Available() >= 4 DO
             in.ReadLInt(data); e.code[i] := data; INC(e.heap, 4); INC(i);
           END;
          
          e.WriteCodeBlock(i, e.base);
        END;
      END;
    END AddHeader;

    PROCEDURE(e: Linker) Begin* (base: LONGINT; fileOut, fileHeader: ARRAY OF CHAR; VAR success: BOOLEAN);
    VAR
      len: INTEGER; res: Files.Result;
    BEGIN 
      base := 0;
      e.base := base; e.pm:=base; e.heap := 100H; (*heap: starting address of internal SRAM*)
      e.first := NIL; e.last := NIL;
      e.Out := Files.New(fileOut,{Files.read,Files.write},res);  (*AosFS.OpenWriter(Rout, Out, 0);*)
      COPY(fileOut,e.tmpName);
      e.Rout := BinaryRider.ConnectWriter(e.Out); e.Rout.SetPos(0);
      e.AddHeader(fileHeader, success);
      (*Set interrupt vector 0000H~0044H*)
      e.code[0] := 940CH; 
      e.code[1] := 0046H;
      
      FOR len := 2 TO 68 BY 2 DO
        e.code[len] := 940CH;
        e.code[len+1] := 0052H
      END;
      e.WriteCodeBlock(len, base);
      e.pm := e.pm + len*2;
      (*Initialize stack pointer, enable external data memory*)
      len := 11;
      e.code[0] := 2411H; e.code[1] := 0BE1FH; e.code[2] := 0E800H; e.code[3] := 0BF05H; e.code[4] := 0EFCFH;
      e.code[5] := 0E1D0H; e.code[6] := 0BFDEH; e.code[7] := 0BFCDH; e.code[8] := 01DEH; e.code[9] := 0E000H; 
      e.code[10] := 0BF0BH;
      e.WriteCodeBlock(len, e.pm);
      e.pm := e.pm+len*2;
      e.bodyBase := e.pm;
      e.code[0] := 940CH; e.code[1] := 0000H;
      e.WriteCodeBlock(2, e.pm); (*original value is 4, pm. 9.01.2008*)
      e.pm := e.pm+4;
      (* the first word after interrupt vectors and memory initialization contains the pointer to module lists *)
      IF e.descriptors THEN e.descriptorBase := e.pm; INC (e.pm, 2) END
    END Begin;
    
    PROCEDURE(e: Linker) Link*(fileIn: ARRAY OF CHAR; VAR success: BOOLEAN);
    VAR mod: Module;
    BEGIN 
      success := TRUE;
      mod := e.ThisMod(fileIn, success);
    END Link;
    
    PROCEDURE(e: Linker) End*;
    VAR link: LONGINT;
      fileName: ARRAY 255 OF CHAR;
    BEGIN
      IF e.first = NIL THEN 
        e.W.WriteString ("No output");
      ELSE
        IF e.descriptors THEN e.ModuleDescriptors END;
        link := e.pm; e.Bodies;
        IF e.plain THEN 
          e.code[0] := link DIV 2; e.WriteCodeBlock (1, e.bodyBase+2);
          e.code[0] := (e.pm-4) DIV 2; e.WriteCodeBlock(1, 6) (*Set up INT0 Interrupt for assert and traps*)
        ELSE e.WriteCodeBlock (0, link) END;
        COPY(e.tmpName,fileName); (*Out.GetName(fileName); nc Rout.Update();*)e.Out.Flush; e.Out.Register;
        e.W.WriteString("Wrote image file "); e.W.WriteString(fileName); e.W.WriteLn;
        e.W.WriteString( "Output file length ="); e.W.WriteLInt( e.Out.Length(), 8);
        e.W.WriteHex( e.first.entry[0]*2 + e.first.pbase,9); e.W.WriteLn(); (*W.Update();*)
        e.first := NIL; e.last := NIL; e.Out := NIL;
      END;
    END End;
  
  (*END Linker;*)

(* nc commented because of redundancy and issue with unsigned four byte constant

  PROCEDURE Branch (dest, pc: LONGINT): LONGINT;
  BEGIN
   RETURN 0EA000000H + ((dest - pc) DIV 4 - 2) MOD 1000000H
  END Branch;

  PROCEDURE BranchLink (dest, pc: LONGINT): LONGINT;
  BEGIN RETURN 0EB000000H + ((dest - pc) DIV 4 - 2) MOD 1000000H
  END BranchLink;
  
  PROCEDURE BodyBranch (m: Module; pc: LONGINT): LONGINT;
  BEGIN RETURN BranchLink (m.pbase + m.entry[0] * 4, pc);
  END BodyBranch;
end nc *)
  
  PROCEDURE ThisFile(name: ARRAY OF CHAR): Files.File;
    VAR i: INTEGER; res: Files.Result;
  BEGIN i := 0;
    WHILE name[i] # 0X DO INC(i) END ;
    name[i] := "."; name[i+1] := "a"; name[i+2] := "v"; name[i+3] := "r"; name[i+4] := 0X;
    RETURN Files.Old(name,{Files.read,Files.write},res)
  END ThisFile;

END BootAVX0.

(*BootSAX.Link 1000H Output.boot M0~*)
