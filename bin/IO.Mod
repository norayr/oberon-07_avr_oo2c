MODULE IO;  (*UART comm.  Ling Liu 20.8 2008*)
  IMPORT BTnodeIO;
  
  PROCEDURE Rec*(VAR ch: CHAR);
  BEGIN
    BTnodeIO.Rec(ch)
  END Rec;

  PROCEDURE Send*(ch: CHAR);
  BEGIN
    BTnodeIO.Send(ch)
  END Send;
  
  PROCEDURE SendChar*(ch: CHAR);
  BEGIN
    BTnodeIO.SendChar(ch)
  END SendChar;
  
  PROCEDURE SendInt*(k: INTEGER);
  BEGIN
    BTnodeIO.SendInt(k)
  END SendInt;
  
  PROCEDURE RecInt*(VAR k: INTEGER);
  BEGIN
    BTnodeIO.RecInt(k)
  END RecInt;
  
  PROCEDURE RecStr*(VAR s: ARRAY OF CHAR);
  BEGIN
    BTnodeIO.RecStr(s)
  END RecStr;
  
  
  PROCEDURE SendStr*(CONST s: ARRAY OF CHAR);
  BEGIN
    BTnodeIO.SendStr(s)
  END SendStr;
  
  PROCEDURE Line*;
  BEGIN
    BTnodeIO.Line
  END Line;
  
  PROCEDURE End*;
  BEGIN
    BTnodeIO.End
  END End; 
  
BEGIN (*initialize USART*)
  
END IO.



