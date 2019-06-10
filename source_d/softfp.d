/*
 * SoftFP Library
 * 
 * Copyright (c) 2016 Fabrice Bellard
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

module softfplib;
 
import core.stdc.stdlib;
import core.stdc.inttypes;
import core.stdc.stdio;
import core.stdc.string;

import cutils;


import std.meta;
import std.traits;

enum RoundingMode {
    RNE, /* Round to Nearest, ties to Even */
    RTZ, /* Round towards Zero */
    RDN, /* Round Down */
    RUP, /* Round Up */
    RMM, /* Round to Nearest, ties to Max Magnitude */
} ;

enum FFLAG_INVALID_OP  = (1 << 4);
enum FFLAG_DIVIDE_ZERO = (1 << 3);
enum FFLAG_OVERFLOW    = (1 << 2);
enum FFLAG_UNDERFLOW   = (1 << 1);
enum FFLAG_INEXACT     = (1 << 0);

enum FCLASS_NINF       = (1 << 0);
enum FCLASS_NNORMAL    = (1 << 1);
enum FCLASS_NSUBNORMAL = (1 << 2);
enum FCLASS_NZERO      = (1 << 3);
enum FCLASS_PZERO      = (1 << 4);
enum FCLASS_PSUBNORMAL = (1 << 5);
enum FCLASS_PNORMAL    = (1 << 6);
enum FCLASS_PINF       = (1 << 7);
enum FCLASS_SNAN       = (1 << 8);
enum FCLASS_QNAN       = (1 << 9);


enum FSIGN_MASK32  = (1 << 31);
enum FSIGN_MASK64  = (cast(uint64_t)1 << 63);

enum HAVE_INT128 = false;

static if (HAVE_INT128)
{
	enum FSIGN_MASK128 = (cast(uint128_t)1 << 127);
}

alias sfloat32 = uint32_t;
alias  sfloat64 = uint64_t;


template Doubled(T)
{
    alias smallTypes = AliasSeq!(ubyte, ushort, uint);
    alias doubledTypes = AliasSeq!(ushort, uint, ulong);
    enum int index =  staticIndexOf!(T, smallTypes);
    static if (index > -1 && index < doubledTypes.lenght)
    {
        alias Doubled = doubledTypes[index];
    }
    else
    {
        static assert (false, "Unsupported Type!");
    }
}

template softfp(alias F_SIZE)
{
    static if (F_SIZE == 32)
    {
        alias F_UINT = uint32_t;
        alias F_ULONG = uint64_t;
        enum MANT_SIZE = 23;
        enum EXP_SIZE = 8;
    }
    else static if (F_SIZE == 64)
    {
        alias F_UHALF = uint32_t;
        alias F_UINT = uint64_t;

        static if (HAVE_INT128)
        {
            alias F_ULONG = uint128_t;
        }
        enum MANT_SIZE = 52;
        enum EXP_SIZE = 11;
    }
    else static if (F_SIZE == 128)
        {
            alias F_UHALF = uint64_t;
            alias F_UINT = uint128_t;
            enum MANT_SIZE = 112;
            enum EXP_SIZE = 1;
        }
        else
        {
            static assert (false, "unsupported F_SIZE");

        }


    enum EXP_MASK = (1 << EXP_SIZE) - 1;
    enum MANT_MASK = (cast(F_UINT)1 << MANT_SIZE) - 1;
    enum SIGN_MASK = cast(F_UINT)1 << (F_SIZE - 1);
    enum IMANT_SIZE = F_SIZE - 2; /* internal mantissa size */
    enum RND_SIZE = IMANT_SIZE - MANT_SIZE;
    enum QNAN_MASK = cast(F_UINT)1 << (MANT_SIZE - 1);

    /*
    // quiet NaN
    #define clz glue(clz, F_SIZE)
    #define F_QNAN glue(F_QNAN, F_SIZE)
    #define pack_sf glue(pack_sf, F_SIZE)
    #define unpack_sf glue(unpack_sf, F_SIZE)
    #define rshift_rnd glue(rshift_rnd, F_SIZE)
    #define round_pack_sf glue(roundpack_sf, F_SIZE)
    #define normalize_sf glue(normalize_sf, F_SIZE)
    #define issignan_sf glue(issignan_sf, F_SIZE)
    #define normalize2_sf glue(normalize2_sf, F_SIZE)
    #define isnan_sf glue(isnan_sf, F_SIZE)
    #define add_sf glue(add_sf, F_SIZE)
    #define mul_sf glue(mul_sf, F_SIZE)
    #define fma_sf glue(fma_sf, F_SIZE)
    #define div_sf glue(div_sf, F_SIZE)
    #define sqrt_sf glue(sqrt_sf, F_SIZE)
    #define normalize_subnormal_sf glue(normalize_subnormal_sf, F_SIZE)
    #define divrem_u glue(divrem_u, F_SIZE)
    #define sqrtrem_u glue(sqrtrem_u, F_SIZE)
    #define mul_u glue(mul_u, F_SIZE)
    #define cvt_sf32_sf glue(cvt_sf32_sf, F_SIZE)
    #define cvt_sf64_sf glue(cvt_sf64_sf, F_SIZE)

    */


	
	// TODO inline
	static int clz(T)(T a)
	{
		int r;
		if (a == 0) {
			r = F_SIZE;
		} else {
			T i = a;
			r = 0;
			while (i >= 0)
			{
				i = i << 1;
				r++;
			}
		}
		return r;
	}




	static if (HAVE_INT128)
	{
		// TODO inline
		static int clz(F_SIZE)(uint128_t a) if (F_SIZE == 128)
		{
			int r;
			if (a == 0)
			{
				r = 128;
			}
			else
			{
				uint64_t ah, al;
				ah = a >> 64;
				al = a;
				if (ah != 0)
					r = __builtin_clzll(ah);
				else
					r = __builtin_clzll(al) + 64;
			}
			return r;
		}
	}

    static const F_UINT F_QNAN = ((cast(F_UINT)EXP_MASK << MANT_SIZE) | (cast(F_UINT)1 << (MANT_SIZE - 1)));

    // TODO inline
    static  F_UINT pack(uint32_t a_sign, uint32_t a_exp, F_UINT a_mant)
    {
        return (cast(F_UINT)a_sign << (F_SIZE - 1)) |
        (cast(F_UINT)a_exp << MANT_SIZE) |
        (a_mant & MANT_MASK);
    }

    // TODO inline
    static F_UINT unpack(uint32_t *pa_sign, int32_t *pa_exp, F_UINT a)
    {
        *pa_sign = a >> (F_SIZE - 1);
        *pa_exp = (a >> MANT_SIZE) & EXP_MASK;
        return a & MANT_MASK;
    }

    static F_UINT rshift_rnd(F_UINT a, int d)
    {
        F_UINT mask;
        if (d != 0) {
            if (d >= F_SIZE) {
                a = (a != 0);
            } else {
                mask = (cast(F_UINT)1 << d) - 1;
                a = (a >> d) | ((a & mask) != 0);
            }
        }
        return a;
    }

    /* a_mant is considered to have its MSB at F_SIZE - 2 bits */
    static F_UINT round_pack(uint32_t a_sign, int a_exp, F_UINT a_mant, RoundingMode rm, uint32_t *pfflags)
    {
        int diff;
        uint32_t addend, rnd_bits;

        switch (rm) {
            case RoundingMode.RNE:
            case RoundingMode.RMM:
            addend = (1 << (RND_SIZE - 1));
            break ;
            case RoundingMode.RTZ:
            addend = 0;
            break ;
            default:
            case RoundingMode.RDN:
            case RoundingMode.RUP:
            //        printf("s=%d rm=%d m=%x\n", a_sign, rm, a_mant);
            if (a_sign ^ (rm & 1))
                addend = (1 << RND_SIZE) - 1;
            else
                addend = 0;
            break ;
        }

        /* potentially subnormal */
        if (a_exp <= 0) {
            bool is_subnormal;
            /* Note: we set the underflow flag if the rounded result
               is subnormal and inexact */
            is_subnormal = (a_exp < 0 ||
            (a_mant + addend) < (cast(F_UINT)1 << (F_SIZE - 1)));
            diff = 1 - a_exp;
            a_mant = rshift_rnd(a_mant, diff);
            rnd_bits = a_mant & ((1 << RND_SIZE ) - 1);
            if (is_subnormal && rnd_bits != 0) {
                *pfflags |= FFLAG_UNDERFLOW;
            }
            a_exp = 1;
        } else {
            rnd_bits = a_mant & ((1 << RND_SIZE ) - 1);
        }
        if (rnd_bits != 0)
            *pfflags |= FFLAG_INEXACT;
        a_mant = (a_mant + addend) >> RND_SIZE;
        /* half way: select even result */
        if (rm == RoundingMode.RNE && rnd_bits == (1 << (RND_SIZE - 1)))
            a_mant &= ~1;
        /* Note the rounding adds at least 1, so this is the maximum
           value */
        a_exp += a_mant >> (MANT_SIZE + 1);
        if (a_mant <= MANT_MASK) {
            /* denormalized or zero */
            a_exp = 0;
        } else if (a_exp >= EXP_MASK) {
            /* overflow */
            if (addend == 0) {
                a_exp = EXP_MASK - 1;
                a_mant = MANT_MASK;
            } else {
                /* infinity */
                a_exp = EXP_MASK;
                a_mant = 0;
            }
            *pfflags |= FFLAG_OVERFLOW | FFLAG_INEXACT;
        }
        return pack(a_sign, a_exp, a_mant);
    }

    /* a_mant is considered to have at most F_SIZE - 1 bits */
    static F_UINT normalize(uint32_t a_sign, int a_exp, F_UINT a_mant, RoundingMode rm, uint32_t *pfflags)
    {
        int shift;
        shift = clz(a_mant) - (F_SIZE - 1 - IMANT_SIZE);
        assert(shift >= 0);
        a_exp -= shift;
        a_mant <<= shift;
        return round_pack(a_sign, a_exp, a_mant, rm, pfflags);
    }

    /* same as normalize() but with a double word mantissa. a_mant1 is
       considered to have at most F_SIZE - 1 bits */
    static F_UINT normalize2(uint32_t a_sign, int a_exp, F_UINT a_mant1, F_UINT a_mant0, RoundingMode rm, uint32_t *pfflags)
    {
        int l, shift;
        if (a_mant1 == 0) {
            l = F_SIZE + clz(a_mant0);
        } else {
            l = clz(a_mant1);
        }
        shift = l - (F_SIZE - 1 - IMANT_SIZE);
        assert(shift >= 0);
        a_exp -= shift;
        if (shift == 0) {
            a_mant1 |= (a_mant0 != 0);
        } else if (shift < F_SIZE) {
            a_mant1 = (a_mant1 << shift) | (a_mant0 >> (F_SIZE - shift));
            a_mant0 <<= shift;
            a_mant1 |= (a_mant0 != 0);
        } else {
            a_mant1 = a_mant0 << (shift - F_SIZE);
        }
        return round_pack(a_sign, a_exp, a_mant1, rm, pfflags);
    }

    bool issignan(F_UINT a)
    {
        uint32_t a_exp1;
        F_UINT a_mant;
        a_exp1 = (a >> (MANT_SIZE - 1)) & ((1 << (EXP_SIZE + 1)) - 1);
        a_mant = a & MANT_MASK;
        return (a_exp1 == (2 * EXP_MASK) && a_mant != 0);
    }

    bool isnan(F_UINT a)
    {
        uint32_t a_exp;
        F_UINT a_mant;
        a_exp = (a >> MANT_SIZE) & EXP_MASK;
        a_mant = a & MANT_MASK;
        return (a_exp == EXP_MASK && a_mant != 0);
    }


    F_UINT add(F_UINT a, F_UINT b, RoundingMode rm,
    uint32_t *pfflags)
    {
        uint32_t a_sign, b_sign, a_exp, b_exp;
        F_UINT tmp, a_mant, b_mant;

        /* swap so that  abs(a) >= abs(b) */
        if ((a & ~SIGN_MASK) < (b & ~SIGN_MASK)) {
            tmp = a;
            a = b;
            b = tmp;
        }
        a_sign = a >> (F_SIZE - 1);
        b_sign = b >> (F_SIZE - 1);
        a_exp = (a >> MANT_SIZE) & EXP_MASK;
        b_exp = (b >> MANT_SIZE) & EXP_MASK;
        a_mant = (a & MANT_MASK) << 3;
        b_mant = (b & MANT_MASK) << 3;
        // TODO unlikly
        if (a_exp == EXP_MASK) {
            if (a_mant != 0) {
                /* NaN result */
                if (!(a_mant & (QNAN_MASK << 3)) || issignan(b))
                    *pfflags |= FFLAG_INVALID_OP;
                return F_QNAN;
            } else if (b_exp == EXP_MASK && a_sign != b_sign) {
                *pfflags |= FFLAG_INVALID_OP;
                return F_QNAN;
            } else {
                /* infinity */
                return a;
            }
        }
        if (a_exp == 0) {
            a_exp = 1;
        } else {
            a_mant |= cast(F_UINT)1 << (MANT_SIZE + 3);
        }
        if (b_exp == 0) {
            b_exp = 1;
        } else {
            b_mant |= cast(F_UINT)1 << (MANT_SIZE + 3);
        }
        b_mant = rshift_rnd(b_mant, a_exp - b_exp);
        if (a_sign == b_sign) {
            /* same signs : add the absolute values  */
            a_mant += b_mant;
        } else {
            /* different signs : subtract the absolute values  */
            a_mant -= b_mant;
            if (a_mant == 0) {
                /* zero result : the sign needs a specific handling */
                a_sign = (rm == RoundingMode.RDN);
            }
        }
        a_exp += (RND_SIZE - 3);
        return normalize(a_sign, a_exp, a_mant, rm, pfflags);
    }

    F_UINT sub(F_UINT a, F_UINT b, RoundingMode rm, uint32_t *pfflags)
    {
        return add(a, b ^ SIGN_MASK, rm, pfflags);
    }

    // TODO inline
    static F_UINT normalize_subnormal(int32_t *pa_exp, F_UINT a_mant)
    {
        int shift;
        shift = MANT_SIZE - ((F_SIZE - 1 - clz(a_mant)));
        *pa_exp = 1 - shift;
        return a_mant << shift;
    }

    static if (is (F_ULONG))
    {
        static F_UINT mul_u(F_UINT *plow, F_UINT a, F_UINT b)
        {
            F_ULONG r;
            r = cast(F_ULONG)a * cast(F_ULONG)b;
            *plow = cast(F_UINT)r;
            return r >> F_SIZE;
        }
    }
    else
    {
        enum FH_SIZE = (F_SIZE / 2);

        static F_UINT mul_u(F_UINT *plow, F_UINT a, F_UINT b)
        {
            F_UHALF a0, a1, b0, b1, r0, r1, r2, r3;
            F_UINT r00, r01, r10, r11, c;
            a0 = cast(F_UHALF)a;
            a1 = a >> FH_SIZE;
            b0 = cast(F_UHALF)b;
            b1 = b >> FH_SIZE;

            r00 = cast(F_UINT)a0 * cast(F_UINT)b0;
            r01 = cast(F_UINT)a0 * cast(F_UINT)b1;
            r10 = cast(F_UINT)a1 * cast(F_UINT)b0;
            r11 = cast(F_UINT)a1 * cast(F_UINT)b1;

            r0 = cast(F_UHALF)r00;
            c = cast(F_UINT)((r00 >> FH_SIZE) + cast(F_UHALF)r01 + cast(F_UHALF)r10);
            r1 = cast(F_UHALF)c;
            c = cast(F_UINT)((c >> FH_SIZE) + (r01 >> FH_SIZE) + (r10 >> FH_SIZE) + cast(F_UHALF)r11);
            r2 = cast(F_UHALF)c;
            r3 = cast(F_UHALF)((c >> FH_SIZE) + (r11 >> FH_SIZE));

            *plow = (cast(F_UINT)r1 << FH_SIZE) | r0;
            return (cast(F_UINT)r3 << FH_SIZE) | r2;
        }

    }




    F_UINT mul(F_UINT a, F_UINT b, RoundingMode rm, uint32_t *pfflags)
    {
        uint32_t a_sign, b_sign, r_sign;
        int32_t a_exp, b_exp, r_exp;
        F_UINT a_mant, b_mant, r_mant, r_mant_low;

        a_sign = a >> (F_SIZE - 1);
        b_sign = b >> (F_SIZE - 1);
        r_sign = a_sign ^ b_sign;
        a_exp = (a >> MANT_SIZE) & EXP_MASK;
        b_exp = (b >> MANT_SIZE) & EXP_MASK;
        a_mant = a & MANT_MASK;
        b_mant = b & MANT_MASK;
        if (a_exp == EXP_MASK || b_exp == EXP_MASK) {
            if (isnan(a) || isnan(b)) {
                if (issignan(a) || issignan(b)) {
                    *pfflags |= FFLAG_INVALID_OP;
                }
                return F_QNAN;
            } else {
                /* infinity */
                if ((a_exp == EXP_MASK && (b_exp == 0 && b_mant == 0)) ||
                (b_exp == EXP_MASK && (a_exp == 0 && a_mant == 0))) {
                    *pfflags |= FFLAG_INVALID_OP;
                    return F_QNAN;
                } else {
                    return pack(r_sign, EXP_MASK, 0);
                }
            }
        }
        if (a_exp == 0) {
            if (a_mant == 0)
                return pack(r_sign, 0, 0); /* zero */
            a_mant = normalize_subnormal(&a_exp, a_mant);
        } else {
            a_mant |= cast(F_UINT)1 << MANT_SIZE;
        }
        if (b_exp == 0) {
            if (b_mant == 0)
                return pack(r_sign, 0, 0); /* zero */
            b_mant = normalize_subnormal(&b_exp, b_mant);
        } else {
            b_mant |= cast(F_UINT)1 << MANT_SIZE;
        }
        r_exp = a_exp + b_exp - (1 << (EXP_SIZE - 1)) + 2;

        r_mant = mul_u(&r_mant_low,a_mant << RND_SIZE, b_mant << (RND_SIZE + 1));
        r_mant |= (r_mant_low != 0);
        return normalize(r_sign, r_exp, r_mant, rm, pfflags);
    }

    /* fused multiply and add */
    F_UINT fma(F_UINT a, F_UINT b, F_UINT c, RoundingMode rm, uint32_t *pfflags)
    {
        uint32_t a_sign, b_sign, c_sign, r_sign;
        int32_t a_exp, b_exp, c_exp, r_exp, shift;
        F_UINT a_mant, b_mant, c_mant, r_mant1, r_mant0, c_mant1, c_mant0, mask;

        a_sign = a >> (F_SIZE - 1);
        b_sign = b >> (F_SIZE - 1);
        c_sign = c >> (F_SIZE - 1);
        r_sign = a_sign ^ b_sign;
        a_exp = (a >> MANT_SIZE) & EXP_MASK;
        b_exp = (b >> MANT_SIZE) & EXP_MASK;
        c_exp = (c >> MANT_SIZE) & EXP_MASK;
        a_mant = a & MANT_MASK;
        b_mant = b & MANT_MASK;
        c_mant = c & MANT_MASK;
        if (a_exp == EXP_MASK || b_exp == EXP_MASK || c_exp == EXP_MASK) {
            if (isnan(a) || isnan(b) || isnan(c)) {
                if (issignan(a) || issignan(b) || issignan(c)) {
                    *pfflags |= FFLAG_INVALID_OP;
                }
                return F_QNAN;
            } else {
                /* infinities */
                if ((a_exp == EXP_MASK && (b_exp == 0 && b_mant == 0)) ||
                (b_exp == EXP_MASK && (a_exp == 0 && a_mant == 0)) ||
                ((a_exp == EXP_MASK || b_exp == EXP_MASK) &&
                (c_exp == EXP_MASK && r_sign != c_sign))) {
                    *pfflags |= FFLAG_INVALID_OP;
                    return F_QNAN;
                } else if (c_exp == EXP_MASK) {
                    return pack(c_sign, EXP_MASK, 0);
                } else {
                    return pack(r_sign, EXP_MASK, 0);
                }
            }
        }
        if (a_exp == 0) {
            if (a_mant == 0)
                goto mul_zero;
            a_mant = normalize_subnormal(&a_exp, a_mant);
        } else {
            a_mant |= cast(F_UINT)1 << MANT_SIZE;
        }
        if (b_exp == 0) {
            if (b_mant == 0) {
                mul_zero:
                if (c_exp == 0 && c_mant == 0) {
                    if (c_sign != r_sign)
                        r_sign = (rm == RoundingMode.RDN);
                    return pack(r_sign, 0, 0);
                } else {
                    return c;
                }
            }
            b_mant = normalize_subnormal(&b_exp, b_mant);
        } else {
            b_mant |= cast(F_UINT)1 << MANT_SIZE;
        }
        /* multiply */
        r_exp = a_exp + b_exp - (1 << (EXP_SIZE - 1)) + 3;

        r_mant1 = mul_u(&r_mant0, a_mant << RND_SIZE, b_mant << RND_SIZE);
        /* normalize to F_SIZE - 3 */
        if (r_mant1 < (cast(F_UINT)1 << (F_SIZE - 3))) {
            r_mant1 = (r_mant1 << 1) | (r_mant0 >> (F_SIZE - 1));
            r_mant0 <<= 1;
            r_exp--;
        }

        /* add */
        if (c_exp == 0) {
            if (c_mant == 0) {
                /* add zero */
                r_mant1 |= (r_mant0 != 0);
                return normalize(r_sign, r_exp, r_mant1, rm, pfflags);
            }
            c_mant = normalize_subnormal(&c_exp, c_mant);
        } else {
            c_mant |= cast(F_UINT)1 << MANT_SIZE;
        }
        c_exp++;
        c_mant1 = c_mant << (RND_SIZE - 1);
        c_mant0 = 0;

        //    printf("r_s=%d r_exp=%d r_mant=%08x %08x\n", r_sign, r_exp, (uint32_t)r_mant1, (uint32_t)r_mant0);
        //    printf("c_s=%d c_exp=%d c_mant=%08x %08x\n", c_sign, c_exp, (uint32_t)c_mant1, (uint32_t)c_mant0);

        /* ensure that abs(r) >= abs(c) */
        if (!(r_exp > c_exp || (r_exp == c_exp && r_mant1 >= c_mant1))) {
            F_UINT tmp;
            int32_t c_tmp;
            /* swap */
            tmp = r_mant1; r_mant1 = c_mant1; c_mant1 = tmp;
            tmp = r_mant0; r_mant0 = c_mant0; c_mant0 = tmp;
            c_tmp = r_exp; r_exp = c_exp; c_exp = c_tmp;
            c_tmp = r_sign; r_sign = c_sign; c_sign = c_tmp;
        }
        /* right shift c_mant */
        shift = r_exp - c_exp;
        if (shift >= 2 * F_SIZE) {
            c_mant0 = (c_mant0 | c_mant1) != 0;
            c_mant1 = 0;
        } else if (shift >= F_SIZE + 1) {
            c_mant0 = rshift_rnd(c_mant1, shift - F_SIZE);
            c_mant1 = 0;
        } else if (shift == F_SIZE) {
            c_mant0 = c_mant1 | (c_mant0 != 0);
            c_mant1 = 0;
        } else if (shift != 0) {
            mask = (cast(F_UINT)1 << shift) - 1;
            c_mant0 = (c_mant1 << (F_SIZE - shift)) | (c_mant0 >> shift) | ((c_mant0 & mask) != 0);
            c_mant1 = c_mant1 >> shift;
        }
        //    printf("  r_mant=%08x %08x\n", (uint32_t)r_mant1, (uint32_t)r_mant0);
        //    printf("  c_mant=%08x %08x\n", (uint32_t)c_mant1, (uint32_t)c_mant0);
        /* add or subtract */
        if (r_sign == c_sign) {
            r_mant0 += c_mant0;
            r_mant1 += c_mant1 + (r_mant0 < c_mant0);
        } else {
            F_UINT tmp;
            tmp = r_mant0;
            r_mant0 -= c_mant0;
            r_mant1 = r_mant1 - c_mant1 - (r_mant0 > tmp);
            if ((r_mant0 | r_mant1) == 0) {
                /* zero result : the sign needs a specific handling */
                r_sign = (rm == RoundingMode.RDN);
            }
        }
        
        /// FIXME Remove?
        version(DISABLED)
        {
            //    printf("  r1_mant=%08x %08x\n", (uint32_t)r_mant1, (uint32_t)r_mant0);
            /* normalize */
            if (r_mant1 == 0) {
                r_mant1 = r_mant0;
                r_exp -= F_SIZE;
            } else {
                shift = clz(r_mant1) - (F_SIZE - 1 - IMANT_SIZE);
                if (shift != 0) {
                    r_mant1 = (r_mant1 << shift) | (r_mant0 >> (F_SIZE - shift));
                    r_mant0 <<= shift;
                    r_exp -= shift;
                }
                r_mant1 |= (r_mant0 != 0);
            }
            return normalize(r_sign, r_exp, r_mant1, rm, pfflags);
        }
        //
        return normalize2(r_sign, r_exp, r_mant1, r_mant0, rm, pfflags);

    }

    static if (is (F_ULONG))
    {

        static F_UINT divrem_u(F_UINT *pr, F_UINT ah, F_UINT al, F_UINT b)
        {
            F_ULONG a;
            a = (cast(F_ULONG)ah << F_SIZE) | al;
            *pr = a % b;
            return cast(F_UINT)(a / b);
        }
    }
    else
    {
        /* XXX: optimize */
        static F_UINT divrem_u(F_UINT *pr, F_UINT a1, F_UINT a0, F_UINT b)
        {
            int i, qb, ab;

            assert(a1 < b);
            for (i = 0; i < F_SIZE; i++) {
                ab = a1 >> (F_SIZE - 1);
                a1 = (a1 << 1) | (a0 >> (F_SIZE - 1));
                if (ab || a1 >= b) {
                    a1 -= b;
                    qb = 1;
                } else {
                    qb = 0;
                }
                a0 = (a0 << 1) | qb;
            }
            *pr = a1;
            return a0;
        }

    }

    F_UINT div(F_UINT a, F_UINT b, RoundingMode rm,
    uint32_t *pfflags)
    {
        uint32_t a_sign, b_sign, r_sign;
        int32_t a_exp, b_exp, r_exp;
        F_UINT a_mant, b_mant, r_mant, r;

        a_sign = a >> (F_SIZE - 1);
        b_sign = b >> (F_SIZE - 1);
        r_sign = a_sign ^ b_sign;
        a_exp = (a >> MANT_SIZE) & EXP_MASK;
        b_exp = (b >> MANT_SIZE) & EXP_MASK;
        a_mant = a & MANT_MASK;
        b_mant = b & MANT_MASK;
        if (a_exp == EXP_MASK) {
            if (a_mant != 0 || isnan(b)) {
                if (issignan(a) || issignan(b)) {
                    *pfflags |= FFLAG_INVALID_OP;
                }
                return F_QNAN;
            } else if (b_exp == EXP_MASK) {
                *pfflags |= FFLAG_INVALID_OP;
                return F_QNAN;
            } else {
                return pack(r_sign, EXP_MASK, 0);
            }
        } else if (b_exp == EXP_MASK) {
            if (b_mant != 0) {
                if (issignan(a) || issignan(b)) {
                    *pfflags |= FFLAG_INVALID_OP;
                }
                return F_QNAN;
            } else {
                return pack(r_sign, 0, 0);
            }
        }

        if (b_exp == 0) {
            if (b_mant == 0) {
                /* zero */
                if (a_exp == 0 && a_mant == 0) {
                    *pfflags |= FFLAG_INVALID_OP;
                    return F_QNAN;
                } else {
                    *pfflags |= FFLAG_DIVIDE_ZERO;
                    return pack(r_sign, EXP_MASK, 0);
                }
            }
            b_mant = normalize_subnormal(&b_exp, b_mant);
        } else {
            b_mant |= cast(F_UINT)1 << MANT_SIZE;
        }
        if (a_exp == 0) {
            if (a_mant == 0)
                return pack(r_sign, 0, 0); /* zero */
            a_mant = normalize_subnormal(&a_exp, a_mant);
        } else {
            a_mant |= cast(F_UINT)1 << MANT_SIZE;
        }
        r_exp = a_exp - b_exp + (1 << (EXP_SIZE - 1)) - 1;
        r_mant = divrem_u(&r, a_mant, 0, b_mant << 2);
        if (r != 0)
            r_mant |= 1;
        return normalize(r_sign, r_exp, r_mant, rm, pfflags);
    }

    static if (is (F_ULONG))
    {

        /* compute sqrt(a) with a = ah*2^F_SIZE+al and a < 2^(F_SIZE - 2)
       return true if not exact square. */
        static int sqrtrem_u(F_UINT *pr, F_UINT ah, F_UINT al)
        {
            F_ULONG a, u, s;
            int l, inexact;

            /* 2^l >= a */
            if (ah != 0) {
                l = 2 * F_SIZE - clz(ah - 1);
            } else {
                if (al == 0) {
                    *pr = 0;
                    return 0;
                }
                l = F_SIZE - clz(al - 1);
            }
            a = (cast(F_ULONG)ah << F_SIZE) | al;
            u = cast(F_ULONG)1 << ((l + 1) / 2);
            for (;;) {
                s = u;
                u = ((a / s) + s) / 2;
                if (u >= s)
                    break ;
            }
            inexact = (a - s * s) != 0;
            *pr = cast(F_UINT)s;
            return inexact;
        }

    }
    else
    {

        static int sqrtrem_u(F_UINT *pr, F_UINT a1, F_UINT a0)
        {
            int l, inexact;
            F_UINT u, s, r, q, sq0, sq1;

            /* 2^l >= a */
            if (a1 != 0) {
                l = 2 * F_SIZE - clz(a1 - 1);
            } else {
                if (a0 == 0) {
                    *pr = 0;
                    return 0;
                }
                l = F_SIZE - clz(a0 - 1);
            }
            u = cast(F_UINT)1 << ((l + 1) / 2);
            for (;;) {
                s = u;
                q = divrem_u(&r, a1, a0, s);
                u = (q + s) / 2;
                if (u >= s)
                    break ;
            }
            sq1 = mul_u(&sq0, s, s);
            inexact = (sq0 != a0 || sq1 != a1);
            *pr = s;
            return inexact;
        }
    }


    F_UINT sqrt(F_UINT a, RoundingMode rm,
    uint32_t *pfflags)
    {
        uint32_t a_sign;
        int32_t a_exp;
        F_UINT a_mant;

        a_sign = a >> (F_SIZE - 1);
        a_exp = (a >> MANT_SIZE) & EXP_MASK;
        a_mant = a & MANT_MASK;
        if (a_exp == EXP_MASK) {
            if (a_mant != 0) {
                if (issignan(a)) {
                    *pfflags |= FFLAG_INVALID_OP;
                }
                return F_QNAN;
            } else if (a_sign) {
                goto neg_error;
            } else {
                return a; /* +infinity */
            }
        }
        if (a_sign) {
            if (a_exp == 0 && a_mant == 0)
                return a; /* -zero */
            neg_error:
            *pfflags |= FFLAG_INVALID_OP;
            return F_QNAN;
        }
        if (a_exp == 0) {
            if (a_mant == 0)
                return pack(0, 0, 0); /* zero */
            a_mant = normalize_subnormal(&a_exp, a_mant);
        } else {
            a_mant |= cast(F_UINT)1 << MANT_SIZE;
        }
        a_exp -= EXP_MASK / 2;
        /* simpler to handle an even exponent */
        if (a_exp & 1) {
            a_exp--;
            a_mant <<= 1;
        }
        a_exp = (a_exp >> 1) + EXP_MASK / 2;
        a_mant <<= (F_SIZE - 4 - MANT_SIZE);
        if (sqrtrem_u(&a_mant, a_mant, 0))
            a_mant |= 1;
        return normalize(a_sign, a_exp, a_mant, rm, pfflags);
    }

    /* comparisons */

    F_UINT min(F_UINT a, F_UINT b, uint32_t *pfflags)
    {
        uint32_t a_sign, b_sign;

        if (isnan(a) || isnan(b)) {
            if (issignan(a) || issignan(b)) {
                *pfflags |= FFLAG_INVALID_OP;
                return F_QNAN;
            } else if (isnan(a)) {
                if (isnan(b))
                    return F_QNAN;
                else
                    return b;
            } else {
                return a;
            }
        }
        a_sign = a >> (F_SIZE - 1);
        b_sign = b >> (F_SIZE - 1);

        if (a_sign != b_sign) {
            if (a_sign)
                return a;
            else
                return b;
        } else {
            if ((a < b) ^ a_sign)
                return a;
            else
                return b;
        }
    }

    F_UINT max(F_UINT a, F_UINT b, uint32_t *pfflags)
    {
        uint32_t a_sign, b_sign;

        if (isnan(a) || isnan(b)) {
            if (issignan(a) || issignan(b)) {
                *pfflags |= FFLAG_INVALID_OP;
                return F_QNAN;
            } else if (isnan(a)) {
                if (isnan(b))
                    return F_QNAN;
                else
                    return b;
            } else {
                return a;
            }
        }
        a_sign = a >> (F_SIZE - 1);
        b_sign = b >> (F_SIZE - 1);

        if (a_sign != b_sign) {
            if (a_sign)
                return b;
            else
                return a;
        } else {
            if ((a < b) ^ a_sign)
                return b;
            else
                return a;
        }
    }

    int eq_quiet(F_UINT a, F_UINT b, uint32_t *pfflags)
    {
        if (isnan(a) || isnan(b)) {
            if (issignan(a) || issignan(b)) {
                *pfflags |= FFLAG_INVALID_OP;
            }
            return 0;
        }

        if (cast(F_UINT)((a | b) << 1) == 0)
            return 1; /* zero case */
        return (a == b);
    }

    int le(F_UINT a, F_UINT b, uint32_t *pfflags)
    {
        uint32_t a_sign, b_sign;

        if (isnan(a) || isnan(b)) {
            *pfflags |= FFLAG_INVALID_OP;
            return 0;
        }

        a_sign = a >> (F_SIZE - 1);
        b_sign = b >> (F_SIZE - 1);
        if (a_sign != b_sign) {
            return (a_sign || (cast(F_UINT)((a | b) << 1) == 0));
        } else {
            if (a_sign) {
                return (a >= b);
            } else {
                return (a <= b);
            }
        }
    }

    int lt(F_UINT a, F_UINT b, uint32_t *pfflags)
    {
        uint32_t a_sign, b_sign;

        if (isnan(a) || isnan(b)) {
            *pfflags |= FFLAG_INVALID_OP;
            return 0;
        }

        a_sign = a >> (F_SIZE - 1);
        b_sign = b >> (F_SIZE - 1);
        if (a_sign != b_sign) {
            return (a_sign && (cast(F_UINT)((a | b) << 1) != 0));
        } else {
            if (a_sign) {
                return (a > b);
            } else {
                return (a < b);
            }
        }
    }

    uint32_t fclass(F_UINT a)
    {
        uint32_t a_sign;
        int32_t a_exp;
        F_UINT a_mant;
        uint32_t ret;

        a_sign = a >> (F_SIZE - 1);
        a_exp = (a >> MANT_SIZE) & EXP_MASK;
        a_mant = a & MANT_MASK;
        if (a_exp == EXP_MASK) {
            if (a_mant != 0) {
                if (a_mant & QNAN_MASK)
                    ret = FCLASS_QNAN;
                else
                    ret = FCLASS_SNAN;
            } else {
                if (a_sign)
                    ret = FCLASS_NINF;
                else
                    ret = FCLASS_PINF;
            }
        } else if (a_exp == 0) {
            if (a_mant == 0) {
                if (a_sign)
                    ret = FCLASS_NZERO;
                else
                    ret = FCLASS_PZERO;
            } else {
                if (a_sign)
                    ret = FCLASS_NSUBNORMAL;
                else
                    ret = FCLASS_PSUBNORMAL;
            }
        } else {
            if (a_sign)
                ret = FCLASS_NNORMAL;
            else
                ret = FCLASS_PNORMAL;
        }
        return ret;
    }

    /* conversions between floats */

    static if (F_SIZE >= 64)
    {
        F_UINT from_float32(uint32_t a, uint32_t *pfflags)
        {
            uint32_t a_sign;
            int32_t a_exp;
            F_UINT a_mant;

            a_mant = softfp!32.unpack(&a_sign, &a_exp, a);
            if (a_exp == 0xff) {
                if (a_mant != 0) {
                    /* NaN */
                    if (softfp!32.issignan(a)) {
                        *pfflags |= FFLAG_INVALID_OP;
                    }
                    return F_QNAN;
                } else {
                    /* infinity */
                    return pack(a_sign, EXP_MASK, 0);
                }
            }
            if (a_exp == 0) {
                if (a_mant == 0)
                    return pack(a_sign, 0, 0); /* zero */
                a_mant = softfp!32.normalize_subnormal(&a_exp, cast(uint)a_mant);
            }
            /* convert the exponent value */
            a_exp = a_exp - 0x7f + (EXP_MASK / 2);
            /* shift the mantissa */
            a_mant <<= (MANT_SIZE - 23);
            /* We assume the target float is large enough to that no
           normalization is necessary */
            return pack(a_sign, a_exp, a_mant);
        }

        uint32_t to_float32(F_UINT a, RoundingMode rm, uint32_t *pfflags)
        {
            uint32_t a_sign;
            int32_t a_exp;
            F_UINT a_mant;

            a_mant = unpack(&a_sign, &a_exp, a);
            if (a_exp == EXP_MASK) {
                if (a_mant != 0) {
                    /* NaN */
                    if (issignan(a)) {
                        *pfflags |= FFLAG_INVALID_OP;
                    }
                    return softfp!32.F_QNAN;
                } else {
                    /* infinity */
                    return softfp!32.pack(a_sign, 0xff, 0);
                }
            }
            if (a_exp == 0) {
                if (a_mant == 0)
                    return softfp!32.pack(a_sign, 0, 0); /* zero */
                normalize_subnormal(&a_exp, a_mant);
            } else {
                a_mant |= cast(F_UINT)1 << MANT_SIZE;
            }
            /* convert the exponent value */
            a_exp = a_exp - (EXP_MASK / 2) + 0x7f;
            /* shift the mantissa */
            a_mant = rshift_rnd(a_mant, MANT_SIZE - (32 - 2));
            return softfp!32.normalize(a_sign, a_exp, cast(uint)a_mant, rm, pfflags);
        }
    }



    static if (F_SIZE >= 128)
    {
        F_UINT from_float64(uint64_t a, uint32_t *pfflags)
        {
            uint32_t a_sign;
            int32_t a_exp;
            F_UINT a_mant;

            a_mant = softfp!64.unpack(&a_sign, &a_exp, a);

            if (a_exp == 0x7ff) {
                if (a_mant != 0) {
                    /* NaN */
                    if (softfp!64.issignan(a)) {
                        *pfflags |= FFLAG_INVALID_OP;
                    }
                    return F_QNAN;
                } else {
                    /* infinity */
                    return pack(a_sign, EXP_MASK, 0);
                }
            }
            if (a_exp == 0) {
                if (a_mant == 0)
                    return pack(a_sign, 0, 0); /* zero */
                a_mant = softfp!64.normalize_subnormal(&a_exp, a_mant);
            }
            /* convert the exponent value */
            a_exp = a_exp - 0x3ff + (EXP_MASK / 2);
            /* shift the mantissa */
            a_mant <<= (MANT_SIZE - 52);
            return pack(a_sign, a_exp, a_mant);
        }

        uint64_t to_float64(F_UINT a, RoundingMode rm, uint32_t *pfflags)
        {
            uint32_t a_sign;
            int32_t a_exp;
            F_UINT a_mant;

            a_mant = unpack(&a_sign, &a_exp, a);
            if (a_exp == EXP_MASK) {
                if (a_mant != 0) {
                    /* NaN */
                    if (issignan(a)) {
                        *pfflags |= FFLAG_INVALID_OP;
                    }
                    return softfp!64.F_QNAN;
                } else {
                    /* infinity */
                    return softfp!64.pack(a_sign, 0x7ff, 0);
                }
            }
            if (a_exp == 0) 
            {
                if (a_mant == 0)
                    return pack64(a_sign, 0, 0); /* zero */
                normalize_subnormal(&a_exp, a_mant);
            } 
            else 
            {
                a_mant |= cast(F_UINT)1 << MANT_SIZE;
            }
            /* convert the exponent value */
            a_exp = a_exp - (EXP_MASK / 2) + 0x3ff;
            /* shift the mantissa */
            a_mant = rshift_rnd(a_mant, MANT_SIZE - (64 - 2));
            return softfp!64.normalize(a_sign, a_exp, a_mant, rm, pfflags);
        }
    }

    //import softfp_template_icvt;
    //#define ICVT_SIZE 32
    //mixin icvt!32;
    //#define ICVT_SIZE 64
    //mixin icvt!64;


    //static if (HAVE_INT128)
    //{
        //#define ICVT_SIZE 128
    //    mixin icvt!128;
    //}


/*
//#define F_SIZE 32
mixin softfp!(32);

//#define F_SIZE 64
mixin softfp!(64);

static if (HAVE_INT128)
{
    //#define F_SIZE 128
    mixin softfp!(128);
}

*/


	// /* conversions between float and integers */
	// static ICVT_INT glue(glue(glue(internal_cvt_sf, F_SIZE), _i), ICVT_SIZE)(F_UINT a, RoundingModeEnum rm,
	// 																		 uint32_t *pfflags, BOOL is_unsigned)

    /* conversions between float and integers */
    static ICVT_INT internal_cvt_to_signed(ICVT_INT, F_UINT)(F_UINT a, RoundingMode rm, uint32_t *pfflags, bool is_unsigned)
    {
		alias ICVT_UINT = Unsigned!ICVT_INT;
		enum ICVT_SIZE = ICVT_UINT.sizeof * 8;
        uint32_t a_sign, addend, rnd_bits;
        int32_t a_exp;
        F_UINT a_mant;
        ICVT_UINT r, r_max;

        a_sign = a >> (F_SIZE - 1);
        a_exp = (a >> MANT_SIZE) & EXP_MASK;
        a_mant = a & MANT_MASK;
        if (a_exp == EXP_MASK && a_mant != 0)
            a_sign = 0; /* NaN is like +infinity */
        if (a_exp == 0) {
            a_exp = 1;
        } else {
            a_mant |= cast(F_UINT)1 << MANT_SIZE;
        }
        a_mant <<= RND_SIZE;
        a_exp = a_exp - (EXP_MASK / 2) - MANT_SIZE;

        if (is_unsigned)
            r_max = cast(ICVT_UINT)a_sign - 1;
        else
            r_max = (cast(ICVT_UINT)1 << (ICVT_SIZE - 1)) - cast(ICVT_UINT)(a_sign ^ 1);
        if (a_exp >= 0) {
            if (a_exp <= (ICVT_SIZE - 1 - MANT_SIZE)) {
                r = cast(ICVT_UINT)(a_mant >> RND_SIZE) << a_exp;
                if (r > r_max)
                    goto overflow;
            } else {
            overflow:
                *pfflags |= FFLAG_INVALID_OP;
                return r_max;
            }
        } else {
            a_mant = rshift_rnd(a_mant, -a_exp);

            switch(rm) {
            case RoundingMode.RNE:
            case RoundingMode.RMM:
                addend = (1 << (RND_SIZE - 1));
                break;
            case RoundingMode.RTZ:
                addend = 0;
                break;
            default:
            case RoundingMode.RDN:
            case RoundingMode.RUP:
                if (a_sign ^ (rm & 1))
                    addend = (1 << RND_SIZE) - 1;
                else
                    addend = 0;
                break;
            }

            rnd_bits = a_mant & ((1 << RND_SIZE ) - 1);
            a_mant = (a_mant + addend) >> RND_SIZE;
            /* half way: select even result */
            if (rm == RoundingMode.RNE && rnd_bits == (1 << (RND_SIZE - 1)))
                a_mant &= ~1;
            if (a_mant > r_max)
                goto overflow;
            r = cast(ICVT_UINT)a_mant;
            if (rnd_bits != 0)
                *pfflags |= FFLAG_INEXACT;
        }
        if (a_sign)
            r = -r;
        return r;
    }

    T to_integer(T)(F_UINT a, RoundingMode rm, uint32_t *pfflags) if (!isUnsigned!T)
    {
        return internal_cvt_to_signed!(T,F_UINT)(a, rm, pfflags, false);
    }

    T to_integer(T)(F_UINT a, RoundingMode rm, uint32_t *pfflags) if (isUnsigned!T)
    {
        return internal_cvt_to_signed!(T,F_UINT)(a, rm, pfflags, true);
    }

    /* conversions between float and integers */
    static F_UINT internal_cvt_from_signed(ICVT_INT, F_UINT)(ICVT_INT a, RoundingMode rm, uint32_t *pfflags, bool is_unsigned)
    {
		alias ICVT_UINT = Unsigned!ICVT_INT;
		enum ICVT_SIZE = ICVT_UINT.sizeof * 8;
        uint32_t a_sign;
        int32_t a_exp;
        F_UINT a_mant;
        ICVT_UINT r, mask;
        int l;

        if (!is_unsigned && a < 0) {
            a_sign = 1;
            r = -cast(ICVT_UINT)a;
        } else {
            a_sign = 0;
            r = a;
        }
        a_exp = (EXP_MASK / 2) + F_SIZE - 2;
        /* need to reduce range before generic float normalization */
        l = cast(int)(ICVT_SIZE - clz!ICVT_UINT(r) - (F_SIZE - 1));
        if (l > 0)
        {
            mask = r & ((cast(ICVT_UINT)1 << l) - 1);
            r = (r >> l) | ((r & mask) != 0);
            a_exp += l;
        }
        a_mant = cast(F_UINT)r;
        return normalize(a_sign, a_exp, a_mant, rm, pfflags);
    }

    F_UINT to_float(T)(T a, RoundingMode rm, uint32_t *pfflags) if (!isUnsigned!T)
    {
        return internal_cvt_from_signed!(T, F_UINT)(a, rm, pfflags, false);
    }

    F_UINT to_float(T)(T  a, RoundingMode rm, uint32_t *pfflags) if (isUnsigned!T)
    {
        return internal_cvt_from_signed!(T, F_UINT)(a, rm, pfflags, true);
    }

}
