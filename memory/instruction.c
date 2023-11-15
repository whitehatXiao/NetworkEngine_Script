#include "instruction.h"
#include "../cpu/mmu.h"
#include "../memory/dram.h"
#include "../cpu/register.h"

#include <stdio.h>

static uint64_t decode_od(od_t od)
{
    if (od.type == IMM)
    {
        return *((uint64_t *)&od.imm);
    }
    else if (od.type == REG)
    {
        return (uint64_t)od.reg1;
    }
    else
    {
        // mm
        uint64_t vaddr = 0;

        if (od.type == MM_IMM)
        {
            vaddr = od.imm;
        }
        else if (od.type == MM_REG)
        {
            // store reg
            vaddr = *(od.reg1);
        }
        else if (od.type == MM_IMM_REG)
        {
            vaddr = od.imm + *(od.reg1);
        }
        else if (od.type == MM_REG1_REG2)
        {
            // store reg
            vaddr = *(od.reg1) + *(od.reg2);
        }
        else if (od.type == MM_IMM_REG1_REG2)
        {
            // store reg
            vaddr = *(od.reg1) + *(od.reg2) + od.imm;
        }
        else if (od.type == MM_REG2_S)
        {
            // store reg
            vaddr = (*(od.reg2)) * od.scal;
        }
        else if (od.type == MM_IMM_REG2_S)
        {
            // store reg
            vaddr = od.imm + (*(od.reg2)) * od.scal;
        }
        else if (od.type == MM_REG1_REG2_S)
        {
            // store reg
            vaddr = *(od.reg1) + (*(od.reg2)) * od.scal;
        }
        else if (od.type == MM_IMM_REG1_REG2_S)
        {
            // store reg
            vaddr = od.imm + *(od.reg1) + (*(od.reg2)) * od.scal;
        }
        
        return vaddr;
    }
}


void instruction_cycle()
{

    inst_t *instr = (inst_t *)reg.rip;

    // imm: imm
    // reg: value
    // mm: paddr
    uint64_t src = decode_od(instr->src);
    uint64_t dst = decode_od(instr->dst);

    // add rax rbx
    // op = add_reg_reg = 3
    // handler_table[add_reg_reg] == handler_table[3] == add_reg_reg_handler

    handler_t handler = handler_table[instr->op]; // how to init handler_table[]

    // add_reg_reg_handler(src = &rax, dst = &rbx)
    handler(dst, src);

    printf("    %s\n", instr->code); // value after execute ?
}

void init_handler_table()
{
    handler_table[mov_reg_reg] = &mov_reg_reg_handler;
    handler_table[call] = &call_handler;
    handler_table[add_reg_reg] = &add_reg_reg_handler;
    handler_table[push_reg] = &push_reg_handler;
    handler_table[pop_reg] = &pop_reg_handler;
    handler_table[mov_reg_mem] = &mov_reg_mem_handler;
}

/**
 * reg.rsp = reg.rsp - 8; 操作是将栈指针 rsp 向下移动8个字节，也就是减去8。
 * 在栈的概念中，
 * 向下移动表示栈的增长方向，所以这个操作实际上是使栈指针指向栈顶的上方的位置。
 */
void mov_reg_reg_handler(uint64_t src, uint64_t dst)
{
    // src: reg
    // dst: reg
    *(uint64_t *)dst = *(uint64_t *)src;
    reg.rip = reg.rip + sizeof(inst_t);
}

void mov_reg_mem_handler(uint64_t src, uint64_t dst)
{
    // src: reg
    // dst: mem virutal address
    write64bits_dram(
        va2pa(dst),
        *(uint64_t *)src
    );

    reg.rip = reg.rip + sizeof(inst_t);
}

void push_reg_handler(uint64_t src, uint64_t dst)
{
    // src: reg
    // dst: empty
    reg.rsp = reg.rsp - 0x8;
    write64bits_dram(
        va2pa(reg.rsp),
        *(uint64_t *)src
    );
    reg.rip = reg.rip + sizeof(inst_t);
}

void pop_reg_handler(uint64_t src, uint64_t dst)
{
    // TODO
    printf("pop\n");
}

/**
 * 将控制从函数 P 转移到函数 Q 只 需 要简单地把程序计数器 (PC ) 设置为 Q 的代码的起始位
置 。
不过，
当 稍后从 Q 返回的时候，处理器必须记录好它 需 要继续 P 的执行的代码位置 。
在
x86-6 4 机器中，这个信息是用指令 call Q 调用过程 Q 来记录的。该指 令 会把地址 A 压入栈
中，并将 PC 设置为 Q 的起始地址 。 压入的地址 A 被称为返回地址，是紧跟在 call 指令后
面的那条指令的地址。对应的指令 ret 会从栈中弹出地址 A, 并把 PC 设置为 A

  csapp 3.7.2  call 指令的底层逻辑
*/

void call_handler(uint64_t src, uint64_t dst) // TODO dst not use
{
    // src: imm address of called function
    reg.rsp = reg.rsp - 8;

    // write return address to rsp memory
    write64bits_dram(
        va2pa(reg.rsp),
        reg.rip + sizeof(inst_t));

    // point to src(imm), it was starting address of calling function
    reg.rip = src;

    // maybe not done yet ,
    //  return , pop ...
}

void add_reg_reg_handler(uint64_t src, uint64_t dst)
{
    *(uint64_t *)dst = *(uint64_t *)dst + *(uint64_t *)src;
    reg.rip = reg.rip + sizeof(inst_t);
}
