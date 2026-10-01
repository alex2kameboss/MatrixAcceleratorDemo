#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include "mrsn_internal.h"

/* Root of order 512: om512 = 430821412 + i 1152650470 */

/* om512.^[1:63] in natural order and interleaved format as re,im, re,im, etc.*/

uint32_t omegas512[126] =
  {
    430821412u,  1152650470u, 236104903u,  1577470940u, 485600145u,  224958826u,  206059115u,  1935040570u,
    660017901u,  1340846354u, 1896945393u, 2098580229u, 735494074u,  1494204761u, 1641940819u, 26164677u,
    1777644782u, 1383853684u, 1093071961u, 648593218u,  1920912571u, 914097328u,  1742797653u, 2140339328u,
    1371669334u, 2103108137u, 1260750973u, 1362440376u, 1336950523u, 839591040u,  1241207368u, 1179735656u,
    1202912605u, 1980032781u, 1921627098u, 1668363411u, 165851886u,  1674906685u, 228509164u,  14530030u,
    1792244284u, 36557796u,   1014093253u, 2137011181u, 252929270u,  1353673049u, 194696271u,  567259857u,
    853979252u,  1113159341u, 1563928157u, 849605071u,  472916039u,  952794586u,  1309288441u, 373229752u,
    528066207u,  951582730u,  141956360u,  1977033713u, 605970061u,  1530121874u, 1556715293u, 978592373u,
    378535762u,  1207781610u, 477953613u,  2022380190u, 1398069297u, 1397384897u, 408478793u,  262191051u,
    1326503162u, 1362518885u, 1276547035u, 1514613395u, 328267072u,  484667533u,  1133522282u, 280947147u,
    1730666434u, 2110668387u, 81378258u,   1357626641u, 655387905u,  1395419301u, 1038945916u, 134155457u,
    1603661239u, 1398285837u, 1949783546u, 1067683608u, 1916124599u, 187158958u,  1415090252u, 2112881577u,
    834535867u,  222141861u,  1553669210u, 736262640u,  1925205788u, 278287463u,  2079025011u, 2137679949u,
    1756768506u, 1678097410u, 1506666447u, 445356670u,  1370602608u, 1664948088u, 579625837u,  1690787918u,
    1082787046u, 2133873350u, 1895558694u, 636875771u,  1644164930u, 820860779u,  1263730590u, 1796741361u,
    578660954u,  152276873u,  2085743640u, 812986380u,  1854234209u, 1637799161u
  };

/* Root of order 128: om128 = 206059115 + i 1935040570 */

/* om128.^[0:63] in bitreversed order and interleaved format as re, im, re, im, etc.*/

uint32_t omegas128[128] =
  {
    1u,          0u,          0u,          1u,          32768u,      32768u,      2147450879u, 32768u,
    1556715293u, 978592373u,  1168891274u, 1556715293u, 978592373u,  1556715293u, 590768354u,  978592373u,
    1241207368u, 1179735656u, 967747991u,  1241207368u, 2112881577u, 1415090252u, 732393395u,  2112881577u,
    1415090252u, 2112881577u, 34602070u,   1415090252u, 1179735656u, 1241207368u, 906276279u,  1179735656u,
    1641940819u, 26164677u,   2121318970u, 1641940819u, 1690787918u, 579625837u,  1567857810u, 1690787918u,
    1133522282u, 280947147u,  1866536500u, 1133522282u, 567259857u,  194696271u,  1952787376u, 567259857u,
    194696271u,  567259857u,  1580223790u, 194696271u,  280947147u,  1133522282u, 1013961365u, 280947147u,
    579625837u,  1690787918u, 456695729u,  579625837u,  26164677u,   1641940819u, 505542828u,  26164677u,
    206059115u,  1935040570u, 212443077u,  206059115u,  1796741361u, 1263730590u, 883753057u,  1796741361u,
    408478793u,  262191051u,  1885292596u, 408478793u,  373229752u,  1309288441u, 838195206u,  373229752u,
    228509164u,  14530030u,   2132953617u, 228509164u,  134155457u,  1038945916u, 1108537731u, 134155457u,
    2079025011u, 2137679949u, 9803698u,    2079025011u, 2140339328u, 1742797653u, 404685994u,  2140339328u,
    1742797653u, 2140339328u, 7144319u,    1742797653u, 2137679949u, 2079025011u, 68458636u,   2137679949u,
    1038945916u, 134155457u,  2013328190u, 1038945916u, 14530030u,   228509164u,  1918974483u, 14530030u,
    1309288441u, 373229752u,  1774253895u, 1309288441u, 262191051u,  408478793u,  1739004854u, 262191051u,
    1263730590u, 1796741361u, 350742286u,  1263730590u, 1935040570u, 206059115u,  1941424532u, 1935040570u
};


/******************************************************************************
* Name: mrsn_ntt_256
*
* Description: In-place, decimation-in-frequency number theoretic negperiodic
*              transform (NTT) in Z_p with p the Mersenne prime 2^31-1.
*
*              Input in natural order.
*              Output in bitreversed order.
*
*              Note that the output is represented as 128 "complex" numbers with
*              interleaved real and imaginary parts (re im re im re im ...)
*
*              For a "real" input of length N, the negperiodic complex
*              NTT of length N has conjugate symmetry, so that only N/2
*              values need to be calculated.
*
*
* Arguments: uint32_t a[256]: pointer to input/ouput vector of elements of Z_p
*
******************************************************************************/

void mrsn_ntt_256(uint32_t a[256])
{

  uint32_t re0, im0, re1, im1, t0, t1, t2, t3, om_re, om_im, t1_re, t1_im, t2_re, t2_im;

  int len, blocks, len2, len3, len4, ind, ii, k, k1, k2;

  
  /* First pass through the array
       
     1. Form complex numbers,  2n = 256, n = 128
    
     (x^2n + 1)_r => (x^n - i)_c and (x^n + i)_c.

     Note: x^n + i is the conjugate of x^n - i and can be neglected

     c[0:127] =  a_[0:127] + i a_[128:255]

     2. Twist coefficients

                  omega_4n
     (x^n - i)_c ==========>  (x^n - 1)_c

     Next stages will do a complex NTT for (x^128-1)_c

     
     Twisting means to multiply c_[0:127] by omega_512.^[0:127].

     This multiplication can be combined with stage1 that uses the
     simplest butterfly +/-

     Stage 1
         
     (x^128-1) ->  (x^64 - 1) and (x_64 + 1)
  */


  /* Multiplication by 1 */
  re0 = a[0   ];
  im0 = a[128 ];


  /* Multiplication by sqrt(i) = (1+i)*2^15 */
  re1 = a[64  ];
  im1 = a[192 ];

  t1_re = rot15(re1);
  t1_im = rot15(im1);

  
  re1 = sub(t1_re, t1_im);
  im1 = add(t1_re, t1_im);

  //Butterfly +/
  a[ 0]  =  add(re0, re1);
  a[64]  =  add(im0, im1);
  
  a[128]  =  sub(re0, re1);
  a[192]  =  sub(im0, im1);

  
  k1 = 0;
  k2 = 124;
  
  for (int i = 1; i < 64; i++)
    {
      re0 = a[0   + i];
      im0 = a[128 + i];

      om_re = omegas512[k1];
      om_im = omegas512[k1+1];

      k1 = k1 + 2;

      t0 = prod(re0,om_re);
      t1 = prod(im0,om_im);

      t2 = prod(re0,om_im);
      t3 = prod(im0,om_re);

      re0 = sub(t0,t1);
      im0 = add(t2,t3);

      re1 = a[64  + i];
      im1 = a[192 + i];
      
      /*
	Using symmetry (c,s) -> (s,c) around 45 degrees:
	cos(45 + x) = sin(45 - x)
	sin(45 + x) = cos(45 - x)

	This works also for complex roots in modular arithmetic
      */

      om_im = omegas512[k2]; 
      om_re = omegas512[k2+1]; 

      k2 = k2 - 2;
      
      t0 = prod(re1,om_re);
      t1 = prod(im1,om_im);

      t2 = prod(re1,om_im);
      t3 = prod(im1,om_re);

      re1 = sub(t0,t1);
      im1 = add(t2,t3);
      
      a[ 0  + i]  =  add(re0, re1);
      a[64  + i]  =  add(im0, im1);
      
      a[128 + i]  =  sub(re0, re1);
      a[192 + i]  =  sub(im0, im1);
    }

  /*
    Stage 2 - done separately as this requires butterfly +/- i and no
    multiplication
    
    (x^64 - 1) -> (x^32 - 1) and (x_32 + 1)

    (x_64 + 1) -> (x^32 - i) and (x_32 + i)
  */
  	
  for (int i = 0; i < 32; i++)
    {
      re0 = a[0  + i];
      re1 = a[32 + i];
      im0 = a[64 + i];
      im1 = a[96 + i];

      //Butterfly +/-

      a[0  + i] =  add(re0, re1);
      a[32 + i] =  add(im0, im1);

      a[64 + i]  =  sub(re0, re1);
      a[96 + i]  =  sub(im0, im1);
    }

  for (int i = 0; i < 32; i++)
    {
      re0 = a[128 + 0  +  i];
      re1 = a[128 + 32 + i];
      im0 = a[128 + 64 + i];
      im1 = a[128 + 96 + i];

      //Butterfly +/- i

      a[128 + 0   + i] =  sub(re0, im1);
      a[128 + 32  + i] =  add(im0, re1);

      a[128 + 64 + i]  =  add(re0, im1);
      a[128 + 96 + i]  =  sub(im0, re1);
    }

  

  /*
    Stages 3 - 7

    Starts from x^32 - 1 and (x^32 - o) with o all other roots of order 32.

    x^32 - 1 -> x^16 - 1

    x^16 - 1 -> x^8 - 1

    x^8 - 1  -> x^4 -1

    x^4 - 1 -> x^2 - 1

    x^2 - 1 -> x - 1.

    Index for the roots goes back to zero at each stage. Roots must be in bitreversed order. 
    
  */
  
  for (len = 16, blocks = 4; len >= 1; len >>= 1, blocks <<= 1)
    {

      len2 = len<<1;
      len3 = len2 + len;
      len4 = len<<2;

      //First block with multiplication by 1
      ind = 0;

 
      for (int i = 0; i < len; i++)
	{
	  ii = ind + i;
	  
	  re0 = a[ii];
	  re1 = a[ii + len];
	  im0 = a[ii + len2];
	  im1 = a[ii + len3];

	  //Butterfly +/-
	  a[ii]        =  add(re0, re1);
	  a[ii + len]  =  add(im0, im1);
	  
	  a[ii + len2] =  sub(re0, re1);
	  a[ii + len3] =  sub(im0, im1);
	}

      //Second block with multiplication by i
      ind = ind + len4;
      for (int i = 0; i < len; i++)
	{
	  ii = ind + i;
	  
	  re0 = a[ii      ];
	  re1 = a[ii + len];
	  im0 = a[ii + len2];
	  im1 = a[ii + len3];

	  //Butterfly +/- i
	  a[ii      ] =  sub(re0, im1);
	  a[ii + len] =  add(im0, re1);
	  
	  a[ii + len2]  =  add(re0, im1);
	  a[ii + len3]  =  sub(im0, re1);
	}

      //Third block with multiplication by sqrt(i) -  no multiplication needed
      ind = ind + len4;      
      for (int i = 0; i < len; i++)
	{
	  ii = ind + i;
	  
	  re0 = a[ii];
	  re1 = a[ii + len];
	  im0 = a[ii + len2];
	  im1 = a[ii + len3];

	  //Butterfly +/- sqrt(i)

	  //sqrt(i) = (1+i)*2^15 = (32768 + i 32768)
      
	  t1_re = rot15(re1);
	  t1_im = rot15(im1);
	  
	  t2_re = sub(t1_re, t1_im);
	  t2_im = add(t1_re, t1_im);
      
	  a[ii]     =  add(re0, t2_re);
	  a[ii+len] =  add(im0, t2_im);
      
	  a[ii+len2]  = sub(re0, t2_re);
	  a[ii+len3]  = sub(im0, t2_im);
      	}

      //Fourth block with multiplication by sqrt(-i) -  no multiplication needed
      ind = ind + len4;      
      for (int i = 0; i < len; i++)
	 {
	   ii = ind + i;
	   re0 = a[ii];
	   re1 = a[ii + len];
	   im0 = a[ii + len2];
	   im1 = a[ii + len3];

	   //Butterfly +/- sqrt(-i) 
	   
	   //sqrt(-i) = (-1+i)*2^15 = (-32768 + i 32768)
	   
	   t1_re = rot15(re1);
	   t1_im = rot15(im1);
	   
	   t2_re = add(t1_re, t1_im); //-t2_re
	   t2_im = sub(t1_re, t1_im);
	   
	   a[ii]     = sub(re0, t2_re);//-t2_re
	   a[ii+len] = add(im0, t2_im);
	   
	   a[ii+len2]  = add(re0, t2_re);//-t2_re
	   a[ii+len3]  = sub(im0, t2_im);
	 }

      /*
	All other blocks with multiplication with subsequent roots
	taken from omegas128 (saved in bitreversed order)
      */

      //Root index: steps directly to 4 as blocks corresponding to k = 0,1,2,3 have been calculated above
      k = 4; 

      for (int bl = 0; bl < blocks - 4; bl++)
	 {
	   ind = ind + len4;
	   
	   om_re = omegas128[2*k];
	   om_im = omegas128[2*k+1];

	   k++;
	   
	   for (int i = 0; i < len; i++)
	     {
	       ii = ind + i;
	       re0 = a[ii];
	       re1 = a[ii + len];
	       im0 = a[ii + len2];
	       im1 = a[ii + len3];

	       t0 = prod(re1,om_re);
	       t1 = prod(im1,om_im);

	       t1_re =  sub(t0,t1);

	       t2 = prod(re1,om_im);
	       t3 = prod(im1,om_re);

	       t1_im =  add(t2,t3);
	       
	       a[ii]        = add(re0, t1_re);
	       a[ii + len]  = add(im0, t1_im);
	       a[ii + len2] = sub(re0, t1_re);
	       a[ii + len3] = sub(im0, t1_im);
	     }
	 }
    }
  
  return;
}
      
  

    
/******************************************************************************
* Name: mrsn_invntt256
*
* Description: In-place, decimation-in-time number theoretic negperiodic
*              transform (NTT) in Z_p with p the Mersenne prime 2^31-1.
*
*              Input in bitreversded order.
*              Output in natural order.
*
* Arguments: uint32_t a[256]: pointer to input/ouput vector of elements of Z_p
*
******************************************************************************/

void mrsn_invntt_256(uint32_t a[256])
{
  
  uint32_t re0, im0, re1, im1, t0, t1, t2, t3, om_re, om_im, t1_re, t1_im, t2_re, t2_im;

  int len, blocks, len2, len3, len4, ind, ii, k, k1, k2;
  
  /*
    Stages 7 - 3

    
    
  */
  
  for (len = 1, blocks = 64; len <= 16; len <<= 1, blocks >>= 1)
    {

      len2 = len<<1;
      len3 = len2 + len;
      len4 = len<<2;

      //First block with multiplication by 1
      ind = 0;

 
      for (int i = 0; i < len; i++)
	{
	  ii = ind + i;
	  
	  re0 = a[ii];
	  im0 = a[ii + len];
	  re1 = a[ii + len2];
	  im1 = a[ii + len3];

	  //Butterfly   +/-
	  a[ii]        =  add(re0, re1);
	  a[ii + len2]  =  add(im0, im1);
	  
	  a[ii + len]  =  sub(re0, re1);
	  a[ii + len3] =  sub(im0, im1);
	}

      //Second block with multiplication by conj(i) = -i
      ind = ind + len4;
      for (int i = 0; i < len; i++)
	{
	  ii = ind + i;
	  
	  re0 = a[ii      ];
	  im0 = a[ii + len];
	  re1 = a[ii + len2];
	  im1 = a[ii + len3];

	  
	  //Inverse Butterfly +/- i
	  a[ii      ] =  add(re0, re1);
	  a[ii + len2] =  add(im0, im1);
	  
	  a[ii + len]  =  sub(im0, im1);
	  a[ii + len3]  =  sub(re1, re0);
	}

      //Third block with multiplication by sqrt(i) -  no multiplication needed
      ind = ind + len4;      
      for (int i = 0; i < len; i++)
	{
	  ii = ind + i;
	  
	  re0 = a[ii];
	  im0 = a[ii + len];
	  re1 = a[ii + len2];
	  im1 = a[ii + len3];

	  //Butterfly +/- sqrt(i)

	  //sqrt(i) = (1+i)*2^15 = (32768 + i 32768)

	  a[ii]     =  add(re0, re1);
	  a[ii+len2] =  add(im0, im1);

	  t1_re =     sub(re0, re1); 
	  t1_im =     sub(im0, im1);
	  
	  t2_re = rot15(t1_re);
	  t2_im = rot15(t1_im);

	  // multiplication with conj(1+i) = (1-i)
	  
	  a[ii+len]  = add(t2_re, t2_im);
	  a[ii+len3]  = sub(t2_im, t2_re);
      	}

      //Fourth block with multiplication by sqrt(-i) -  no multiplication needed
      ind = ind + len4;      
      for (int i = 0; i < len; i++)
	 {
	   ii = ind + i;
	   re0 = a[ii];
	   im0 = a[ii + len];
	   re1 = a[ii + len2];
	   im1 = a[ii + len3];

	   //Butterfly +/- sqrt(-i) 
	   
	   //sqrt(-i) = (-1+i)*2^15 = (-32768 + i 32768)

	   a[ii]     =  add(re0, re1);
	   a[ii+len2] =  add(im0, im1);

	   t1_re =     sub(re1, re0); //-t_re
	   t1_im =     sub(im0, im1);
	   
	   t2_re = rot15(t1_re);
	   t2_im = rot15(t1_im);
	   
	   // multiplication with conj(-1+i) = (-1-i)
	   
	   a[ii+len]  = add(t2_im, t2_re);//-t2_re
	   a[ii+len3]  = sub(t2_re, t2_im);//-t2_re
	 }

      /*
	All other blocks with multiplication with subsequent roots
	taken from omegas128 (saved in bitreversed order)
      */

      //Root index: steps directly to 4 as blocks corresponding to k = 0,1,2,3 have been calculated above
      k = 4; 

      for (int bl = 0; bl < blocks - 4; bl++)
	 {
	   ind = ind + len4;
	   
	   om_re = omegas128[2*k];
	   om_im = omegas128[2*k+1];

	   //multiplication with conjugate

	   k++;
	   
	   for (int i = 0; i < len; i++)
	     {
	       ii = ind + i;
	       re0 = a[ii];
	       im0 = a[ii + len];
	       re1 = a[ii + len2];
	       im1 = a[ii + len3];
	       
	       a[ii]     =  add(re0, re1);
	       a[ii+len2] =  add(im0, im1);


	       t1_re =     sub(re0, re1); 
	       t1_im =     sub(im0, im1);
	  
	       t0 = prod(t1_re,om_re);
	       t1 = prod(t1_im,om_im);//-t1

	       a[ii + len] =  add(t0,t1);//-t1

	       t2 = prod(t1_re,om_im);//-t2
	       t3 = prod(t1_im,om_re);

	       a[ii + len3] =  sub(t3,t2);//-t2
	       
	     }
	 }
    }

    /*
    Stage 2 - done separately as this requires butterfly +/- i and no
    multiplication
    
    (x^64 - 1) -> (x^32 - 1) and (x_32 + 1)

    (x_64 + 1) -> (x^32 - i) and (x_32 + i)
  */
  
  	
  for (int i = 0; i < 32; i++)
    {
      re0 = a[0  + i];
      im0 = a[32 + i];
      re1 = a[64 + i];
      im1 = a[96 + i];

      //Butterfly +/-

      a[0  + i] =  add(re0, re1);
      a[64 + i] =  add(im0, im1);

      a[32 + i]  =  sub(re0, re1);
      a[96 + i]  =  sub(im0, im1);
    }

  for (int i = 0; i < 32; i++)
    {
      re0 = a[128 + 0  +  i];
      im0 = a[128 + 32 + i];
      re1 = a[128 + 64 + i];
      im1 = a[128 + 96 + i];

      //Inverse Butterfly +/- i

      a[128 + 0   + i] =  add(re0, re1);
      a[128 + 64  + i] =  add(im0, im1);

      a[128 + 32 + i]  =  sub(im0, im1);
      a[128 + 96 + i]  =  sub(re1, re0);
    }


  /*

    Stage 1 combined with twisting
    
  */

 

  re0 = a[0   ];
  im0 = a[64 ];

  re1 = a[128  ];
  im1 = a[192 ];

  a[0]    =  add(re0, re1);
  a[128]  =  add(im0, im1);
  
  t1_re  =  sub(re0, re1);
  t1_im  =  sub(im0, im1);
  
 
  /* Multiplication by conj(sqrt(i)) = (1-i)*2^15 */

  
  t2_re = rot15(t1_re);
  t2_im = rot15(t1_im);

  a[64]  =  add(t2_re, t2_im);
  
  a[192]  = sub(t2_im, t2_re);


  
  k1 = 0;
  k2 = 124;
  
  for (int i = 1; i < 64; i++)
    {
      re0 = a[0   + i];
      im0 = a[64  + i];

      re1 = a[128 + i];
      im1 = a[192 + i];

      t1_re  = add(re0, re1);
      t1_im  = add(im0, im1);

      t2_re  = sub(re0, re1);
      t2_im  = sub(im0, im1);

      om_re = omegas512[k1];
      om_im = omegas512[k1+1];

      k1 = k1 + 2;

      t0 = prod(t1_re,om_re);
      t1 = prod(t1_im,om_im);//-t1

      t2 = prod(t1_re,om_im);//-t2
      t3 = prod(t1_im,om_re);

      a[0   + i] = add(t0,t1);
      a[128 + i] = sub(t3,t2);

      
      /*
	Using symmetry (c,s) -> (s,c) around 45 degrees:
	cos(45 + x) = sin(45 - x)
	sin(45 + x) = cos(45 - x)

	This works also for complex roots in modular arithmetic
      */

      om_im = omegas512[k2]; 
      om_re = omegas512[k2+1]; 

      k2 = k2 - 2;

      t0 = prod(t2_re,om_re);
      t1 = prod(t2_im,om_im);//-t1

      t2 = prod(t2_re,om_im);//-t2
      t3 = prod(t2_im,om_re);
      

      a[64  + i] = add(t0,t1);
      a[192 + i] = sub(t3,t2);
      
    }
}




    
/******************************************************************************
* Name: mrsn_mulc_256
*
* Description: Multiplication of 2 arrays in NTT domain with elements in Zp
*              for p Mersenne prime 2^31-1.
*
* Arguments:
*   - uint32_t r[]: pointer to ouput array
*   - const uint32_t a[]: pointer to first input array
*   - const uint32_t a[]: pointer to second input array
* 
******************************************************************************/


void mrsn_mulc_256(uint32_t r[], const uint32_t a[], const uint32_t b[])
{
  uint32_t re0,im0, re1, im1, t0, t1, t2, t3;
  
  for (int i = 0; i < 256; i += 2)
    {
      re0 = a[i];
      im0 = a[i+1];
      
      re1 = b[i];
      im1 = b[i+1];

      t0 = prod(re0,re1);
      t1 = prod(im0,im1);

      t2 = prod(re0,im1);
      t3 = prod(im0,re1);

      r[i]   = sub(t0,t1);
      r[i+1] = add(t2,t3);
    }    
}


