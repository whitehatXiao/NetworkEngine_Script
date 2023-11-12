#include <stdio.h>
#include <stdint.h>

#include "cpu/register.h"
#include "cpu/mmu.h"
#include "memory/instruction.h"
#include "memory/dram.h"
#include "disk/elf.h"

//  resolve global define question ...
reg_t reg;
handler_t handler_table[NUM_INSTRTYPE];
uint8_t mm[MM_LEN];

int main()
{

    // uint64_t a = 0xffff0000;
    // uint64_t b = 0x0000abcd;

    // printf("hello , world\n");

    // return 0;

    init_handler_table(); // load instruction to handler_table. it like code recorder register .

    // init  翻译add.c程序 ，手动放到寄存器、内存中且修改栈等各种状态中，我们现在正在实施的是一个编译器，或者说汇编器。
    // 是不是也可以理解为想linux内核一般的东西，只是这里没有进场管理、io管理等调用系统物理资源的特权指令（接口）
    reg.rax = 0x12340000;
    reg.rbx = 0x0;
    reg.rcx = 0x8000660;
    reg.rdx = 0xabcd;
    reg.rsi = 0x7ffffffee2f8;
    reg.rdi = 0x1;
    reg.rbp = 0x7ffffffee210;
    reg.rsp = 0x7ffffffee1f0;

    reg.rip = (uint64_t)&program[11]; // not extend clamid

    write64bits_dram(va2pa(0x7ffffffee210), 0x08000660); // rbp
    write64bits_dram(va2pa(0x7ffffffee208), 0x0);
    write64bits_dram(va2pa(0x7ffffffee200), 0xabcd);
    write64bits_dram(va2pa(0x7ffffffee1f8), 0x12340000);
    write64bits_dram(va2pa(0x7ffffffee1f0), 0x08000660); // rsp

    print_register();
    print_stack();

    // run inst

    for (int i = 0; i < 3; i++)
    {
        instruction_cycle();

        print_register();
        print_stack();
    }

    // verify

    int match = 1;

    match = match && (reg.rax == 0x1234abcd);
    match = match && (reg.rbx == 0x0);
    match = match && (reg.rcx == 0x8000660);
    match = match && (reg.rdx == 0x12340000);
    match = match && (reg.rsi == 0xabcd);
    match = match && (reg.rdi == 0x12340000);
    match = match && (reg.rbp == 0x7ffffffee210);
    match = match && (reg.rsp == 0x7ffffffee1f0);

    if (match == 1)
    {
        printf("register match\n");
    }
    else
    {
        printf("register not match\n");
    }

    match = match && (read64bits_dram(va2pa(0x7ffffffee210)) == 0x08000660); // rbp
    match = match && (read64bits_dram(va2pa(0x7ffffffee208)) == 0x1234abcd);
    match = match && (read64bits_dram(va2pa(0x7ffffffee200)) == 0xabcd);
    match = match && (read64bits_dram(va2pa(0x7ffffffee1f8)) == 0x12340000);
    match = match && (read64bits_dram(va2pa(0x7ffffffee1f0)) == 0x08000660);

    if (match == 1)
    {
        printf("memory match\n");
    }
    else
    {
        printf("memory not match\n");
    }

    return 0;
}