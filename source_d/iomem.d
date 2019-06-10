/*
 * IO memory handling
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

import core.stdc.stdlib;
import core.stdc.stdio;
import core.stdc.stdarg;
import core.stdc.string;
import core.stdc.inttypes;


import cutils;
import dutils;

/*
PHYS_MEM_READ_WRITE(8, uint8_t)
PHYS_MEM_READ_WRITE(32, uint32_t)
PHYS_MEM_READ_WRITE(64, uint64_t)
*/
alias DeviceWriteFunc = void function(void *opaque, uint32_t offset,
                             uint32_t val, int size_log2);
alias DeviceReadFunc = uint32_t function(void *opaque, uint32_t offset, int size_log2);

enum DEVIO_SIZE8 = (1 << 0);
enum DEVIO_SIZE16 = (1 << 1);
enum DEVIO_SIZE32 = (1 << 2);
/* not supported, could add specific 64 bit callbacks when needed */
//#define DEVIO_SIZE64 (1 << 3) 
enum DEVIO_DISABLED = (1 << 4);

enum DEVRAM_FLAG_ROM        = (1 << 0); /* not writable */
enum DEVRAM_FLAG_DIRTY_BITS = (1 << 1); /* maintain dirty bits */
enum DEVRAM_FLAG_DISABLED   = (1 << 2); /* allocated but not mapped */
enum DEVRAM_PAGE_SIZE_LOG2  = 12;
enum DEVRAM_PAGE_SIZE       = (1 << DEVRAM_PAGE_SIZE_LOG2);

struct PhysMemoryRange{
    PhysMemoryMap *map;
    uint64_t addr;
    uint64_t org_size; /* original size */
    uint64_t size; /* =org_size or 0 if the mapping is disabled */
    bool is_ram;
    /* the following is used for RAM access */
    int devram_flags;
    uint8_t *phys_mem;
    int dirty_bits_size; /* in bytes */
    uint32_t *dirty_bits; /* NULL if not used */
    uint32_t*[2] dirty_bits_tab;
    int dirty_bits_index; /* 0-1 */
    /* the following is used for I/O access */
    void *opaque;
    DeviceReadFunc read_func;
    DeviceWriteFunc write_func;
    int devio_flags;
}

enum PHYS_MEM_RANGE_MAX = 32;

struct PhysMemoryMap {
    int n_phys_mem_range;
    PhysMemoryRange[PHYS_MEM_RANGE_MAX] phys_mem_range;
    PhysMemoryRange * function(PhysMemoryMap *s, uint64_t addr, uint64_t size, int devram_flags) register_ram;
    void function(PhysMemoryMap *s, PhysMemoryRange *pr) free_ram;
    uint32_t * function(PhysMemoryMap *s, PhysMemoryRange *pr) get_dirty_bits;
    void function(PhysMemoryMap *s, PhysMemoryRange *pr, uint64_t addr, bool enabled) set_ram_addr;
    void *opaque;
    void function(void *opaque, uint8_t *ram_addr, size_t ram_size) flush_tlb_write_range;
}



PhysMemoryMap *phys_mem_map_init();

void phys_mem_map_end(PhysMemoryMap *s);
PhysMemoryRange *register_ram_entry(PhysMemoryMap *s, uint64_t addr,
                                    uint64_t size, int devram_flags);

// TODO inline
static  PhysMemoryRange *cpu_register_ram(PhysMemoryMap *s, uint64_t addr,
                                  uint64_t size, int devram_flags)
{
    return s.register_ram(s, addr, size, devram_flags);
}
PhysMemoryRange *cpu_register_device(PhysMemoryMap *s, uint64_t addr,
                                     uint64_t size, void *opaque,
                                     DeviceReadFunc *read_func, DeviceWriteFunc *write_func,
                                     int devio_flags);
PhysMemoryRange *get_phys_mem_range(PhysMemoryMap *s, uint64_t paddr);
void phys_mem_set_addr(PhysMemoryRange *pr, uint64_t addr, bool enabled);

// TODO inline
static  uint32_t *phys_mem_get_dirty_bits(PhysMemoryRange *pr)
{
    PhysMemoryMap *map = pr.map;
    return map.get_dirty_bits(map, pr);
}

// TODO inline
static void phys_mem_set_dirty_bit(PhysMemoryRange *pr, size_t offset)
{
    size_t page_index;
    uint32_t mask;
    uint32_t * dirty_bits_ptr;
    if (pr.dirty_bits) {
        page_index = offset >> DEVRAM_PAGE_SIZE_LOG2;
        mask = 1 << (page_index & 0x1f);
        dirty_bits_ptr = pr.dirty_bits + (page_index >> 5);
        *dirty_bits_ptr |= mask;
    }
}

// TODO inline
static bool phys_mem_is_dirty_bit(PhysMemoryRange *pr, size_t offset)
{
    size_t page_index;
    uint32_t *dirty_bits_ptr;
    if (!pr.dirty_bits)
        return true;
    page_index = offset >> DEVRAM_PAGE_SIZE_LOG2;
    dirty_bits_ptr = pr.dirty_bits + (page_index >> 5);
    return (*dirty_bits_ptr >> (page_index & 0x1f)) & 1;
}

void phys_mem_reset_dirty_bit(PhysMemoryRange *pr, size_t offset);
uint8_t *phys_mem_get_ram_ptr(PhysMemoryMap *map, uint64_t paddr, bool is_rw);

/* IRQ support */

alias SetIRQFunc = void function(void *opaque, int irq_num, int level);

struct IRQSignal{
    SetIRQFunc set_irq;
    void *opaque;
    int irq_num;
}

void irq_init(IRQSignal *irq, SetIRQFunc *set_irq, void *opaque, int irq_num);

// TODO inline
static void set_irq(IRQSignal *irq, int level)
{
    irq.set_irq(irq.opaque, irq.irq_num, level);
}


PhysMemoryMap *phys_mem_map_init()
{
    PhysMemoryMap *s;
    s = cast(PhysMemoryMap*) mallocz((*s).sizeof);
    s.register_ram = &default_register_ram;
    s.free_ram = &default_free_ram;
    s.get_dirty_bits = &default_get_dirty_bits;
    s.set_ram_addr = &default_set_addr;
    return s;
}

void phys_mem_map_end(PhysMemoryMap *s)
{
    int i;
    PhysMemoryRange *pr;

    for(i = 0; i < s.n_phys_mem_range; i++) {
        pr = &s.phys_mem_range[i];
        if (pr.is_ram) {
            s.free_ram(s, pr);
        }
    }
    free(s);
}

/* return null if not found */
/* XXX: optimize */
PhysMemoryRange *get_phys_mem_range(PhysMemoryMap *s, uint64_t paddr)
{
    PhysMemoryRange *pr;
    int i;
    for(i = 0; i < s.n_phys_mem_range; i++) {
        pr = &s.phys_mem_range[i];
        if (paddr >= pr.addr && paddr < pr.addr + pr.size)
            return pr;
    }
    return null;
}

PhysMemoryRange *register_ram_entry(PhysMemoryMap *s, uint64_t addr,
                                    uint64_t size, int devram_flags)
{
    PhysMemoryRange *pr;

    assert(s.n_phys_mem_range < PHYS_MEM_RANGE_MAX);
    assert((size & (DEVRAM_PAGE_SIZE - 1)) == 0 && size != 0);
    pr = &s.phys_mem_range[s.n_phys_mem_range++];
    pr.map = s;
    pr.is_ram = true;
    pr.devram_flags = devram_flags & ~DEVRAM_FLAG_DISABLED;
    pr.addr = addr;
    pr.org_size = size;
    if (devram_flags & DEVRAM_FLAG_DISABLED)
        pr.size = 0;
    else
        pr.size = pr.org_size;
    pr.phys_mem = null;
    pr.dirty_bits = null;
    return pr;
}

static PhysMemoryRange *default_register_ram(PhysMemoryMap *s, uint64_t addr,
                                             uint64_t size, int devram_flags)
{
    PhysMemoryRange *pr;

    pr = register_ram_entry(s, addr, size, devram_flags);

    pr.phys_mem = cast(uint8_t*) mallocz(size);
    if (!pr.phys_mem) {
        assert(0, "Could not allocate VM memory");
        
    }

    if (devram_flags & DEVRAM_FLAG_DIRTY_BITS) {
        size_t nb_pages;
        int i;
        nb_pages = size >> DEVRAM_PAGE_SIZE_LOG2;
        pr.dirty_bits_size = cast(uint32_t) (((nb_pages + 31) / 32) * uint32_t.sizeof);
        pr.dirty_bits_index = 0;
        for(i = 0; i < 2; i++) {
            pr.dirty_bits_tab[i] = cast(uint32_t*) mallocz(pr.dirty_bits_size);
        }
        pr.dirty_bits = pr.dirty_bits_tab[pr.dirty_bits_index];
    }
    return pr;
}

/* return a pointer to the bitmap of dirty bits and reset them */
static uint32_t *default_get_dirty_bits(PhysMemoryMap *map,
                                              PhysMemoryRange *pr)
{
    uint32_t *dirty_bits;
    bool has_dirty_bits;
    size_t n, i;
    
    dirty_bits = pr.dirty_bits;

    has_dirty_bits = false;
    n = pr.dirty_bits_size / (uint32_t.sizeof);
    for(i = 0; i < n; i++) {
        if (dirty_bits[i] != 0) {
            has_dirty_bits = true;
            break;
        }
    }
    if (has_dirty_bits && pr.size != 0) {
        /* invalidate the corresponding CPU write TLBs */
        map.flush_tlb_write_range(map.opaque, pr.phys_mem, pr.org_size);
    }
    
    pr.dirty_bits_index ^= 1;
    pr.dirty_bits = pr.dirty_bits_tab[pr.dirty_bits_index];
    memset(pr.dirty_bits, 0, pr.dirty_bits_size);
    return dirty_bits;
}

/* reset the dirty bit of one page at 'offset' inside 'pr' */
void phys_mem_reset_dirty_bit(PhysMemoryRange *pr, size_t offset)
{
    size_t page_index;
    uint32_t mask;
    uint32_t * dirty_bits_ptr;
    PhysMemoryMap *map;
    if (pr.dirty_bits) {
        page_index = offset >> DEVRAM_PAGE_SIZE_LOG2;
        mask = 1 << (page_index & 0x1f);
        dirty_bits_ptr = pr.dirty_bits + (page_index >> 5);
        if (*dirty_bits_ptr & mask) {
            *dirty_bits_ptr &= ~mask;
            /* invalidate the corresponding CPU write TLBs */
            map = pr.map;
            map.flush_tlb_write_range(map.opaque,
                                       pr.phys_mem + (offset & ~(DEVRAM_PAGE_SIZE - 1)),
                                       DEVRAM_PAGE_SIZE);
        }
    }
}

static void default_free_ram(PhysMemoryMap *s, PhysMemoryRange *pr)
{
    free(pr.phys_mem);
}

PhysMemoryRange *cpu_register_device(PhysMemoryMap *s, uint64_t addr,
                                     uint64_t size, void *opaque,
                                     DeviceReadFunc read_func, DeviceWriteFunc write_func,
                                     int devio_flags)
{
    PhysMemoryRange *pr;
    assert(s.n_phys_mem_range < PHYS_MEM_RANGE_MAX);
    assert(size <= 0xffffffff);
    pr = &s.phys_mem_range[s.n_phys_mem_range++];
    pr.map = s;
    pr.addr = addr;
    pr.org_size = size;
    if (devio_flags & DEVIO_DISABLED)
        pr.size = 0;
    else
        pr.size = pr.org_size;
    pr.is_ram = false;
    pr.opaque = opaque;
    pr.read_func = read_func;
    pr.write_func = write_func;
    pr.devio_flags = devio_flags;
    return pr;
}

static void default_set_addr(PhysMemoryMap *map,
                             PhysMemoryRange *pr, uint64_t addr, bool enabled)
{
    if (enabled) {
        if (pr.size == 0 || pr.addr != addr) {
            /* enable or move mapping */
            if (pr.is_ram) {
                map.flush_tlb_write_range(map.opaque,
                                           pr.phys_mem, pr.org_size);
            }
            pr.addr = addr;
            pr.size = pr.org_size;
        }
    } else {
        if (pr.size != 0) {
            /* disable mapping */
            if (pr.is_ram) {
                map.flush_tlb_write_range(map.opaque,
                                           pr.phys_mem, pr.org_size);
            }
            pr.addr = 0;
            pr.size = 0;
        }
    }
}

void phys_mem_set_addr(PhysMemoryRange *pr, uint64_t addr, bool enabled)
{
    PhysMemoryMap *map = pr.map;
    if (!pr.is_ram) {
        default_set_addr(map, pr, addr, enabled);
    } else {
        return map.set_ram_addr(map, pr, addr, enabled);
    }
}

/* return null if no valid RAM page. The access can only be done in the page */
uint8_t *phys_mem_get_ram_ptr(PhysMemoryMap *map, uint64_t paddr, bool is_rw)
{
    PhysMemoryRange *pr = get_phys_mem_range(map, paddr);
    uintptr_t offset;
    if (!pr || !pr.is_ram)
        return null;
    offset = paddr - pr.addr;
    if (is_rw)
        phys_mem_set_dirty_bit(pr, offset);
    return pr.phys_mem + cast(uintptr_t)offset;
}

/* IRQ support */

void irq_init(IRQSignal *irq, SetIRQFunc set_irq, void *opaque, int irq_num)
{
    irq.set_irq = set_irq;
    irq.opaque = opaque;
    irq.irq_num = irq_num;
}
