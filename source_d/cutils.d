/*
 * Misc C utilities
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

module cutils;

import core.stdc.stdlib;
import core.stdc.stdio;
import core.stdc.string;
import core.stdc.inttypes;
import core.stdc.ctype;

public import dutils;

/*
#define likely(x)       __builtin_expect(!!(x), 1)
#define unlikely(x)     __builtin_expect(!!(x), 0)
#define force___attribute__((always_inline))
#define no___attribute__((noinline))
#define __maybe_unused __attribute__((unused))

#define xglue(x, y) x ## y
#define glue(x, y) xglue(x, y)
#define stringify(s)    tostring(s)
#define tostring(s)     #s

#ifndef offsetof
#define offsetof(type, field) ((size_t) &((type *)0).field)
#endif
#define countof(x) (sizeof(x) / sizeof(x[0]))



#define DLL_PUBLIC __attribute__ ((visibility ("default")))

#ifndef _BOOL_defined
#define _BOOL_defined
#undef FALSE
#undef TRUE

typedef int BOOL;
enum {
    FALSE = 0,
    TRUE = 1,
};
#endif

// this test works at least with gcc
#if defined(__SIZEOF_INT128__)
#define HAVE_INT128
#endif

#ifdef HAVE_INT128
typedef __int128 int128_t;
typedef unsigned __int128 uint128_t;
#endif
*/


// TODO All are supposed to be inlined
static int max_int(int a, int b)
{
    if (a > b)
        return a;
    else
        return b;
}

static int min_int(int a, int b)
{
    if (a < b)
        return a;
    else
        return b;
}



static uint32_t bswap_32(uint32_t v)
{
    return ((v & 0xff000000) >> 24) | ((v & 0x00ff0000) >>  8) |
        ((v & 0x0000ff00) <<  8) | ((v & 0x000000ff) << 24);
}

static uint16_t get_le16(const uint8_t *ptr)
{
    return ptr[0] | (ptr[1] << 8);
}

static uint32_t get_le32(const uint8_t *ptr)
{
    return ptr[0] | (ptr[1] << 8) | (ptr[2] << 16) | (ptr[3] << 24);
}

static uint64_t get_le64(const uint8_t *ptr)
{
    return get_le32(ptr) | (cast(uint64_t)get_le32(ptr + 4) << 32);
}

static void put_le16(uint8_t *ptr, uint16_t v)
{
    ptr[0] = cast(uint8_t)v;
    ptr[1] = cast(uint8_t)(v >> 8);
}

static void put_le32(uint8_t *ptr, uint32_t v)
{
    ptr[0] = cast(uint8_t)v;
    ptr[1] = cast(uint8_t)(v >> 8);
    ptr[2] = cast(uint8_t)(v >> 16);
    ptr[3] = cast(uint8_t)(v >> 24);
}

static void put_le64(uint8_t *ptr, uint64_t v)
{
    put_le32(ptr, cast(uint32_t)v);
    put_le32(ptr + 4, v >> 32);
}

static uint32_t get_be32(const uint8_t *d)
{
    return (d[0] << 24) | (d[1] << 16) | (d[2] << 8) | d[3];
}

static void put_be32(uint8_t *d, uint32_t v)
{
    d[0] = cast(uint8_t)(v >> 24);
    d[1] = cast(uint8_t)(v >> 16);
    d[2] = cast(uint8_t)(v >> 8);
    d[3] = cast(uint8_t)(v >> 0);
}

static void put_be64(uint8_t *d, uint64_t v)
{
    put_be32(d, cast(uint32_t)(v >> 32));
    put_be32(d + 4, cast(uint32_t)v);
}

/*
#ifdef WORDS_BIGENDIAN
static uint32_t cpu_to_be32(uint32_t v)
{
    return v;
}
#else
static uint32_t cpu_to_be32(uint32_t v)
{
    return bswap_32(v);
}
#endif

*/

/* XXX: optimize */
static int ctz32(uint32_t a)
{
    int i;
    if (a == 0)
        return 32;
    for(i = 0; i < 32; i++) {
        if ((a >> i) & 1)
            return i;
    }
    return 32;
}


void *mallocz(size_t size);
//void pstrcpy(char *buf, int buf_size, const char *str);
// char *pstrcat(char *buf, int buf_size, const char *s);
int strstart(const char *str, const char *val, const char **ptr);

struct DynBuf
{
    uint8_t *buf;
    size_t size;
    size_t allocated_size;
}

void dbuf_init(DynBuf *s);
void dbuf_write(DynBuf *s, size_t offset, const uint8_t *data, size_t len);
void dbuf_putc(DynBuf *s, uint8_t c);
void dbuf_putstr(DynBuf *s, const char *str);
void dbuf_free(DynBuf *s);

void *mallocz(size_t size)
{
    void *ptr;
    ptr = malloc(size);
    if (!ptr)
        return null;
    memset(ptr, 0, size);
    return ptr;
}
/*
void pstrcpy(char *buf, int buf_size, char *str)
{
    char c;
    char *q = buf;

    if (buf_size <= 0)
        return;

    for(;;) {
        c = *str;
        str++;
        if (c == 0 || q >= buf + buf_size - 1)
            break;
        *q++ = c;
    }
    *q = '\0';
}

char *pstrcat(char *buf, int buf_size, const char *s)
{
    int len;
    len = cast(int)strlen(buf);
    if (len < buf_size)
        pstrcpy(buf + len, buf_size - len, s);
    return buf;
}

int strstart(const (char) *str, const char *val, const (char) **ptr)
{
    const (char) *p;
    const (char) *q;
    p = str;
    q = val;
    while (*q != '\0') {
        if (*p != *q)
            return 0;
        p++;
        q++;
    }
    if (ptr)
        *ptr = p;
    return 1;
}
*/
void dbuf_init(DynBuf *s)
{
    memset(s, 0, (*s).sizeof);
}

void dbuf_write(DynBuf *s, size_t offset, const (uint8_t) *data, size_t len)
{

    size_t end, new_size;
    new_size = end = offset + len;
    if (new_size > s.allocated_size) {
        new_size = max_int(cast(uint32_t)new_size, cast(uint32_t)(s.allocated_size * 3 / 2) );
        s.buf = cast(uint8_t *)realloc(s.buf, new_size);
        s.allocated_size = new_size;
    }
    memcpy(s.buf + offset, data, len);
    if (end > s.size)
        s.size = end;
}
/*
void dbuf_putc(DynBuf *s, uint8_t c)
{
    dbuf_write(s, s.size, &c, 1);
}

void dbuf_putstr(DynBuf *s, const char *str)
{
    dbuf_write(s, s.size, cast(const (uint8_t) *)str, strlen(str));
}

void dbuf_free(DynBuf *s)
{
    free(s.buf);
    memset(s, 0, (*s).sizeof);
}
*/
