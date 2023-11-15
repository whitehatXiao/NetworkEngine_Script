CC = /usr/bin/gcc-11
CFLAGS = -Wall -g -Werror

EXE = program

SRC = ./ass
CODE = memory/instruction.c memory/dram.c disk/code.c cpu/mmu.c main.c

.PHONY: program
main:
	$(CC) $(CFLAGS) -I$(SRC) $(CODE) -o $(EXE)
	./$(EXE)

clean:
	rm $(EXE)