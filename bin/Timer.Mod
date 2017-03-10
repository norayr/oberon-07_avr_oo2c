MODULE Timer;
IMPORT SYSTEM;

CONST
  TCCR1B = 2EH; TIMSK = 37H; TCNT1L = 2CH; TCNT1H = 2DH; TIFR = 36H;
  SecondClicks = 110; 

VAR
  Seconds*: INTEGER;
  secondDevisor: INTEGER;
  
PROCEDURE Handle [15];
BEGIN
  IF secondDevisor > 0 THEN
    DEC(secondDevisor);
  ELSE
    INC(Seconds);
    IF Seconds = 60 THEN
      Seconds := 0
    END;
    secondDevisor := SecondClicks;
  END;
    
END Handle;

BEGIN
  Seconds := 0;
  
  SYSTEM.SEI;
  SYSTEM.PORTOUT(TCCR1B, 1); (*set TCCR1B with 1*)
  SYSTEM.PORTOUT(TIMSK, 4); (*out TIMSK, 4; enable timer1 overflow interrupt*)  
  SYSTEM.PORTOUT(TCNT1L, 0); (*out TCNT1L, 0*)
  SYSTEM.PORTOUT(TCNT1H, 0); (*out TCNT1H, 0*)
  SYSTEM.PORTOUT(TIFR, 0); (*out TIFR, 0*)
  
  secondDevisor := SecondClicks;
  
  
END Timer.

