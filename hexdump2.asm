;   Executable name : hexdump2
;   Version         : 1.0
;   Created date    : 13 Dec 2018
;   Last update     : 13 Dec 2018
;   Author          : Brian Hart
;   Description     : A simple hex dump utility demonstrating the use of
;                     assembly language procedures
;
;   Build using these commands:
;       nasm -g -f elf -F stabs hexdump2.asm
;       ld -o hexdump2 hexdump2.o -m elf_i386
;
; This code is from the book "Assembly Language Step by Step: Programming with Linux," 3rd ed.,
; by Jeff Duntemann (John Wiley & Sons, 2009).
;
; The following are equates that define named constants, for enhanced program readability
;
BUFFLEN     EQU 10                  ; Length of buffer, in bytes

SYS_EXIT    EQU 1                   ; Syscall number for sys_exit
SYS_READ    EQU 3                   ; Syscall number for sys_read
SYS_WRITE   EQU 4                   ; Syscall number for sys_write

OK          EQU 0                   ; Operation completed without errors
ERROR       EQU -1                  ; Operation failed to complete; error flag

STDIN       EQU 0                   ; File Descriptor 0: Standard Input
STDOUT      EQU 1                   ; File Descriptor 1: Standard Output
STDERR      EQU 2                   ; File Descriptor 2: Standard Error

EOF         EQU 0                   ; End-of-file reached

SECTION .bss                        ; Section containing uninitialized data

   Buff:    resb    BUFFLEN         ; Buffer to hold data read in

SECTION .data                       ; Section containing initialized data

; Here we have two parts of a single useful data structure, implementing
; the text line of a hex dump utility.  The first part displays 16 bytes in
; hex separated by spaces.  Immediately following is a 16-character line
; delimited by vertical bar characters.  Because they are adjacent, the two
; parts can be referenced separately or as a single contiguous unit.
; Remember that if DumpLin is to be used separately, you must append an
; EOL before sending it to the Linux console.

    DumpLin: db " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00"
    DUMPLEN  EQU $-DumpLin
    ASCLin:  db "|................|",10
    ASCLEN:  EQU $-ASCLin
    FULLLEN: EQU $-DumpLin
    
; The HexDigits table is used to convert numeric values to their hex
; equivalents.  Index by nybble without a scale: [HexDigits+eax]
    HexDigits: db   "0123456789ABCDEF"
    
; This table is used for ASCII character translation, into the ASCII
; portion of the hex dump line, via XLAT or ordinary memory lookup.
; All printable characters "play through" as themselves.  The high 128 
; characters are transalated into ASCII period (2Eh).  The non-printable
; characters in the low 128 are also translated to ASCII period, as is
; char 127.
DotXlat:
    db 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh
    db 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh
    db 20h, 21h, 22h, 23h, 24h, 25h, 26h, 27h, 28h, 29h, 2Ah, 2Bh, 2Ch, 2Dh, 2Eh, 2Fh
    db 30h, 31h, 32h, 33h, 34h, 35h, 36h, 37h, 38h, 39h, 3Ah, 3Bh, 3Ch, 3Dh, 3Eh, 3Fh
    db 40h, 41h, 42h, 43h, 44h, 45h, 46h, 47h, 48h, 49h, 4Ah, 4Bh, 4Ch, 4Dh, 4Eh, 4Fh
    db 50h, 51h, 52h, 53h, 54h, 55h, 56h, 57h, 58h, 59h, 5Ah, 5Bh, 5Ch, 5Dh, 5Eh, 5Fh
    db 60h, 61h, 62h, 63h, 64h, 65h, 66h, 67h, 68h, 69h, 6Ah, 6Bh, 6Ch, 6Dh, 6Eh, 6Fh
    db 70h, 71h, 72h, 73h, 74h, 75h, 76h, 77h, 78h, 79h, 7Ah, 7Bh, 7Ch, 7Dh, 7Eh, 2Eh
    db 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh
    db 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh
    db 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh
    db 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh
    db 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh
    db 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh
    db 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh
    db 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh, 2Eh
    
SECTION .text                       ; Section containing code

;-------------------------------------------------------------------------
; ClearLine   : Clear a hex dump line string to 16 zero values
; UPDATED     : 13 Dec 2018
; IN          : Nothing
; RETURNS     : Nothing
; MODIFIES    : Nothing
; CALLS       : DumpChar
; DESCRIPTION : The hex dump line string is cleared to binary 0 by
;               calling DumpChar 16 times, passing it 0 each time.

ClearLine:
    pushad                          ; Save all of the caller's general-purpose (GP) registers to the stack
    mov edx, 15                     ; We're going to go 16 pokes, counting from zero
.poke:
    xor eax, eax                    ; Tell DumpChar to poke a '0' (it looks at the value of EAX for what to poke)
    call DumpChar                   ; Insert the '0' into the hex dump string
    sub edx, 1                      ; DEC doesn't affect CF!
    jae .poke                       ; Loop back if EDX >= 0
    popad                           ; Restore all of the caller's GP registers from the stack
    ret                             ; Go home
    

;-------------------------------------------------------------------------
; DumpChar    : "Poke" a value into the hex dump line string.
; UPDATED     : 13 Dec 2018
; IN          : Pass the 8-bit value to be poked in EAX.
; RETURNS     : Pass the value's position in the line (0-15) in EDX
; MODIFIES    : EAX, ASCLin, DumpLin
; CALLS       : Nothing
; DESCRIPTION : The value passed in EAX will be put in both the hex dump
;               portion and in the ASCII portion, at the position passed
;               in EDX, represented by a space where it is not a
;               printable character.

DumpChar:
; Push the values that are in the registers EBX and EDI onto the stack.  This is 
; because we will need these registers within this subroutine; however, once we're
; done executing, the caller of this subroutine might have been using EBX and EDI for
; something else.  Therefore, we want to temporarily save the values in these registers
; to the stack (kind of like our "scratch pad") to restore when we're done.
    push ebx                        ; Save caller's EBX
    push edi                        ; Save caller's EDI
; First, we insert the input char into the ASCII portion of the dump line
    mov  bl, BYTE [DotXlat+eax]     ; Translate nonprintables to '.'
    mov  BYTE [ASCLin+edx+1], bl    ; Write to ASCII portion
; Now we insert the hex equivalent of the input char into the hex portion
; of the hex dump line:
    mov  ebx, eax                   ; Save a second copy of the input char
    lea  edi, [edx*2+edx]           ; Calc offset into the hex dump line string (EDX times 3)
; Look up low nybble character and insert it into the hex dump string:
    and  eax, 0000000Fh             ; Mask out all but the low nybble
    mov  al, BYTE [HexDigits+eax]   ; Look up the char equiv. of nybble
    mov  BYTE [DumpLin+edi+2], al   ; Write the char equiv. to the line string
; Look up high nybble character and insert it into the string:
    and  ebx, 000000F0h             ; Mask out all but second-lowest nybble
    shr  ebx, 4                     ; Shift high 4 bits of byte into low 4 bits
    mov  bl, BYTE [HexDigits+ebx]   ; Look up char equiv. of nybble
    mov  BYTE [DumpLin+edi+1], bl   ; Write the char equiv. to the line string
; Done! Let's go home:
    pop  edi                        ; Restore caller's EDI
    pop  ebx                        ; Restore caller's EBX
    ret                             ; Return to caller
    

;-------------------------------------------------------------------------
; PrintLine   : Displays the hex dump line stirng via INT 80h sys_write
; UPDATED     : 13 Dec 2018
; IN          : Nothing
; RETURNS     : Nothing
; MODIFIES    : Nothing
; CALLS       : Kernel sys_write
; DESCRIPTION : The hex dump line string DumpLin is displayed to STDOUT
;               using INT 80h sys_write.  All GP registers are preserved.

PrintLine:
    pushad                          ; Save all of the GP registers of the caller to the stack
    mov  eax, SYS_WRITE             ; Specify sys_write syscall
    mov  ebx, STDOUT                ; Specify File Descriptor 1: Standard output
    mov  ecx, DumpLin               ; Pass offset of line string
    mov  edx, FULLLEN               ; Pass size of the line string
    int  80h                        ; Make kernel call to display line string
    popad                           ; Restore all of the GP registers of the caller back from the stack
    ret                             ; Go home
    

;-------------------------------------------------------------------------
; LoadBuff    : Fills a buffer with data from STDIN via INT 80h sys_read
; UPDATED     : 13 Dec 2018
; IN          : Nothing
; RETURNS     : # of bytes read in EBP
; MODIFIES    : ECX, EBP, Buff
; CALLS       : Kernel sys_read
; DESCRIPTION : Loads a buffer full of data (BUFFLEN bytes) from STDIN
;               using INT 80h sys_read and places it in Buff.  Buffer
;               offset counter ECX is zeroed, because we're starting in
;               on a new buffer full of data.  Caller must test value in
;               EBP: If EBP contains zero on return, we hit EOF on stdin.
;               Less than 0 in EBP on return indicates some kind of error.

LoadBuff:
    push  eax                       ; Save caller's EAX
    push  ebx                       ; Save caller's EBX
    push  edx                       ; Save caller's EDX
    mov   eax, SYS_READ             ; Specify sys_read syscall
    mov   ebx, STDIN                ; Specify File Descriptor 0: Standard Input
    mov   ecx, Buff                 ; Pass offset of the buffer to read to
    mov   edx, BUFFLEN              ; Pass number of bytes to read at one pass
    int   80h                       ; Call sys_read to fill the buffer
    mov   ebp, eax                  ; Save # of bytes read from file for later
    xor   ecx, ecx                  ; Clear buffer pointer ECX to 0
    pop   edx                       ; Restore caller's EDX
    pop   ebx                       ; Restore caller's EBX
    pop   eax                       ; Restore caller's EAX
    ret                             ; Go home
 
GLOBAL _start

;-------------------------------------------------------------------------
; MAIN PROGRAM BEGINS HERE
;-------------------------------------------------------------------------

_start:
    nop                             ; No-ops for GDB
    
; Whatever initialization needs doing before the loop scan starts is here:
    xor   esi, esi                  ; Clear total byte counter to 0
    call  LoadBuff                  ; Read first buffer of data from STDIN
    cmp   ebp, EOF                  ; If ebp=0, sys_read reached EOF on STDIN 
                                    ; ('EOF' symbol here is defined as an equate with the value of zero)
    jbe   Exit                      ; If ebp <= 0, then we need to Exit
                                    
; Go through the buffer and convert binary byte values to hex digits:
Scan:
    xor   eax, eax                  ; Clear EAX to 0
    mov   al, BYTE [Buff+ecx]       ; Get a byte from the buffer into AL
    mov   edx, esi                  ; Copy total counter into EDX
    and   edx, 0000000Fh            ; Mask out lowest 4 bits of char counter
    call  DumpChar                  ; Call the char poke procedure
    
; Bump the buffer pointer to the next character and see if buffer's done:
    inc   esi                       ; Increment total chars processed counter
    inc   ecx                       ; Increment buffer pointer
    cmp   ecx, ebp                  ; Compare with the # of chars in the buffer
    jb    .modTest                  ; If we've processed all the chars in the buffer...
    call  LoadBuff                  ; ...go fill the buffer again
    cmp   ebp, EOF                  ; If ebp=0, sys_read reached EOF on STDIN
                                    ; ('EOF' symbol here is defined as an equate with the value of zero)
    jbe   Done                      ; If we got EOF, we're done
    
; See if we're at the end of a block of 16 and need to display a line:
.modTest:
    test  esi,0000000Fh             ; Test 4 lowest bits in counter for 0
    jnz   Scan                      ; If counter is *not* modulo 16, loop back
    call  PrintLine                 ; ...otherwise print the line
    call  ClearLine                 ; Clear hex dump line to 0's
    jmp   Scan                      ; Continue scanning the buffer    
    
; All done!  Let's end this party:
Done:
    call  PrintLine                 ; Print the "leftovers" line
Exit:
    mov   eax, SYS_EXIT             ; Code for Exit Syscall
    mov   ebx, OK                   ; Return a code of zero
    int   80h                       ; Make kernel call
