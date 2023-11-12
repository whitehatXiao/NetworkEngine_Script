CC = /usr/bin/gcc-11
CFLAGS = -Wall -g -O2 -Werror -std=gnu99

EXE = program

SRC = ./ass
CODE = memory/instruction.c memory/dram.c disk/code.c cpu/mmu.c main.c

.PHONY: program
main:
	$(CC) $(CFLAGS) -I$(SRC) $(CODE) -o $(EXE)

run: program
	./$(EXE)

clean:
	rm $(EXE)