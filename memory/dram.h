#ifndef dram_guard
#define dram_guard

#include <stdint.h>

#define MM_LEN 1000

// 为什么要使用 uint8 呢？  直接用 64 不是更加方便吗
// read64bits_dram 和  write64bits_dram 都是通过位运算8bit,8bit进行的
extern uint8_t mm[MM_LEN]; // physical memeory

uint64_t read64bits_dram(uint64_t paddr);
void write64bits_dram(uint64_t paddr, uint64_t data);

void print_stack();
void print_register();

#endif