MODULE SecondBlink; (*light up LED 2, 3 in turn every second*)
IMPORT LED, Timer;

BEGIN
  WHILE TRUE DO
     IF ODD(Timer.Seconds) THEN
        LED.LightLED2
    ELSE
        LED.LightLED3
    END
  END
END SecondBlink.

OAVCompiler0.Compile \s Test/Native/BTnodeTimerLED.Moa~

OAVCompiler0.LinkXLoader 0H SecondBlink.bin SecondBlink ~

Bin2Hex.Convert SecondBlink.bin SecondBlink.hex 0 16 ~

