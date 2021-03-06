MODULE LED;
IMPORT
  SYSTEM;
CONST
  DDRB=17H; PORTB = 18H; LED2=200H; LED3 = 400H; NoLED = 0FFH;
  
PROCEDURE LightLED2*;
VAR x: INTEGER;
BEGIN
  (*light up led 2*)
  SYSTEM.GET(LED2, x);
  SYSTEM.PUT(LED2, x);
  
  (*toggle the latch*)
  SYSTEM.PORTOUT(PORTB, 20H);
  SYSTEM.NOP;
  SYSTEM.PORTOUT(PORTB, 0)
END LightLED2;

PROCEDURE LightLED3*;
VAR
  x: INTEGER;
BEGIN
  (*light up third led*)
  SYSTEM.GET(LED3, x);
  SYSTEM.PUT(LED3, x);
  
  (*toggle the latch*)
  SYSTEM.PORTOUT(PORTB, 20H);
  SYSTEM.NOP;
  SYSTEM.PORTOUT(PORTB, 0)
END LightLED3;

PROCEDURE SwitchOff*;
VAR x: INTEGER;
BEGIN  
  (* Switch off LEDs  *)
  SYSTEM.GET(NoLED, x);
  SYSTEM.PUT(NoLED, x);
  
  (*toggle the latch*)
  SYSTEM.PORTOUT(PORTB, 20H);
  SYSTEM.NOP;
  SYSTEM.PORTOUT(PORTB, 0)
END SwitchOff;

BEGIN
(*set output mode for DDRB*)
  SYSTEM.PORTOUT(DDRB, 20H)
END LED.