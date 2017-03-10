MODULE BTnodeIO;  (*UART comm.  Ling Liu 20.8 2008*)
  IMPORT SYSTEM;
  
  PROCEDURE Rec*(VAR ch: CHAR);
  BEGIN
    REPEAT UNTIL SYSTEM.BITIO(0BH, 7);
    SYSTEM.PORTIN(0CH, ch)
  END Rec;

  PROCEDURE Send*(ch: CHAR);
  BEGIN
    REPEAT UNTIL SYSTEM.BITIO(0BH, 5);
    SYSTEM.PORTOUT(0CH, ch);
  END Send;
  
  PROCEDURE SendChar*(ch: CHAR);
  BEGIN
    Send(2X);
    Send(ch)
  END SendChar;
  
  PROCEDURE SendInt*(k: INTEGER);
    VAR i, j: INTEGER; 
  BEGIN
    Send(1X);
    i := 2;
    REPEAT
      i := i-1;
      k := SYSTEM.ROR(k, 8);
      Send(CHR(k));
    UNTIL i = 0
  END SendInt;
  
  PROCEDURE RecInt*(VAR k: INTEGER);
    VAR i, j: INTEGER; ch: CHAR;
  BEGIN
     i := 2; j := 0;
    REPEAT i := i-1; Rec(ch); j  := SYSTEM.LSL(j,8)+ORD(ch) UNTIL i = 0;
    k := j
  END RecInt;
  
  PROCEDURE RecStr*(VAR s: ARRAY OF CHAR);
    VAR i: INTEGER; ch: CHAR;
  BEGIN
    i := 0;
    REPEAT
      Rec(ch);
      s[i] := ch;
      INC(i)
    UNTIL ch = 0X
  END RecStr;
  
  
  
  PROCEDURE SendStr*(CONST s: ARRAY OF CHAR);
    VAR i: INTEGER; ch: CHAR;
  BEGIN
    Send(4X);
    i := 0;
    REPEAT
      ch := s[i];
      INC(i); Send(ch)
    UNTIL ch = 0X
  END SendStr;
  
  PROCEDURE Line*;
  BEGIN
    Send(6X)
  END Line;
  
  PROCEDURE End*;
  BEGIN
    Send(7X)
  END End; 
  
BEGIN (*initialize USART*)
  (*Set baud rate*)
  SYSTEM.PUT(90H, 0H);
  SYSTEM.PORTOUT(09H, 3H);
  
  (*Enable receive and transmit*)
  SYSTEM.PORTOUT(0AH, 18H);
  
  (*specialization for BTnode*)
  SYSTEM.PORTOUT(2H, 4H); (*cbi DDRE 4; sbi DDRE 2*)
  SYSTEM.PORTOUT(3H, 1H)

END BTnodeIO.



