module riscv_cpu_def;

import core.stdc.inttypes;
import core.stdc.stdlib;

import dutils;

import softfplib;
import iomem;

enum MIP_USIP = (1 << 0);
enum MIP_SSIP = (1 << 1);
enum MIP_HSIP = (1 << 2);
enum MIP_MSIP = (1 << 3);
enum MIP_UTIP = (1 << 4);
enum MIP_STIP = (1 << 5);
enum MIP_HTIP = (1 << 6);
enum MIP_MTIP = (1 << 7);
enum MIP_UEIP = (1 << 8);
enum MIP_SEIP = (1 << 9);
enum MIP_HEIP = (1 << 10);
enum MIP_MEIP = (1 << 11);


/*
struct RISCVCPUClass
{
    RISCVCPUState * function(PhysMemoryMap *mem_map) riscv_cpu_init;
    void function(RISCVCPUState *s) riscv_cpu_end;
    void function(RISCVCPUState *s, int n_cycles) riscv_cpu_interp;
    uint64_t function(RISCVCPUState *s) riscv_cpu_get_cycles;
    void function(RISCVCPUState *s, uint32_t mask) riscv_cpu_set_mip;
    void function(RISCVCPUState *s, uint32_t mask) riscv_cpu_reset_mip;
    uint32_t function(RISCVCPUState *s) riscv_cpu_get_mip;
    bool function (RISCVCPUState *s) riscv_cpu_get_power_down;
    uint32_t function(RISCVCPUState *s) riscv_cpu_get_misa;
    void function(RISCVCPUState *s, uint8_t *ram_ptr, size_t ram_size) riscv_cpu_flush_tlb_write_range_ram;
}

struct RISCVCPUCommonState
{
    const RISCVCPUClass *class_ptr;
}
*/
// import riscv_cpu_priv;

enum CONFIG_EXT_C = true; /* compressed instructions */

version = MAX_XLEN_64;

version(MAX_XLEN_32)
{
    alias target_ulong = uint32_t;
    alias target_long = int32_t;
    enum MAX_XLEN = 32;
}
else version(MAX_XLEN_64)
{
    alias target_ulong = uint64_t;
    alias target_long = int64_t;
    enum MAX_XLEN = 64;
}
else version(MAX_XLEN_128)
{
    alias target_ulong = uint128_t;
    alias target_long = int128_t;
    enum MAX_XLEN = 128;
}
else
{
    static assert(0, "Unsupported MAX_XLEN");
}

static if (MAX_XLEN == 128)
{
    enum FLEN = 128;
}
else
{
    enum FLEN = 64;
}


/* FLEN is the floating point register width */
static if (FLEN > 0)
{
	static if (FLEN == 32)
	{
		alias fp_uint = uint32_t;
		enum F32_HIGH = 0;
	}
	else static if (FLEN == 64)
	{
		alias fp_uint =  uint64_t;
		enum F32_HIGH = (cast(fp_uint)-1 << 32);
		enum F64_HIGH = 0;
	}
	else static if (FLEN == 128)
	{
		alias fp_uint = uint128_t;
		enum F32_HIGH = (cast(fp_uint)-1 << 32);
		enum F64_HIGH = (cast(fp_uint)-1 << 64);
	}
	else
	{
		static assert (false, "Error unsupported FLEN");
	}
}


/* MLEN is the maximum memory access width */
static if (MAX_XLEN <= 32 && FLEN <= 32)
{
    enum  MLEN = 32;
}
else static if (MAX_XLEN <= 64 && FLEN <= 64)
{
    enum MLEN = 64;
}
else
{
    enum MLEN = 128;
}


static if  (MLEN == 32)
{
    alias mem_uint_t = uint32_t;
}
else static if (MLEN == 64)
{
    alias mem_uint_t = uint64_t;
}
else static if (MLEN == 128)
{
    alias mem_uint_t = uint128_t;
}
else
{
    static assert (0, "Unsupported MLEN");
}


enum TLB_SIZE = 256;

enum CAUSE_MISALIGNED_FETCH    = 0x0;
enum CAUSE_FAULT_FETCH         = 0x1;
enum CAUSE_ILLEGAL_INSTRUCTION = 0x2;
enum CAUSE_BREAKPOINT          = 0x3;
enum CAUSE_MISALIGNED_LOAD     = 0x4;
enum CAUSE_FAULT_LOAD          = 0x5;
enum CAUSE_MISALIGNED_STORE    = 0x6;
enum CAUSE_FAULT_STORE         = 0x7;
enum CAUSE_USER_ECALL          = 0x8;
enum CAUSE_SUPERVISOR_ECALL    = 0x9;
enum CAUSE_HYPERVISOR_ECALL    = 0xa;
enum CAUSE_MACHINE_ECALL       = 0xb;
enum CAUSE_FETCH_PAGE_FAULT    = 0xc;
enum CAUSE_LOAD_PAGE_FAULT     = 0xd;
enum CAUSE_STORE_PAGE_FAULT    = 0xf;

/* Note: converted to correct bit position at runtime */
enum CAUSE_INTERRUPT  = (cast(uint32_t)1 << 31);


enum PTE_V_MASK = (1 << 0);
enum PTE_U_MASK = (1 << 4);
enum PTE_A_MASK = (1 << 6);
enum PTE_D_MASK = (1 << 7);

enum ACCESS_READ  = 0;
enum ACCESS_WRITE = 1;
enum ACCESS_CODE  = 2;

enum PRV_U = 0;
enum PRV_S = 1;
enum PRV_H = 2;
enum PRV_M = 3;

/* misa CSR */
enum MCPUID_SUPER   = (1 << ('S' - 'A'));
enum MCPUID_USER    = (1 << ('U' - 'A'));
enum MCPUID_I       = (1 << ('I' - 'A'));
enum MCPUID_M       = (1 << ('M' - 'A'));
enum MCPUID_A       = (1 << ('A' - 'A'));
enum MCPUID_F       = (1 << ('F' - 'A'));
enum MCPUID_D       = (1 << ('D' - 'A'));
enum MCPUID_Q       = (1 << ('Q' - 'A'));
enum MCPUID_C       = (1 << ('C' - 'A'));

/* mstatus CSR */

enum MSTATUS_SPIE_SHIFT = 5;
enum MSTATUS_MPIE_SHIFT = 7;
enum MSTATUS_SPP_SHIFT = 8;
enum MSTATUS_MPP_SHIFT = 11;
enum MSTATUS_FS_SHIFT  = 13;
enum MSTATUS_UXL_SHIFT = 32;
enum MSTATUS_SXL_SHIFT = 34;

enum MSTATUS_UIE = (1 << 0);
enum MSTATUS_SIE = (1 << 1);
enum MSTATUS_HIE = (1 << 2);
enum MSTATUS_MIE = (1 << 3);
enum MSTATUS_UPIE = (1 << 4);
enum MSTATUS_SPIE = (1 << MSTATUS_SPIE_SHIFT);
enum MSTATUS_HPIE = (1 << 6);
enum MSTATUS_MPIE = (1 << MSTATUS_MPIE_SHIFT);
enum MSTATUS_SPP = (1 << MSTATUS_SPP_SHIFT);
enum MSTATUS_HPP = (3 << 9);
enum MSTATUS_MPP =(3 << MSTATUS_MPP_SHIFT);
enum MSTATUS_FS = (3 << MSTATUS_FS_SHIFT);
enum MSTATUS_XS = (3 << 15);
enum MSTATUS_MPRV = (1 << 17);
enum MSTATUS_SUM = (1 << 18);
enum MSTATUS_MXR = (1 << 19);
//enum MSTATUS_TVM (1 << 20)
//enum MSTATUS_TW (1 << 21)
//enum MSTATUS_TSR (1 << 22)
enum MSTATUS_UXL_MASK = (cast(uint64_t)3 << MSTATUS_UXL_SHIFT);
enum MSTATUS_SXL_MASK = (cast(uint64_t)3 << MSTATUS_SXL_SHIFT);

enum PG_SHIFT = 12;
enum PG_MASK = ((1 << PG_SHIFT) - 1);

struct TLBEntry
{
    target_ulong vaddr;
    uintptr_t mem_addend;
}

struct RISCVCPUState {
    /*RISCVCPUCommonState common;*/ /* must be first */
    
    target_ulong pc;
    target_ulong[32] reg;

static if (FLEN > 0)
{
    fp_uint[32] fp_reg;
    uint32_t fflags;
    uint8_t frm;
}
    uint8_t cur_xlen;  /* current XLEN value, <= MAX_XLEN */
    uint8_t priv; /* see PRV_x */
    uint8_t fs; /* MSTATUS_FS value */
    uint8_t mxl; /* MXL field in MISA register */
    
    uint64_t insn_counter;
    bool power_down_flag;
    int pending_exception; /* used during MMU exception handling */
    target_ulong pending_tval;
    
    /* CSRs */
    target_ulong mstatus;
    target_ulong mtvec;
    target_ulong mscratch;
    target_ulong mepc;
    target_ulong mcause;
    target_ulong mtval;
    target_ulong mhartid; /* ro */
    uint32_t misa;
    uint32_t mie;
    uint32_t mip;
    uint32_t medeleg;
    uint32_t mideleg;
    uint32_t mcounteren;
    
    target_ulong stvec;
    target_ulong sscratch;
    target_ulong sepc;
    target_ulong scause;
    target_ulong stval;
version (MAX_XLEN_32)
{
    uint32_t satp;
}
else
{
    uint64_t satp; /* currently 64 bit physical addresses max */
}
    uint32_t scounteren;

    target_ulong load_res; /* for atomic LR/SC */

    PhysMemoryMap *mem_map;

    TLBEntry[TLB_SIZE] tlb_read;
    TLBEntry[TLB_SIZE] tlb_write;
    TLBEntry[TLB_SIZE] tlb_code;
}


/* return 0 if OK, != 0 if exception */
// TODO inline __exception
static int target_read(Uint_type)(RISCVCPUState *s, Uint_type *pval, target_ulong addr)
{
	import std.math;
	enum int log2size = cast(int)log2(Uint_type.sizeof);
	uint32_t tlb_idx;
	tlb_idx = (addr >> PG_SHIFT) & (TLB_SIZE - 1);
	// TODO use? likely
	if (s.tlb_read[tlb_idx].vaddr == (addr & ~(PG_MASK & ~((/*size / 8*/ Uint_type.sizeof) - 1))))
	{
		*pval = *cast(Uint_type *)(s.tlb_read[tlb_idx].mem_addend + cast(uintptr_t)addr);
	}
	else
	{
		mem_uint_t val;
		int ret;
		ret = target_read_slow(s, &val, addr, log2size );
		if (ret)
		{
			return ret;	
		}
		*pval = cast(Uint_type)val;
	}
	return 0;
}


//DLL_PUBLIC
int target_read_slow(RISCVCPUState *s, mem_uint_t *pval,
                                target_ulong addr, int size_log2);
//DLL_PUBLIC
int target_write_slow(RISCVCPUState *s, target_ulong addr,
                                 mem_uint_t val, int size_log2);


// TODO inline __exception
static int target_write(Uint_type)(RISCVCPUState *s, target_ulong addr, Uint_type val)
{
	import std.math;
	enum int log2size = cast(int)log2(Uint_type.sizeof);
	uint32_t tlb_idx;
	tlb_idx = (addr >> PG_SHIFT) & (TLB_SIZE - 1);
	// TODO use? likely
	if (s.tlb_write[tlb_idx].vaddr == (addr & ~(PG_MASK & ~((/*size / 8*/ Uint_type.sizeof) - 1))))
	{
		*cast(Uint_type *)(s.tlb_write[tlb_idx].mem_addend + cast(uintptr_t)addr) = val;
		return 0;
	}
	else
	{
		return target_write_slow(s, addr, val, log2size );
	}
}



// TODO inline 
static uint32_t get_field1(uint32_t val, int src_pos, 
                                  int dst_pos, int dst_pos_max)
{
    int mask;
    assert(dst_pos_max >= dst_pos);
    mask = ((1 << (dst_pos_max - dst_pos + 1)) - 1) << dst_pos;
    if (dst_pos >= src_pos)
        return (val << (dst_pos - src_pos)) & mask;
    else
        return (val >> (src_pos - dst_pos)) & mask;
}


// TODO __exception
static int raise_interrupt(RISCVCPUState *s)
{
    uint32_t mask;
    int irq_num;

    mask = get_pending_irq_mask(s);
    if (mask == 0)
        return 0;
    // FIXME   
    //irq_num = ctz32(mask);
    raise_exception(s, irq_num | CAUSE_INTERRUPT);
    return -1;
}

// TODO inline
static  int32_t sext(int32_t val, int n)
{
    return (val << (32 - n)) >> (32 - n);
}


// TODO no_inline __exception
/* return 0 if OK, != 0 if exception */
static  int target_read_insn_slow(RISCVCPUState *s, uint8_t **pptr, target_ulong addr)
{
    int tlb_idx;
    target_ulong paddr;
    uint8_t *ptr;
    PhysMemoryRange *pr;

    
    if (get_phys_addr(s, &paddr, addr, ACCESS_CODE)) {
        s.pending_tval = addr;
        s.pending_exception = CAUSE_FETCH_PAGE_FAULT;
        return -1;
    }
    pr = get_phys_mem_range(s.mem_map, paddr);
    if (!pr || !pr.is_ram) {
        /* XXX: we only access to execute code from RAM */
        s.pending_tval = addr;
        s.pending_exception = CAUSE_FAULT_FETCH;
        return -1;
    }
    tlb_idx = (addr >> PG_SHIFT) & (TLB_SIZE - 1);
    ptr = pr.phys_mem + cast(uintptr_t)(paddr - pr.addr);
    s.tlb_code[tlb_idx].vaddr = addr & ~PG_MASK;
    s.tlb_code[tlb_idx].mem_addend = cast(uintptr_t)ptr - addr;
    *pptr = ptr;
    return 0;
}

/* addr must be aligned */
// inline __exception 
static int target_read_insn_u16(RISCVCPUState *s, uint16_t *pinsn,
                                                   target_ulong addr)
{
    uint32_t tlb_idx;
    uint8_t *ptr;
    
    tlb_idx = (addr >> PG_SHIFT) & (TLB_SIZE - 1);
    /// TODO likely
    if ((s.tlb_code[tlb_idx].vaddr == (addr & ~PG_MASK))) {
        ptr = cast(uint8_t *)(s.tlb_code[tlb_idx].mem_addend +
                          cast(uintptr_t)addr);
    }
    else
    {
        if (target_read_insn_slow(s, &ptr, addr))
            return -1;
    }
    *pinsn = *cast(uint16_t *)ptr;
    return 0;
}

// TODO __attribute__((packed))
struct  unaligned_u32
{
	align (1):
    uint32_t u32;
};

/* unaligned access at an address known to be a multiple of 2 */
static uint32_t get_insn32(uint8_t *ptr)
{
    return (cast(unaligned_u32 *)ptr).u32;
}



static void tlb_init(RISCVCPUState *s)
{
    for(int i = 0; i < TLB_SIZE; i++)
    {
        s.tlb_read[i].vaddr = -1;
        s.tlb_write[i].vaddr = -1;
        s.tlb_code[i].vaddr = -1;
    }
}

static void tlb_flush_all(RISCVCPUState *s)
{
    tlb_init(s);
}

static void tlb_flush_vaddr(RISCVCPUState *s, target_ulong vaddr)
{
    tlb_flush_all(s);
}
/* return -1 if invalid CSR. 0 if OK. 'will_write' indicate that the
   csr will be written after (used for CSR access check) */
static int csr_read(RISCVCPUState *s, target_ulong *pval, uint32_t csr,
                     bool will_write)
{
    target_ulong val;

    if (((csr & 0xc00) == 0xc00) && will_write)
        return -1; /* read-only CSR */
    if (s.priv < ((csr >> 8) & 3))
        return -1; /* not enough priviledge */
    
    switch(csr) {
static if (FLEN > 0)
{
    case 0x001: /* fflags */
        if (s.fs == 0)
            return -1;
        val = s.fflags;
        break;
    case 0x002: /* frm */
        if (s.fs == 0)
            return -1;
        val = s.frm;
        break;
    case 0x003:
        if (s.fs == 0)
            return -1;
        val = s.fflags | (s.frm << 5);
        break;
}
    case 0xc00: /* ucycle */
    case 0xc02: /* uinstret */
        {
            uint32_t counteren;
            if (s.priv < PRV_M) {
                if (s.priv < PRV_S)
                    counteren = s.scounteren;
                else
                    counteren = s.mcounteren;
                if (((counteren >> (csr & 0x1f)) & 1) == 0)
                    goto invalid_csr;
            }
        }
        val = cast(int64_t)s.insn_counter;
        break;
    case 0xc80: /* mcycleh */
    case 0xc82: /* minstreth */
        if (s.cur_xlen != 32)
            goto invalid_csr;
        {
            uint32_t counteren;
            if (s.priv < PRV_M)
            {
                if (s.priv < PRV_S)
                    counteren = s.scounteren;
                else
                    counteren = s.mcounteren;
                if (((counteren >> (csr & 0x1f)) & 1) == 0)
                    goto invalid_csr;
            }
        }
        val = s.insn_counter >> 32;
        break;
        
    case 0x100:
        val = get_mstatus(s, SSTATUS_MASK);
        break;
    case 0x104: /* sie */
        val = s.mie & s.mideleg;
        break;
    case 0x105:
        val = s.stvec;
        break;
    case 0x106:
        val = s.scounteren;
        break;
    case 0x140:
        val = s.sscratch;
        break;
    case 0x141:
        val = s.sepc;
        break;
    case 0x142:
        val = s.scause;
        break;
    case 0x143:
        val = s.stval;
        break;
    case 0x144: /* sip */
        val = s.mip & s.mideleg;
        break;
    case 0x180:
        val = s.satp;
        break;
    case 0x300:
        val = get_mstatus(s, cast(target_ulong)-1);
        break;
    case 0x301:
        val = s.misa;
        val |= cast(target_ulong)s.mxl << (s.cur_xlen - 2);
        break;
    case 0x302:
        val = s.medeleg;
        break;
    case 0x303:
        val = s.mideleg;
        break;
    case 0x304:
        val = s.mie;
        break;
    case 0x305:
        val = s.mtvec;
        break;
    case 0x306:
        val = s.mcounteren;
        break;
    case 0x340:
        val = s.mscratch;
        break;
    case 0x341:
        val = s.mepc;
        break;
    case 0x342:
        val = s.mcause;
        break;
    case 0x343:
        val = s.mtval;
        break;
    case 0x344:
        val = s.mip;
        break;
    case 0xb00: /* mcycle */
    case 0xb02: /* minstret */
        val = cast(int64_t)s.insn_counter;
        break;
    case 0xb80: /* mcycleh */
    case 0xb82: /* minstreth */
        if (s.cur_xlen != 32)
            goto invalid_csr;
        val = s.insn_counter >> 32;
        break;
    case 0xf14:
        val = s.mhartid;
        break;
    default:
    invalid_csr:
version(debug_c)
{
        /* the 'time' counter is usually emulated */
        if (csr != 0xc01 && csr != 0xc81) {
            printf("csr_read: invalid CSR=0x%x\n", csr);
        }
}
        *pval = 0;
        return -1;
    }
    *pval = val;
    return 0;
}

static if (FLEN > 0)
{
static void set_frm(RISCVCPUState *s, uint8_t val)
{
    if (val >= 5)
        val = 0;
    s.frm = val;
}


/* return -1 if invalid roundind mode */
static int get_insn_rm(RISCVCPUState *s, uint rm)
{
    if (rm == 7)
        return s.frm;
    if (rm >= 5)
        return -1;
    else
        return rm;
}
}



/* return -1 if invalid CSR, 0 if OK, 1 if the interpreter loop must be
   exited (e.g. XLEN was modified), 2 if TLBs have been flushed. */
static int csr_write(RISCVCPUState *s, uint32_t csr, target_ulong val)
{
    target_ulong mask;

debug(DUMP_CSR)
{
    printf("csr_write: csr=0x%03x val=0x", csr);
    print_target_ulong(val);
    printf("\n");
}
    switch(csr) {
static if (FLEN > 0)
{
    case 0x001: /* fflags */
        s.fflags = val & 0x1f;
        s.fs = 3;
        break;
    case 0x002: /* frm */
        set_frm(s, val & 7);
        s.fs = 3;
        break;
    case 0x003: /* fcsr */
        set_frm(s, (val >> 5) & 7);
        s.fflags = val & 0x1f;
        s.fs = 3;
        break;
}
    case 0x100: /* sstatus */
        set_mstatus(s, (s.mstatus & ~SSTATUS_MASK) | (val & SSTATUS_MASK));
        break;
    case 0x104: /* sie */
        mask = s.mideleg;
        s.mie = cast(uint32_t)((s.mie & ~mask) | (val & mask));
        break;
    case 0x105:
        s.stvec = val & ~3;
        break;
    case 0x106:
        s.scounteren = val & COUNTEREN_MASK;
        break;
    case 0x140:
        s.sscratch = val;
        break;
    case 0x141:
        s.sepc = val & ~1;
        break;
    case 0x142:
        s.scause = val;
        break;
    case 0x143:
        s.stval = val;
        break;
    case 0x144: /* sip */
        mask = s.mideleg;
        s.mip = cast(uint32_t)((s.mip & ~mask) | (val & mask));
        break;
    case 0x180:
        /* no ASID implemented */
static if (MAX_XLEN == 32)
{
        {
            int new_mode;
            new_mode = (val >> 31) & 1;
            s.satp = (val & ((cast(target_ulong)1 << 22) - 1)) |
                (new_mode << 31);
        }
}
else
{
        {
            int mode, new_mode;
            mode = s.satp >> 60;
            new_mode = (val >> 60) & 0xf;
            if (new_mode == 0 || (new_mode >= 8 && new_mode <= 9))
                mode = new_mode;
            s.satp = (val & ((cast(uint64_t)1 << 44) - 1)) |
                (cast(uint64_t)mode << 60);
        }
}
        tlb_flush_all(s);
        return 2;
        
    case 0x300:
        set_mstatus(s, val);
        break;
    case 0x301: /* misa */
static if (MAX_XLEN >= 64)
{
        {
            int new_mxl;
            new_mxl = (val >> (s.cur_xlen - 2)) & 3;
            if (new_mxl >= 1 && new_mxl <= get_base_from_xlen(MAX_XLEN)) {
                /* Note: misa is only modified in M level, so cur_xlen
                   = 2^(mxl + 4) */
                if (s.mxl != new_mxl) {
                    s.mxl = cast(uint8_t)new_mxl;
                    s.cur_xlen = cast(uint8_t)(1 << (new_mxl + 4));
                    return 1;
                }
            }
        }
}
        break;
    case 0x302:
        mask = (1 << (CAUSE_STORE_PAGE_FAULT + 1)) - 1;
        s.medeleg = cast(uint32_t)((s.medeleg & ~mask) | (val & mask));
        break;
    case 0x303:
        mask = MIP_SSIP | MIP_STIP | MIP_SEIP;
        s.mideleg = cast(uint32_t)((s.mideleg & ~mask) | (val & mask));
        break;
    case 0x304:
        mask = MIP_MSIP | MIP_MTIP | MIP_SSIP | MIP_STIP | MIP_SEIP;
        s.mie = cast(uint32_t)((s.mie & ~mask) | (val & mask));
        break;
    case 0x305:
        s.mtvec = val & ~3;
        break;
    case 0x306:
        s.mcounteren = val & COUNTEREN_MASK;
        break;
    case 0x340:
        s.mscratch = val;
        break;
    case 0x341:
        s.mepc = val & ~1;
        break;
    case 0x342:
        s.mcause = val;
        break;
    case 0x343:
        s.mtval = val;
        break;
    case 0x344:
        mask = MIP_SSIP | MIP_STIP;
        s.mip = cast(uint32_t)((s.mip & ~mask) | (val & mask));
        break;
    default:
debug(DUMP_INVALID_CSR)
{
        printf("csr_write: invalid CSR=0x%x\n", csr);
}
        return -1;
    }
    return 0;
}



static void raise_exception2(RISCVCPUState *s, uint32_t cause,
                             target_ulong tval)
{
    bool deleg;
    target_ulong causel;
    
//static if ((DUMP_EXCEPTIONS) || defined(DUMP_MMU_EXCEPTIONS) || defined(DUMP_INTERRUPTS))

    {
        int flag;
        flag = 0;
version(debug_c)
{
        if (cause == CAUSE_FAULT_FETCH ||
            cause == CAUSE_FAULT_LOAD ||
            cause == CAUSE_FAULT_STORE ||
            cause == CAUSE_FETCH_PAGE_FAULT ||
            cause == CAUSE_LOAD_PAGE_FAULT ||
            cause == CAUSE_STORE_PAGE_FAULT)
            flag = 1;
}
version(debug_c)
{
        flag |= (cause & CAUSE_INTERRUPT) != 0;
}
version(debug_c)
{
        flag = 1;
        flag = (cause & CAUSE_INTERRUPT) == 0;
        if (cause == CAUSE_SUPERVISOR_ECALL || cause == CAUSE_ILLEGAL_INSTRUCTION)
            flag = 0;
}
        if (flag) {
			/// FIXME debug features
            // log_printf("raise_exception: cause=0x%08x tval=0x", cause);
version(debug_c)
{
            print_target_ulong(tval);
}
            // log_printf("\n");
            //dump_regs(s);
        }
    }

    if (s.priv <= PRV_S)
    {
        /* delegate the exception to the supervisor priviledge */
        if (cause & CAUSE_INTERRUPT)
            deleg = (s.mideleg >> (cause & (MAX_XLEN - 1))) & 1;
        else
            deleg = (s.medeleg >> cause) & 1;
    }
    else
    {
        deleg = 0;
    }
    
    causel = cause & 0x7fffffff;
    if (cause & CAUSE_INTERRUPT)
        causel |= cast(target_ulong)1 << (s.cur_xlen - 1);
    
    if (deleg)
    {
        s.scause = causel;
        s.sepc = s.pc;
        s.stval = tval;
        s.mstatus = (s.mstatus & ~MSTATUS_SPIE) |
            (((s.mstatus >> s.priv) & 1) << MSTATUS_SPIE_SHIFT);
        s.mstatus = (s.mstatus & ~MSTATUS_SPP) |
            (s.priv << MSTATUS_SPP_SHIFT);
        s.mstatus &= ~MSTATUS_SIE;
        set_priv(s, PRV_S);
        s.pc = s.stvec;
    }
    else
    {
        s.mcause = causel;
        s.mepc = s.pc;
        s.mtval = tval;
        s.mstatus = (s.mstatus & ~MSTATUS_MPIE) |
            (((s.mstatus >> s.priv) & 1) << MSTATUS_MPIE_SHIFT);
        s.mstatus = (s.mstatus & ~MSTATUS_MPP) |
            (s.priv << MSTATUS_MPP_SHIFT);
        s.mstatus &= ~MSTATUS_MIE;
        set_priv(s, PRV_M);
        s.pc = s.mtvec;
    }
}

static void raise_exception(RISCVCPUState *s, uint32_t cause)
{
    raise_exception2(s, cause, 0);
}

static void handle_sret(RISCVCPUState *s)
{
    int spp, spie;
    spp = (s.mstatus >> MSTATUS_SPP_SHIFT) & 1;
    /* set the IE state to previous IE state */
    spie = (s.mstatus >> MSTATUS_SPIE_SHIFT) & 1;
    s.mstatus = (s.mstatus & ~(1 << spp)) |
        (spie << spp);
    /* set SPIE to 1 */
    s.mstatus |= MSTATUS_SPIE;
    /* set SPP to U */
    s.mstatus &= ~MSTATUS_SPP;
    set_priv(s, spp);
    s.pc = s.sepc;
}

static void handle_mret(RISCVCPUState *s)
{
    int mpp, mpie;
    mpp = (s.mstatus >> MSTATUS_MPP_SHIFT) & 3;
    /* set the IE state to previous IE state */
    mpie = (s.mstatus >> MSTATUS_MPIE_SHIFT) & 1;
    s.mstatus = (s.mstatus & ~(1 << mpp)) |
        (mpie << mpp);
    /* set MPIE to 1 */
    s.mstatus |= MSTATUS_MPIE;
    /* set MPP to U */
    s.mstatus &= ~MSTATUS_MPP;
    set_priv(s, mpp);
    s.pc = s.mepc;
}


static void set_mstatus(RISCVCPUState *s, target_ulong val)
{
    target_ulong mod, mask;
    
    /* flush the TLBs if change of MMU config */
    mod = s.mstatus ^ val;
    if ((mod & (MSTATUS_MPRV | MSTATUS_SUM | MSTATUS_MXR)) != 0 ||
        ((s.mstatus & MSTATUS_MPRV) && (mod & MSTATUS_MPP) != 0))
    {
        tlb_flush_all(s);
    }
    s.fs = (val >> MSTATUS_FS_SHIFT) & 3;

    mask = MSTATUS_MASK & ~MSTATUS_FS;
static if (MAX_XLEN >= 64)
{
    {
        int uxl, sxl;
        uxl = (val >> MSTATUS_UXL_SHIFT) & 3;
        if (uxl >= 1 && uxl <= get_base_from_xlen(MAX_XLEN))
            mask |= MSTATUS_UXL_MASK;
        sxl = (val >> MSTATUS_UXL_SHIFT) & 3;
        if (sxl >= 1 && sxl <= get_base_from_xlen(MAX_XLEN))
            mask |= MSTATUS_SXL_MASK;
    }
}
    s.mstatus = (s.mstatus & ~mask) | (val & mask);
}


static void set_priv(RISCVCPUState *s, int priv)
{
    if (s.priv != priv) {
        tlb_flush_all(s);
static if (MAX_XLEN >= 64)
{
        /* change the current xlen */
        {
            int mxl;
            if (priv == PRV_S)
                mxl = (s.mstatus >> MSTATUS_SXL_SHIFT) & 3;
            else if (priv == PRV_U)
                mxl = (s.mstatus >> MSTATUS_UXL_SHIFT) & 3;
            else
                mxl = s.mxl;
            s.cur_xlen = cast(uint8_t)(1 << (4 + mxl));
        }
}
        s.priv = cast(uint8_t)priv;
    }
}

// TODO inline
static uint32_t get_pending_irq_mask(RISCVCPUState *s)
{
    uint32_t pending_ints, enabled_ints;

    pending_ints = s.mip & s.mie;
    if (pending_ints == 0)
        return 0;

    enabled_ints = 0;
    switch(s.priv) {
    case PRV_M:
        if (s.mstatus & MSTATUS_MIE)
            enabled_ints = ~s.mideleg;
        break;
    case PRV_S:
        enabled_ints = ~s.mideleg;
        if (s.mstatus & MSTATUS_SIE)
            enabled_ints |= s.mideleg;
        break;
    default:
    case PRV_U:
        enabled_ints = -1;
        break;
    }
    return pending_ints & enabled_ints;
}


enum SSTATUS_MASK0 = (MSTATUS_UIE | MSTATUS_SIE |       
                      MSTATUS_UPIE | MSTATUS_SPIE |     
                      MSTATUS_SPP | 
                      MSTATUS_FS | MSTATUS_XS | 
                      MSTATUS_SUM | MSTATUS_MXR);
static if (MAX_XLEN >= 64)
{
	enum SSTATUS_MASK = (SSTATUS_MASK0 | MSTATUS_UXL_MASK);
}
else
{
	enum SSTATUS_MASK = SSTATUS_MASK0;
}


enum MSTATUS_MASK = (MSTATUS_UIE | MSTATUS_SIE | MSTATUS_MIE |
                      MSTATUS_UPIE | MSTATUS_SPIE | MSTATUS_MPIE |
                      MSTATUS_SPP | MSTATUS_MPP |
                      MSTATUS_FS |
                      MSTATUS_MPRV | MSTATUS_SUM | MSTATUS_MXR);

/* cycle and insn counters */
enum COUNTEREN_MASK = ((1 << 0) | (1 << 2));

/* return the complete mstatus with the SD bit */
static target_ulong get_mstatus(RISCVCPUState *s, target_ulong mask)
{
    target_ulong val;
    bool sd;
    val = s.mstatus | (s.fs << MSTATUS_FS_SHIFT);
    val &= mask;
    sd = ((val & MSTATUS_FS) == MSTATUS_FS) |
        ((val & MSTATUS_XS) == MSTATUS_XS);
    if (sd)
        val |= cast(target_ulong)1 << (s.cur_xlen - 1);
    return val;
}

static int get_base_from_xlen(int xlen)
{
    if (xlen == 32)
    {
        return 1;
	}
    else if (xlen == 64)
    {
        return 2;
	}
    else
    {
        return 3;
	}
}

static void cpu_abort(RISCVCPUState *s)
{
	// TODO fix it
    //dump_regs(s);
    abort();
}

/* addr must be aligned. Only RAM accesses are supported */
// template PHYS_MEM_READ_WRITE(size, uint_type)

// TODO __maybe_unused inline
static void phys_write(uint_type)(RISCVCPUState *s, target_ulong addr,uint_type val)
{
	PhysMemoryRange *pr = get_phys_mem_range(s.mem_map, addr);
	if (!pr || !pr.is_ram)
		return;
	*cast(uint_type *)(pr.phys_mem + cast(uintptr_t)(addr - pr.addr)) = val;
}

// TODO __maybe_unused inline
static uint_type phys_read(uint_type)(RISCVCPUState *s, target_ulong addr)
{
	PhysMemoryRange *pr = get_phys_mem_range(s.mem_map, addr);
	if (!pr || !pr.is_ram)
		return 0;
	return *cast(uint_type *)(pr.phys_mem + cast(uintptr_t)(addr - pr.addr));
}


/* access = 0: read, 1 = write, 2 = code. Set the exception_pending
   field if necessary. return 0 if OK, -1 if translation error */
static int get_phys_addr(RISCVCPUState *s,
                         target_ulong *ppaddr, target_ulong vaddr,
                         int access)
{
    int mode, levels, pte_bits, pte_idx, pte_mask, pte_size_log2, xwr, priv;
    int need_write, vaddr_shift, i, pte_addr_bits;
    target_ulong pte_addr, pte, vaddr_mask, paddr;
    if ((s.mstatus & MSTATUS_MPRV) && access != ACCESS_CODE) {
        /* use previous priviledge */
        priv = (s.mstatus >> MSTATUS_MPP_SHIFT) & 3;
    } else {
        priv = s.priv;
    }

    if (priv == PRV_M) {
        if (s.cur_xlen < MAX_XLEN) {
            /* truncate virtual address */
            *ppaddr = vaddr & ((cast(target_ulong)1 << s.cur_xlen) - 1);
        } else {
            *ppaddr = vaddr;
        }
        return 0;
    }
static if (MAX_XLEN == 32)
{
    /* 32 bits */
    mode = s.satp >> 31;
    if (mode == 0)
    {
        /* bare: no translation */
        *ppaddr = vaddr;
        return 0;
    }
    else
    {
        /* sv32 */
        levels = 2;
        pte_size_log2 = 2;
        pte_addr_bits = 22;
    }
}
else
{
    mode = (s.satp >> 60) & 0xf;
    if (mode == 0)
    {
        /* bare: no translation */
        *ppaddr = vaddr;
        return 0;
    }
    else
    {
        /* sv39/sv48 */
        levels = mode - 8 + 3;
        pte_size_log2 = 3;
        vaddr_shift = MAX_XLEN - (PG_SHIFT + levels * 9);
        if (((cast(target_long)vaddr << vaddr_shift) >> vaddr_shift) != vaddr)
        {
            return -1;
		}
        pte_addr_bits = 44;
    }
}
    pte_addr = (s.satp & ((cast(target_ulong)1 << pte_addr_bits) - 1)) << PG_SHIFT;
    pte_bits = 12 - pte_size_log2;
    pte_mask = (1 << pte_bits) - 1;
    for(i = 0; i < levels; i++)
    {
        vaddr_shift = PG_SHIFT + pte_bits * (levels - 1 - i);
        pte_idx = cast(int)(vaddr >> vaddr_shift) & pte_mask;
        pte_addr += pte_idx << pte_size_log2;
        if (pte_size_log2 == 2)
        {
            pte = phys_read!uint32_t(s, pte_addr);
		}
        else
        {
            pte = phys_read!uint64_t(s, pte_addr);
		}
        //printf("pte=0x%08" PRIx64 "\n", pte);
        if (!(pte & PTE_V_MASK))
        {
            return -1; /* invalid PTE */
		}
        paddr = (pte >> 10) << PG_SHIFT;
        xwr = (pte >> 1) & 7;
        if (xwr != 0)
        {
            if (xwr == 2 || xwr == 6)
            {
                return -1;
			}
            /* priviledge check */
            if (priv == PRV_S)
            {
                if ((pte & PTE_U_MASK) && !(s.mstatus & MSTATUS_SUM))
                {
                    return -1;
				}
            }
            else
            {
                if (!(pte & PTE_U_MASK))
                {
                    return -1;
				}
            }
            /* protection check */
            /* MXR allows read access to execute-only pages */
            if (s.mstatus & MSTATUS_MXR)
            {
                xwr |= (xwr >> 2);
			}

            if (((xwr >> access) & 1) == 0)
            {
                return -1;
			}
            need_write = !(pte & PTE_A_MASK) ||
                (!(pte & PTE_D_MASK) && access == ACCESS_WRITE);
            pte |= PTE_A_MASK;
            if (access == ACCESS_WRITE)
                pte |= PTE_D_MASK;
            if (need_write)
            {
                if (pte_size_log2 == 2)
                {
                    phys_write!uint32_t(s, pte_addr, cast(uint32_t)pte);
				}
                else
                {
                    phys_write!uint64_t(s, pte_addr, pte);
				}
            }
            vaddr_mask = (cast(target_ulong)1 << vaddr_shift) - 1;
            *ppaddr = (vaddr & vaddr_mask) | (paddr  & ~vaddr_mask);
            return 0;
        }
        else
        {
            pte_addr = paddr;
        }
    }
    return -1;
}

/* return 0 if OK, != 0 if exception */
int target_read_slow(RISCVCPUState *s, mem_uint_t *pval,
                     target_ulong addr, int size_log2)
{
    int size, tlb_idx, err, al;
    target_ulong paddr, offset;
    uint8_t *ptr;
    PhysMemoryRange *pr;
    mem_uint_t ret;

    /* first handle unaligned accesses */
    size = 1 << size_log2;
    al = cast(int)(addr & (size - 1));
    if (al != 0)
    {
        switch(size_log2) {
        case 1:
            {
                uint8_t v0, v1;
                err = target_read!uint8_t(s, &v0, addr);
                if (err)
                    return err;
                err = target_read!uint8_t(s, &v1, addr + 1);
                if (err)
                    return err;
                ret = v0 | (v1 << 8);
            }
            break;
        case 2:
            {
                uint32_t v0, v1;
                addr -= al;
                err = target_read!uint32_t(s, &v0, addr);
                if (err)
                    return err;
                err = target_read!uint32_t(s, &v1, addr + 4);
                if (err)
                    return err;
                ret = (v0 >> (al * 8)) | (v1 << (32 - al * 8));
            }
            break;
static if (MLEN >= 64)
{
        case 3:
            {
                uint64_t v0, v1;
                addr -= al;
                err = target_read!uint64_t(s, &v0, addr);
                if (err)
                    return err;
                err = target_read!uint64_t(s, &v1, addr + 8);
                if (err)
                    return err;
                ret = (v0 >> (al * 8)) | (v1 << (64 - al * 8));
            }
            break;
}
static if (MLEN >= 128)
{
        case 4:
            {
                uint128_t v0, v1;
                addr -= al;
                err = target_read!uint128_t(s, &v0, addr);
                if (err)
                    return err;
                err = target_read!uint128_t(s, &v1, addr + 16);
                if (err)
                    return err;
                ret = (v0 >> (al * 8)) | (v1 << (128 - al * 8));
            }
            break;
}
        default:
            abort();
        }
    }
    else
    {
        if (get_phys_addr(s, &paddr, addr, ACCESS_READ))
        {
            s.pending_tval = addr;
            s.pending_exception = CAUSE_LOAD_PAGE_FAULT;
            return -1;
        }
        pr = get_phys_mem_range(s.mem_map, paddr);
        if (!pr) {
version(DUMP_INVALID_MEM_ACCESS)
{
            printf("target_read_slow: invalid physical address 0x");
            print_target_ulong(paddr);
            printf("\n");
}
            return 0;
        }
        else if (pr.is_ram)
        {
            tlb_idx = (addr >> PG_SHIFT) & (TLB_SIZE - 1);
            ptr = pr.phys_mem + cast(uintptr_t)(paddr - pr.addr);
            s.tlb_read[tlb_idx].vaddr = addr & ~PG_MASK;
            s.tlb_read[tlb_idx].mem_addend = cast(uintptr_t)ptr - addr;
            switch(size_log2)
            {
            case 0:
                ret = *cast(uint8_t *)ptr;
                break;
            case 1:
                ret = *cast(uint16_t *)ptr;
                break;
            case 2:
                ret = *cast(uint32_t *)ptr;
                break;
static if (MLEN >= 64)
{
            case 3:
                ret = *cast(uint64_t *)ptr;
                break;
}
static if (MLEN >= 128)
{
            case 4:
                ret = *cast(uint128_t *)ptr;
                break;
}
            default:
                abort();
            }
        }
        else
        {
            offset = paddr - pr.addr;
            err = 1;
            if (((pr.devio_flags >> size_log2) & 1) != 0)
            {
                ret = pr.read_func(pr.opaque, cast(uint32_t)offset, size_log2);
                err = 0; // Workaround
            }
static if (MLEN >= 64)
{
			/// FIXME Workaround
            // FIXME Was: else if ((pr.devio_flags & DEVIO_SIZE32) && size_log2 == 3)
            if (err && (pr.devio_flags & DEVIO_SIZE32) && size_log2 == 3)
            {
                /* emulate 64 bit access */
                ret = pr.read_func(pr.opaque, cast(uint32_t)offset, 2);
                ret |= cast(uint64_t)pr.read_func(pr.opaque, cast(uint32_t)offset + 4, 2) << 32;
                err = 0; // Workaround
            }
}
            // FIXME Was: else
            if (err)
            {
version(DUMP_INVALID_MEM_ACCESS)
{
                printf("unsupported device read access: addr=0x");
                print_target_ulong(paddr);
                printf(" width=%d bits\n", 1 << (3 + size_log2));
}
                ret = 0;
            }
        }
    }
    *pval = ret;
    return 0;
}

/* return 0 if OK, != 0 if exception */
int target_write_slow(RISCVCPUState *s, target_ulong addr,
                      mem_uint_t val, int size_log2)
{
    int size, i, tlb_idx, err;
    target_ulong paddr, offset;
    uint8_t *ptr;
    PhysMemoryRange *pr;
    
    /* first handle unaligned accesses */
    size = 1 << size_log2;
    if ((addr & (size - 1)) != 0) {
        /* XXX: should avoid modifying the memory in case of exception */
        for(i = 0; i < size; i++) {
            err = target_write!uint8_t(s, addr + i, (val >> (8 * i)) & 0xff);
            if (err)
                return err;
        }
    }
    else
    {
        if (get_phys_addr(s, &paddr, addr, ACCESS_WRITE)) {
            s.pending_tval = addr;
            s.pending_exception = CAUSE_STORE_PAGE_FAULT;
            return -1;
        }
        pr = get_phys_mem_range(s.mem_map, paddr);
        if (!pr) {
version(DUMP_INVALID_MEM_ACCESS)
{
            printf("target_write_slow: invalid physical address 0x");
            print_target_ulong(paddr);
            printf("\n");
}
        }
        else if (pr.is_ram)
        {
            phys_mem_set_dirty_bit(pr, paddr - pr.addr);
            tlb_idx = (addr >> PG_SHIFT) & (TLB_SIZE - 1);
            ptr = pr.phys_mem + cast(uintptr_t)(paddr - pr.addr);
            s.tlb_write[tlb_idx].vaddr = addr & ~PG_MASK;
            s.tlb_write[tlb_idx].mem_addend = cast(uintptr_t)ptr - addr;
            switch(size_log2) {
            case 0:
                *cast(uint8_t *)ptr = cast(uint8_t)val;
                break;
            case 1:
                *cast(uint16_t *)ptr = cast(uint16_t)val;
                break;
            case 2:
                *cast(uint32_t *)ptr = cast(uint32_t)val;
                break;
static if (MLEN >= 64)
{
            case 3:
                *cast(uint64_t *)ptr = cast(uint64_t)val;
                break;
}
static if (MLEN >= 128)
{
            case 4:
                *cast(uint128_t *)ptr = cast(uint128_t)val;
                break;
}
            default:
                abort();
            }
        }
        else
        {
			err = 1;
            offset = paddr - pr.addr;
            if (((pr.devio_flags >> size_log2) & 1) != 0) {
                pr.write_func(pr.opaque, cast(uint32_t)offset, cast(uint32_t)val, size_log2);
                err = 0;
            }
static if (MLEN >= 64)
{
			/// FIXME Workaround as in above function
            if (err && (pr.devio_flags & DEVIO_SIZE32) && size_log2 == 3)
            {
                /* emulate 64 bit access */
                pr.write_func(pr.opaque, cast(uint32_t)offset, val & 0xffffffff, 2);
                pr.write_func(pr.opaque, cast(uint32_t)offset + 4, (val >> 32) & 0xffffffff, 2);
                err = 0;
            }
}
             if (err)
             {
version(DUMP_INVALID_MEM_ACCESS)
{
                printf("unsupported device write access: addr=0x");
                print_target_ulong(paddr);
                printf(" width=%d bits\n", 1 << (3 + size_log2));
}
            }
        }
    }
    return 0;
}



/* XXX: inefficient but not critical as long as it is seldom used */
static void riscv_cpu_flush_tlb_write_range_ram(alias MAX_XLEN)(RISCVCPUState *s,
                           uint8_t *ram_ptr, size_t ram_size)
{
    uint8_t *ptr;
    uint8_t *ram_end;
    int i;
    
    ram_end = ram_ptr + ram_size;
    for(i = 0; i < TLB_SIZE; i++)
    {
        if (s.tlb_write[i].vaddr != -1)
        {
            ptr = cast(uint8_t *)(s.tlb_write[i].mem_addend +
                              cast(uintptr_t)s.tlb_write[i].vaddr);
            if (ptr >= ram_ptr && ptr < ram_end)
            {
                s.tlb_write[i].vaddr = -1;
            }
        }
    }
}
