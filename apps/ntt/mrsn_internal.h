#ifndef MRSN_INTERNAL_H
#define MRSN_INTERNAL_H

/*

  Modular operations with respect to Mersenne prime p = 2^31-1

  All operations are done on unsigned integers with 32 bits,

  with the exception of:

  - init_red which takes an positive or negative 32bit integer and
    returns its remainder mod p in [0:p]
  
  - red2 which takes a remainder mod p in [0:p-1] and returns a signed
    remainder in [-(p-1)/2 : (p-1)/2]

   Note that we accept as input and output a double zero, where 0 and
   p=0x7FFFFFFF are both 0 mod p. Function red1 is used to correct for
   the double zero.

   
*/

static inline __attribute__((always_inline))
uint32_t rot15_alt(uint32_t x)
{
  //rotate left 15 bits for a number of 31 bits. Works only if MSB = 0!
    return ((x << 15) | (x >> 16)) & 0x7FFFFFFF;
}


static inline __attribute__((always_inline))
uint32_t rot15(uint32_t x)
{
  //rotate left 15 bits for a number of 31 bits. Works only if MSB = 0!
  return (((uint32_t) ((uint16_t) x)) << 15) | (x >> 16);
}

static inline __attribute__((always_inline))
uint32_t rot24(uint32_t x)
{
  //rotate left 24 bits for a number of 31 bits. Works only if MSB = 0!
    return ((x << 24) | (x >> 7)) & 0x7FFFFFFF;
}



static inline __attribute__((always_inline))
uint32_t add(uint32_t x, uint32_t y)
{
  //Modular addition a + b mod(p)
  uint32_t z;

  z = x + y;

  return (z >> 31) + (z &  0x7FFFFFFF);
  
}

static inline __attribute__((always_inline))
uint32_t sub(uint32_t x, uint32_t y)
{

  //Modular subtraction a - b mod(p).  Uses the fact that -b  = ~b mod(p)
  uint32_t y_inv, z;

  y_inv = (~y) & 0x7FFFFFFF;
  
  z = x + y_inv;

  return (z >> 31) + (z &  0x7FFFFFFF);
  
}


static inline __attribute__((always_inline))
uint32_t prod(uint32_t x, uint32_t y)
{
  //Modular product a * b mod(p).

  //Uses a widening product 32b x 32b = 64b and than does a double
  //reduction using x*2^31 = x mod(p).
  
  uint64_t z1, z2;

  z1 = (((uint64_t) x) * ((uint64_t) y));

  z2 = (uint32_t) ( (z1 >> 31) +  (z1  & 0x7FFFFFFF)); 

  return (z2 >> 31) + (z2 &  0x7FFFFFFF);
}

static inline __attribute__((always_inline))
uint32_t red1(uint32_t x)
{
  // Reduces to remainder in [0:p-1]

  // Actually there is a single correction necessary:
  // for double zero where p = 0x7FFFFFFF should be 0 mod(p)

  uint32_t z1, z2;

  z1 = x + 1u;

  z2 = z1 & 0x7FFFFFFF;
  
  if ( z1>>31 == 0)
    return x;
  else
    return z2;
}

static inline __attribute__((always_inline))
int32_t red2(uint32_t x)
{

  //Reduces to remainders in [-(p-1)/2 : (p-1)/2].

  //Works also for double zero.

  int32_t z1, z2;

  z1 = (int32_t) x;

  z2 = ((int32_t) x -  0x7FFFFFFF);
  
  if ( (x & 0x40000000) == 0)
    return z1;
  else
    return z2;
}



static inline __attribute__((always_inline))
int32_t barrett1(int32_t x, int32_t q, int32_t Rq)
{
  int32_t tmp;
  
  tmp = (int32_t) (( ( (int64_t) (x >> 14) ) * ( (int64_t) Rq ) ) >> 19);

  return x - tmp * q;

  
}


static inline __attribute__((always_inline))
int32_t barrett2(int32_t x, int32_t q, int32_t Rq)
{
  int64_t tmp1;

  int32_t tmp;

  int64_t half = 0x0000000100000000;

  tmp1 =  ((int64_t) x ) * ( (int64_t) Rq ) + half;

  
  tmp =  (int32_t) (tmp1 >> 33);

  
  return x - tmp * q;

  
}

#endif
