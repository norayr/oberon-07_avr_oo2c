MODULE FPU;   (*NW 25.11.98 / 28.2.99 / 20.8.2007, Flt. Pt. Unit for SA*)
  IMPORT SYSTEM;
  
  (*This module, called Floating-Point Unit, interprets "integers" as real numbers encoded in
    the IEEE format with a sign bit, an 8-bit exponent e with weight B, and a 23-bit mantissa m:
    x  =  1.m * 2^(e-B)
    The module contains leaf procedures only, and it makes use of some special, inoffocial
    features of the Oberon-SA compiler.
    1. The first asterisk after the symbol PROCEDURE declares a leaf procedure, and subsequent
      asterisks indicate untouched registers at the bottom of the register stack (R11, R10, ...)
    2. Parameters and results are REAL numbers. They are declared of type INTEGER,
      interpreting floating-point numbers as integers in the IEEE 32-bit format.
    3. Function SYSTEM.NULL test for 0.0 (+0 or -0), clearing the sign bit.
    4. Function SYSTEM.XOR serves to obtain the sign for products and quotinets.
    5. Procedure SYSTEM.MULD(x, y, z) yields the 64-bit product <Rx, Rx+1> := y*z
    6. Procedure SYSTEM.ADDC(x, y, z) yields x := y+z+C  (carry from preceding operation).
    The procedures of this module must be in this given order *)

  PROCEDURE Div0*(x, y: INTEGER): INTEGER;   (*y > 0*)  (*1*)
    VAR q, r: INTEGER;
  BEGIN (*ASSERT(y > 0, 7); *)
    r := ABS(x);
    q := 0;
    WHILE r >= y DO
      r := r-y;
      INC(q)
    END;
    IF x < 0 THEN
      q := -q;
      IF r # 0 THEN
        q := q-1
      END
    END
    RETURN q   (*q = quotient, r = remainder*)
  END Div0;
  
  PROCEDURE Mod0*(x, y: INTEGER): INTEGER;   (*y > 0*)  (*2*)
    VAR r: INTEGER;
  BEGIN (*ASSERT(y > 0, 7); *)
    r := ABS(x);
    WHILE r >= y DO
      r := r-y
    END;
    IF (x < 0) & (r # 0) THEN
      r := y-r
    END
    RETURN r   (*q = quotient, r = remainder*)
  END Mod0;
BEGIN
END FPU.

