#ifndef mmu_guard
#define mmu_guard // include guide tech

#include <stdio.h>
#include <stdint.h>

// memory management unit , duty is map for virtual address to physical address
uint64_t va2pa(uint64_t vaddr);

#endif
