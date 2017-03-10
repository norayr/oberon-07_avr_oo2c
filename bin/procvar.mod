MODULE procvar;
(*  IMPORT out;*)
  VAR m, n, l: INTEGER;
    f: PROCEDURE (x, y: INTEGER): INTEGER;

  PROCEDURE F(x, y: INTEGER): INTEGER;
  BEGIN RETURN (x + y) * (x -y)
  END F;
  
BEGIN f := F;
  (*AVRIO.RecInt(m); AVRIO.RecInt(n); AVRIO.SendInt(m*m - n*n); *)
  n := 9; l := 8;
  (*out.Int(m*m-n*n);*)
  (*out.Int(f(m, n));*)
  m := f(l,n);
END procvar.
(*
OAVCompiler0.Compile \s Test/Native/Cases/ProcVar.Moa ~

OAVCompiler0.LinkXLoader 0H ProcVar.bin  ProcVar ~

Bin2Hex.Convert ProcVar.bin ProcVar1.hex 0 16 ~

OAVD0.ListFile ProcVar.bin ProcVar.asm ~

TestAVR.ClosePort ~

S.Free TestAVR ~

TestAVR.SR 8 3~
*)