hexdump2: hexdump2.o
	ld -o hexdump2 hexdump2.o -m elf_i386
hexdump2.o: hexdump2.asm
	nasm -f elf -g -F stabs hexdump2.asm -l hexdump2.lst
clean:
	rm -f *.o *.lst hexdump2
