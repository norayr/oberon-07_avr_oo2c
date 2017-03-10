MODULE MAU;   (*Memory Allocation Unit; NW 24.1.2007*)
  (* These procedures must remain in this order!*)
  IMPORT SYSTEM;
  VAR Heap: INTEGER;  (*origin of free space*)
  
  PROCEDURE Alloc*(VAR adr: INTEGER; size: INTEGER);  (*1*)
    (*allocate area from free space*)
  BEGIN
    adr := Heap; Heap := Heap + size
  END Alloc;

  PROCEDURE New*(VAR p: INTEGER; T: INTEGER);   (*2*)
    (*allocate record, add tag field of 1 word with offset -4*)
    VAR size: INTEGER;
  BEGIN
    p := Heap+2;
    SYSTEM.PUT(Heap, T);  (*adr of type descriptor to new record*)
    SYSTEM.GETFR(T, size);    (*obtain record size from type descriptor*)
    Heap := p + size
  END New;
  
BEGIN Heap := 1100H
END MAU.
