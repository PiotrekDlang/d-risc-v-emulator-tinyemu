/*
 * RISCV CPU emulator
 * 
 * Copyright (c) 2016-2017 Fabrice Bellard
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

module riscv_cpu;
debug import std.stdio;

//import core.stdc.stdio;
//import core.stdc.stdarg;
//import core.stdc.string;
import core.stdc.inttypes;

/*
#ifndef MAX_XLEN
#error MAX_XLEN must be defined
#endif
#ifndef CONFIG_RISCV_MAX_XLEN
#error CONFIG_RISCV_MAX_XLEN must be defined
#endif

*/
import cutils;
import dutils;

import iomem;
import riscv_cpu_def;

import riscv_cpu_tempalate;

mixin cpu_x!32;
mixin cpu_x!64;



static void riscv_cpu_interp(alias MAX_XLEN)(RISCVCPUState *s, int n_cycles)
{
    uint64_t timeout;

    timeout = s.insn_counter + n_cycles;
    while (!s.power_down_flag &&
           cast(int)(timeout - s.insn_counter) > 0)
    {
        n_cycles = cast(int)(timeout - s.insn_counter);
        switch(s.cur_xlen) {
        case 32:
            cpu_x!32.interp_x(s, n_cycles);
            break;
static if (MAX_XLEN >= 64)
{
        case 64:
            cpu_x!64.interp_x(s, n_cycles);
            break;
}
static if (MAX_XLEN >= 128)
{
        case 128:
            cpu!128.interp_x(s, n_cycles);
            break;
}
        default:
            //abort();
        }
    }
}

/* Note: the value is not accurate when called in riscv_cpu_interp() */
static uint64_t riscv_cpu_get_cycles(alias MAX_XLEN)(RISCVCPUState *s)
{
    return s.insn_counter;
}

static void riscv_cpu_set_mip(alias MAX_XLEN)(RISCVCPUState *s, uint32_t mask)
{
    s.mip |= mask;
    /* exit from power down if an interrupt is pending */
    if (s.power_down_flag && (s.mip & s.mie) != 0)
        s.power_down_flag = FALSE;
}

static void riscv_cpu_reset_mip(alias MAX_XLEN)(RISCVCPUState *s, uint32_t mask)
{
    s.mip &= ~mask;
}

static uint32_t riscv_cpu_get_mip(alias MAX_XLEN)(RISCVCPUState *s)
{
    return s.mip;
}

static BOOL riscv_cpu_get_power_down(alias MAX_XLEN)(RISCVCPUState *s)
{
    return s.power_down_flag;
}

static RISCVCPUState * riscv_cpu_init(alias MAX_XLEN)(PhysMemoryMap *mem_map)
{
    RISCVCPUState *s;
    
    s = cast(RISCVCPUState*)mallocz((*s).sizeof);

    /// FIXME s.common.class_ptr = riscv_cpu_class!MAX_XLEN;
    s.mem_map = mem_map;
    s.pc = 0x1000;
    s.priv = PRV_M;
    s.cur_xlen = MAX_XLEN;
    s.mxl = cast(uint8_t)get_base_from_xlen(MAX_XLEN);
    s.mstatus = (cast(uint64_t)s.mxl << MSTATUS_UXL_SHIFT) |
        (cast(uint64_t)s.mxl << MSTATUS_SXL_SHIFT);
    s.misa |= MCPUID_SUPER | MCPUID_USER | MCPUID_I | MCPUID_M | MCPUID_A;
static if (FLEN >= 32)
{
    s.misa |= MCPUID_F;
}
static if (FLEN >= 64)
{
    s.misa |= MCPUID_D;
}
static if (FLEN >= 128)
{
    s.misa |= MCPUID_Q;
}
static if (CONFIG_EXT_C)
{
    s.misa |= MCPUID_C;
}
    tlb_init(s);
    return s;
}

static void riscv_cpu_end(MAX_XLEN)(RISCVCPUState *s)
{
	// free(s);
}

static uint32_t riscv_cpu_get_misa(MAX_XLEN)(RISCVCPUState *s)
{
    return s.misa;
}

void main()
{

	enum LOW_RAM_SIZE =  0x00010000; /* 64KB */
	enum RAM_BASE_ADDR = 0x80000000;


	uint[] code =
	[0x1234,
	0x1234,
	0x436567];
	PhysMemoryMap * mem_map = phys_mem_map_init();

	cpu_register_ram(mem_map, RAM_BASE_ADDR, 1.MB, /* ram_flags */ 0);
    cpu_register_ram(mem_map, 0x00000000, LOW_RAM_SIZE, 0);
	uint8_t* mem_cell = phys_mem_get_ram_ptr(mem_map, 0x1000, false);
	*mem_cell = cast(ubyte)0x01;
	*(mem_cell+1) = cast(ubyte)0x11;
	*(mem_cell+2) = cast(ubyte)0x01;
	*(mem_cell+3) = cast(ubyte)0x11;
	RISCVCPUState * state = riscv_cpu_init!MAX_XLEN(mem_map);
	riscv_cpu_interp!MAX_XLEN(state, 1);
	
}


