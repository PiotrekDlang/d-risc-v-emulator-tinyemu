/*
 * RISCV emulator
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
module riscv_cpu_fp_template;

import core.stdc.inttypes;

template cpu_fp(alias F_SIZE, alias FLEN)
{

    	/* FLEN is the floating point register width */
	static if (FLEN == 32)
	{
		alias fp_uint = uint32_t;
		enum F32_HIGH = 0;
	}
	else static if (FLEN == 64)
	{
		alias fp_uint = uint64_t;
		enum F32_HIGH = (cast(fp_uint)-1 << 32);
		enum F64_HIGH = 0;

	}
	else static if (FLEN == 128)
	{
		alias fp_uint = uint128_t;
		enum F32_HIGH = ((fp_uint)-1 << 32);
		enum F64_HIGH = ((fp_uint)-1 << 64);

	}
	else
	{
		static assert (0, "Unsupported FLEN" );
	}
	
    static if (F_SIZE == 32)
    {
        enum OPID = 0;
        enum F_HIGH = F32_HIGH;
        alias F_UINT = uint32_t;
    }
    else static if (F_SIZE == 64)
    {
        enum OPID = 1;
        enum F_HIGH = F64_HIGH;
        alias F_UINT = uint64_t;
    }
    else static if (F_SIZE == 128)
    {
        enum OPID = 3;
        enum F_HIGH = 0;
        alias F_UINT = uint128_t;
    }
    else
    {
        static assert ( "Unsupported F_SIZE");
    }


    import std.array :replace;
	enum cpu_fp = code
					.replace("F_SIZE", 		F_SIZE.stringof)
					.replace("OPID", 		OPID.stringof)
					.replace("F_HIGH", 		F_HIGH.stringof)
					.replace("FSIGN_MASK", 	"FSIGN_MASK" ~ F_SIZE.stringof);
					
    enum code = q{
                case (0x00 << 2) | OPID:
                    rm = get_insn_rm(s, cast(RoundingMode)rm);
                    if (rm < 0)
                        goto illegal_insn;
                    s.fp_reg[rd] = softfp!F_SIZE.add(	cast(uintF_SIZE_t)s.fp_reg[rs1],
													cast(uintF_SIZE_t)s.fp_reg[rs2],
													cast(RoundingMode)rm,
													&s.fflags )
										| F_HIGH;

                    s.fs = 3;
                    break;
                case (0x01 << 2) | OPID:
                    rm = get_insn_rm(s, cast(RoundingMode)rm);
                    if (rm < 0)
                        goto illegal_insn;
                    s.fp_reg[rd] = softfp!F_SIZE.sub(	cast(uintF_SIZE_t)s.fp_reg[rs1],
													cast(uintF_SIZE_t)s.fp_reg[rs2],
													cast(RoundingMode)rm,
													&s.fflags)
										| F_HIGH;
                    s.fs = 3;
                    break;
                case (0x02 << 2) | OPID:
                    rm = get_insn_rm(s, cast(RoundingMode)rm);
                    if (rm < 0)
                        goto illegal_insn;
                    s.fp_reg[rd] = softfp!F_SIZE.mul(	cast(uintF_SIZE_t)s.fp_reg[rs1],
													cast(uintF_SIZE_t)s.fp_reg[rs2],
													cast(RoundingMode)rm,
													&s.fflags)
										| F_HIGH;
                    s.fs = 3;
                    break;
                case (0x03 << 2) | OPID:
                    rm = get_insn_rm(s, cast(RoundingMode)rm);
                    if (rm < 0)
                        goto illegal_insn;
                    s.fp_reg[rd] = softfp!F_SIZE.div(	cast(uintF_SIZE_t)s.fp_reg[rs1],
													cast(uintF_SIZE_t)s.fp_reg[rs2],
													cast(RoundingMode)rm,
													&s.fflags)
										| F_HIGH;
                    s.fs = 3;
                    break;
                case (0x0b << 2) | OPID:
                    rm = get_insn_rm(s, cast(RoundingMode)rm);
                    if (rm < 0 || rs2 != 0)
                        goto illegal_insn;
                    s.fp_reg[rd] = softfp!F_SIZE.sqrt(	cast(uintF_SIZE_t)s.fp_reg[rs1],
													cast(RoundingMode)rm,
													&s.fflags)
										| F_HIGH;
                    s.fs = 3;
                    break;
                case (0x04 << 2) | OPID:
                    switch(rm) {
                    case 0: /* fsgnj */
                        s.fp_reg[rd] = (s.fp_reg[rs1] & ~FSIGN_MASK) | (s.fp_reg[rs2] & FSIGN_MASK);
                        break;
                    case 1: /* fsgnjn */
                        s.fp_reg[rd] = 	(s.fp_reg[rs1] & ~FSIGN_MASK) | ((s.fp_reg[rs2] & FSIGN_MASK) ^ FSIGN_MASK);
                        break;
                    case 2: /* fsgnjx */
                        s.fp_reg[rd] = s.fp_reg[rs1] ^
                            (s.fp_reg[rs2] & FSIGN_MASK);
                        break;
                    default:
                        goto illegal_insn;
                    }
                    s.fs = 3;
                    break;
                case (0x05 << 2) | OPID:
                    switch(rm) {
                    case 0: /* fmin */
                        s.fp_reg[rd] = softfp!F_SIZE.min(	cast(uintF_SIZE_t)s.fp_reg[rs1],
														cast(uintF_SIZE_t)s.fp_reg[rs2],
														&s.fflags)
												| F_HIGH;
                        break;
                    case 1: /* fmax */
                        s.fp_reg[rd] = softfp!F_SIZE.max(	cast(uintF_SIZE_t)s.fp_reg[rs1],
														cast(uintF_SIZE_t)s.fp_reg[rs2],
														&s.fflags)
												| F_HIGH;
                        break;
                    default:
                        goto illegal_insn;
                    }
                    s.fs = 3;
                    break;
                case (0x18 << 2) | OPID:
                    rm = get_insn_rm(s, cast(RoundingMode)rm);
                    if (rm < 0)
                        goto illegal_insn;
                    switch(rs2) {
                    case 0: /* fcvt.w.[sdq] */
                        // TODO what is the purpose of casting the "val" value?
                        // val = (int32_t)glue(glue(cvt_sf, F_SIZE), _i32)(s->fp_reg[rs1], cast(RoundingMode)rm,
                        // val = (int32_t)cvt_sf32_i32(s->fp_reg[rs1], cast(RoundingMode)rm, &s->fflags);
						// val = (int32_t)softfp.to_int!int32_t(cast(sfloat64)s->fp_reg[rs1], cast(RoundingMode)rm, &s->fflags);
                        val = cast(int32_t)softfp!F_SIZE.to_integer!int32_t(cast(uintF_SIZE_t)s.fp_reg[rs1], cast(RoundingMode)rm, &s.fflags);
                        break;
                    case 1: /* fcvt.wu.[sdq] */
                        val = cast(int32_t)softfp!F_SIZE.to_integer!uint32_t(cast(uintF_SIZE_t)s.fp_reg[rs1], cast(RoundingMode)rm, &s.fflags);
                        break;
static if (XLEN >= 64)
{

                    case 2: /* fcvt.l.[sdq] */
                        val = cast(int64_t)softfp!F_SIZE.to_integer!int64_t(cast(uintF_SIZE_t)s.fp_reg[rs1], cast(RoundingMode)rm, &s.fflags);
                        break;
                    case 3: /* fcvt.lu.[sdq] */
                        val = cast(int64_t)softfp!F_SIZE.to_integer!uint64_t(cast(uintF_SIZE_t)s.fp_reg[rs1], cast(RoundingMode)rm, &s.fflags);
                        break;
}
static if (XLEN >= 128)
{
                    /* XXX: the index is not defined in the spec */
                    case 4: /* fcvt.t.[sdq] */
                        val = softfp!F_SIZE.to_integer!int128_t(s.fp_reg[rs1], cast(RoundingMode)rm, &s.fflags);
                        break;
                    case 5: /* fcvt.tu.[sdq] */
                        val = softfp!F_SIZE.to_integer!uint128_t(s.fp_reg[rs1], cast(RoundingMode)rm, &s.fflags);
                        break;
}
                    default:
                        goto illegal_insn;
                    }
                    if (rd != 0)
                    {
                        s.reg[rd] = val;
					}
                    break;
                case (0x14 << 2) | OPID:
                    switch(rm) {
                    case 0: /* fle */
                        val = softfp!F_SIZE.le(cast(uintF_SIZE_t)s.fp_reg[rs1],
											cast(uintF_SIZE_t)s.fp_reg[rs2],
											&s.fflags);
                        break;
                    case 1: /* flt */
                        val = softfp!F_SIZE.lt(cast(uintF_SIZE_t)s.fp_reg[rs1],
											cast(uintF_SIZE_t)s.fp_reg[rs2],
											&s.fflags);
                        break;
                    case 2: /* feq */
                        val = softfp!F_SIZE.eq_quiet(	cast(uintF_SIZE_t)s.fp_reg[rs1],
													cast(uintF_SIZE_t)s.fp_reg[rs2],
													&s.fflags);
                        break;
                    default:
                        goto illegal_insn;
                    }
                    if (rd != 0)
                    {
                        s.reg[rd] = val;
					}
                    break;
                case (0x1a << 2) | OPID:
                    rm = get_insn_rm(s, cast(RoundingMode)rm);
                    if (rm < 0)
                        goto illegal_insn;
                    switch(rs2) {
                    case 0: /* fcvt.[sdq].w */
						/// WIP FIXME
						//case 0: /* fcvt.[sdq].w */
						//	s->fp_reg[rd] = glue(cvt_i32_sf, F_SIZE)(s->reg[rs1], cast(RoundingMode)rm,
                        //                               &s->fflags) | F_HIGH;
						
                        s.fp_reg[rd] = softfp!F_SIZE.to_float!int32_t(cast(int32_t)s.reg[rs1], cast(RoundingMode)rm,
                                                           &s.fflags) | F_HIGH;
                        //s.fp_reg[rd] = softfp!to_float!fp_uint(s.reg[rs1], cast(RoundingMode)rm,
                        //                                 &s.fflags) | F_HIGH;
                        
                        break;
                    case 1: /* fcvt.[sdq].wu */
                        s.fp_reg[rd] = softfp!F_SIZE.to_float!uint32_t(cast(int32_t)s.reg[rs1], cast(RoundingMode)rm,
                                                           &s.fflags) | F_HIGH;
                        break;
static if (XLEN >= 64)
{
                    case 2: /* fcvt.[sdq].l */
                        s.fp_reg[rd] = softfp!F_SIZE.to_float!int64_t(s.reg[rs1], cast(RoundingMode)rm,
                                                           &s.fflags) | F_HIGH;
                        break;
                    case 3: /* fcvt.[sdq].lu */
                        s.fp_reg[rd] = softfp!F_SIZE.to_float!uint64_t(s.reg[rs1], cast(RoundingMode)rm,
                                                                &s.fflags) | F_HIGH;
                        break;
}
static if (XLEN >= 128)
{
                    /* XXX: the index is not defined in the spec */
                    case 4: /* fcvt.[sdq].t */
                        s.fp_reg[rd] = softfp!F_SIZE.to_float!int128_t(s.reg[rs1], cast(RoundingMode)rm,
                                                           &s.fflags) | F_HIGH;
                        break;
                    case 5: /* fcvt.[sdq].tu */
                        s.fp_reg[rd] = softfp!F_SIZE.to_float!int128_t(s.reg[rs1], cast(RoundingMode)rm,
                                                                &s.fflags) | F_HIGH;
                        break;
}
                    default:
                        goto illegal_insn;
                    }
                    s.fs = 3;
                    break;

                case (0x08 << 2) | OPID:
                    rm = get_insn_rm(s, cast(RoundingMode)rm);
                    if (rm < 0)
                        goto illegal_insn;
                    switch(rs2) {
static if (F_SIZE == 32 && FLEN >= 64)
{
                    case 1: /* cvt.s.d */
                        s.fp_reg[rd] = softfp!64.to_float32(s.fp_reg[rs1], cast(RoundingMode)rm, &s.fflags) | F32_HIGH;
                        break;
 static if (FLEN >= 128)
 {
                    case 3: /* cvt.s.q */
                        s.fp_reg[rd] = softfp!128.to_float32(s.fp_reg[rs1], cast(RoundingMode)rm, &s.fflags) | F32_HIGH;
                        break;
 }
} /* F_SIZE == 32 */
static if (F_SIZE == 64)
{
                    case 0: /* cvt.d.s */
                        s.fp_reg[rd] = softfp!64.from_float32(cast(sfloat32)s.fp_reg[rs1], &s.fflags) | F64_HIGH;
                        break;
 static if (FLEN >= 128)
 {
                    case 1: /* cvt.d.q */
                        s.fp_reg[rd] = softfp!128.to!uint64_t(s.fp_reg[rs1], cast(RoundingMode)rm, &s.fflags) | F64_HIGH;
                        break;
 }
} /* F_SIZE == 64 */
static if (F_SIZE == 128)
{
                    case 0: /* cvt.q.s */
                        s.fp_reg[rd] =  softfp!128.from_float32(s.fp_reg[rs1], &s.fflags);
                        break;
                    case 1: /* cvt.q.d */
                        s.fp_reg[rd] = softfp!128.from_float64(s.fp_reg[rs1], &s.fflags);
                        break;
} /* F_SIZE == 128 */

                    default:
                        goto illegal_insn;
                    }
                    s.fs = 3;
                    break;

                case (0x1c << 2) | OPID:
                    if (rs2 != 0)
                        goto illegal_insn;
                    switch(rm) {
static if (F_SIZE <= XLEN)
{
                    case 0: /* fmv.x.s */
 static if (F_SIZE == 32)
 {
                        val = cast(int32_t)s.fp_reg[rs1];
 }
 else static if (F_SIZE == 64)
 {
                        val = cast(int64_t)s.fp_reg[rs1];
 }
 else
 {
                        val = cast(int128_t)s.fp_reg[rs1];
 }
                        break;
} /* F_SIZE <= XLEN */
                    case 1: /* fclass */
                        val = softfp!F_SIZE.fclass(cast(uintF_SIZE_t)s.fp_reg[rs1]);
                        break;
                    default:
                        goto illegal_insn;
                    }
                    if (rd != 0)
                        s.reg[rd] = val;
                    break;

static if (F_SIZE <= XLEN)
{
                case (0x1e << 2) | OPID: /* fmv.s.x */
                    if (rs2 != 0 || rm != 0)
                        goto illegal_insn;
  static if (F_SIZE == 32)
  {
                    s.fp_reg[rd] = cast(int32_t)s.reg[rs1];
  }
  else static if (F_SIZE == 64)
  {
                    s.fp_reg[rd] = cast(int64_t)s.reg[rs1];
  }
  else
  {
                    s.fp_reg[rd] = cast(int128_t)s.reg[rs1];
  }
                    s.fs = 3;
                    break;
} /* F_SIZE <= XLEN */
    }; /* end of string enum */
}
