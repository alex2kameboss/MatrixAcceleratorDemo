#ifndef MRSN_NTT_H
#define MRSN_NTT_H

void mrsn_ntt_256(uint32_t a[256]);

void mrsn_invntt_256(uint32_t a[256]);

void mrsn_mulc_256(uint32_t r[], const uint32_t a[], const uint32_t b[]);


#endif
