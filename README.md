# Program `hexdump2`

A simple program in assembly (32-bit mode), written with NASM, for Linux.  Demonstrates using assembly language procedures to implement a hex dump utility that also shows the ASCII-equivalent output.

## Pseudo-code

```
As long as there is data available from STDIN, do the following:
    Read data from STDIN
    Convert data bytes to a suitable hexadecimal/ASCII display form
Insert formatted data bytes into a 16-byte hex dump line
    Every 16 bytes, display the hex dump line
```
(The text below is from "Assembly Language Step by Step: Programming with Linux", 3rd ed., by Jeff Duntemann, John Wiley & Sons, 2009.)

This is a good example of early pseudo-code iteration, when you know roughly what you want the program to do but are still a little fuzzy on exactly how to do it.  It should give you a head-start understanding of the much more detailed (and how-oriented) pseudo-code that follows:
```
Zero out the byte count total (ESI) and offset counter (ECX)
Call LoadBuff to fill a buffer with the first batch of data from STDIN
    Test number of bytes fetched into the buffer from STDIN
        If the number of bytes was zero, the file was empty; jump to Exit
Scan:   Get a byte from the buffer and put it in AL
        Derive the byte's position in the hex dump line stirng
        Call DumpChar to poke the byte into the line string
        Increment the total counter and buffer offset counter
        Test and see if we've processed the last byte in the buffer:
            If so, call LoadBuff to fill the buffer with data from STDIN
                Test number of bytes fetched into the buffer from STDIN
                    If the number of bytes was 0, we hit EOF; jump to Exit
        Test and see if we've poked 16 bytes into the hex dump line
        If o, call PrintLine to display the hex dump line
Loop back to Scan
Exit:   Shut down the program gracefully per Linux requirements
```
