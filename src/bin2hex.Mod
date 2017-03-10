MODULE bin2hex;

IMPORT IntStr, ConvTypes, Files, args, TextRider, Out;

PROCEDURE Byte (VAR w: TextRider.Writer; val: LONGINT);
BEGIN w.WriteHex (val MOD 100H, -2);
END Byte;

PROCEDURE ExtendedAddressRecord* (VAR w: TextRider.Writer; extadr: LONGINT);
BEGIN
    w.WriteChar (':'); Byte (w, 2); Byte (w, 0); Byte (w, 0); Byte (w, 4);
    Byte (w, extadr DIV 100H); Byte (w, extadr);
    Byte (w, 100H - (2 + 0 + 0 + 4 + extadr DIV 100H MOD 100H + extadr MOD 100H) MOD 100H); w.WriteLn;
END ExtendedAddressRecord;

PROCEDURE DataRecord* (VAR w: TextRider.Writer; (*CONST*)data: ARRAY OF CHAR; len, offset: LONGINT);
VAR checksum, i: LONGINT;
BEGIN
  checksum := len MOD 100H;
  INC (checksum, offset DIV 100H MOD 100H + offset MOD 100H);
  w.WriteChar (':'); Byte (w, len); Byte (w, offset DIV 100H); Byte (w, offset); Byte (w, 0);
  FOR i := 0 TO len - 1 DO Byte (w, ORD (data[i])); INC (checksum, ORD (data[i])) END;
  Byte (w, 100H - checksum MOD 100H); w.WriteLn;
END DataRecord;

PROCEDURE EndOfFileRecord* (VAR w: TextRider.Writer);
BEGIN w.WriteChar (':'); Byte (w, 0); Byte (w, 0); Byte (w, 0); Byte (w, 1); Byte (w, 255); w.WriteLn;
END EndOfFileRecord;

PROCEDURE ConvertFile* ((*CONST*) source: ARRAY OF CHAR; VAR dest: ARRAY OF CHAR; offset, maxlen: LONGINT);
VAR src, dst: Files.File; r: TextRider.Reader; w: TextRider.Writer; extadr: LONGINT; res : Files.Result;
  c: CHAR; len: LONGINT; data: POINTER TO ARRAY (*maxlen + 1*) OF CHAR;
BEGIN
  NEW(data, maxlen+1);
  src := Files.Old (source, {Files.read, Files.write}, res); dst := Files.New (dest, {Files.read, Files.write}, res);
  r := TextRider.ConnectReader(src); w := TextRider.ConnectWriter(dst);
  r.SetPos(0); w.SetPos(0);
  
  extadr := offset DIV 10000H;
  IF extadr # 0 THEN ExtendedAddressRecord (w, extadr); END;

  REPEAT  
    len := 0;
    LOOP
      r.ReadChar (c); IF r.res # Files.done THEN EXIT END;
      data[len] := c; INC (len); IF len = maxlen THEN EXIT END;
    END;
    
    IF len # 0 THEN DataRecord (w, data^, len, offset) END;

    INC (offset, len);
    IF offset DIV 10000H # extadr THEN
      extadr := offset DIV 10000H;
      ExtendedAddressRecord (w, extadr);
    END;
  UNTIL r.res # Files.done;
    
  EndOfFileRecord (w);

  (*w.Update ();*)
  dst.Close;

END ConvertFile;
PROCEDURE Showhelp;

BEGIN
Out.String ("Bin2Hex is avr atmel binary to hex format converter"); Out.Ln;
Out.String ("(c) copyright Liu Ling 2007"); Out.Ln;
Out.String ("ported to linux with ooc (ooc.sf.net) oberon-2 compiler "); Out. Ln;
Out.String ("by Norayr Chilingaryan");
Out.Ln; Out.Ln;
Out.String ("usage:");
Out.Ln;
Out.String ("bin2hex sourcefile destfile"); Out.Ln;
Out.String ("   or"); Out.Ln;
Out.String ("bin2hex sourcefile destfile offset maxlen"); Out.Ln;
Out.String ("  where offset and maxlen must be numbers"); Out.Ln;
Out.Ln;
Out.String ("have a nice day"); Out.Ln;
Out.Ln;
END Showhelp;

PROCEDURE Convert*(* (context: Commands.Context)*);
VAR 
  source, dest, str: ARRAY 255 OF CHAR;
  offset, maxlen: LONGINT; res : ConvTypes.ConvResults;
BEGIN
  
  IF args.argscount() < 2 THEN Out.String ("Error processing: wrong number of arguments"); Out.Ln; Showhelp; HALT(0) END;
  args.arg (1, source);
  args.arg (2, dest);
  IF args.argscount() = 4 THEN
  args.arg(3, str); IntStr.StrToInt(str, offset, res);
  IF res # IntStr.strAllRight THEN Showhelp; HALT(0); END;
  args.arg(4, str);IntStr.StrToInt (str, maxlen, res);
  IF res # IntStr.strAllRight THEN Showhelp; HALT(0); END;
  (*
  context.arg.GetString (source);
  context.arg.GetString (dest);
  context.arg.GetInteger (offset, TRUE); IF context.arg.res # AosIO.Ok THEN offset := 0 END;
  context.arg.GetInteger (maxlen, TRUE); IF context.arg.res # AosIO.Ok THEN maxlen := 255 END;*)
  ELSE
  offset := 0;
  maxlen := 255
  END;


  ConvertFile (source, dest, offset, maxlen)
END Convert;
BEGIN Convert
END bin2hex.
