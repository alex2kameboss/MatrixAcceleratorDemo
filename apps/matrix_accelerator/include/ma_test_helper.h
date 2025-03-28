#ifndef MA_TEST_HELPER_H
#define MA_TEST_HELPER_H

#ifndef RND_FACTOR
#define RND_FACTOR 10
#endif

#ifndef DEBUG_EN
#define DEBUG_EN 0
#endif

#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include "printf.h"

#define DEBUG(DTYPE) \
void debug_##DTYPE(DTYPE *a, DTYPE *b, DTYPE *res_sw, DTYPE *res_hw) { \
    if ( DEBUG_EN ) { \
        printf("\na = \n"); \
        print_array_##DTYPE(a, N, M); \
        printf("b = \n"); \
        print_array_##DTYPE(b, P, N); \
        printf("sw = \n"); \
        print_array_##DTYPE(res_sw, P, M); \
        printf("hw = \n"); \
        print_array_##DTYPE(res_hw, P, M); \
    } \
} 

#define PRINT_ARRAY(DTYPE) \
void print_array_##DTYPE(DTYPE *ptr, int w, int h) { \
    for (int i = 0; i < h; ++i) { \
        for (int j = 0; j < w; ++j) \
            printf("%#08x ", ptr[i * w + j]); \
        printf("\n"); \
    } \
} 

#define SCALAR_OPERATION_FN(DTYPE, NAME, OP) \
void NAME##_##DTYPE(DTYPE *a, DTYPE *b, DTYPE *c, int m, int n, int p) { \
    for (int i = 0; i < m; ++i) { \
        for (int j = 0; j < n; ++j) { \
            c[i * n + j] = a[i * n + j] OP b[i * n + j]; \
        } \
    } \
} 

#define INIT(DTYPE) \
    void init_array_##DTYPE(DTYPE *ptr, int w, int h) { \
        for (int i = 0; i < h; ++i) \
            for (int j = 0; j < w; ++j) \
                ptr[i * w + j] = rand() % RND_FACTOR + 1; \
    } \
    bool cmp_##DTYPE(DTYPE* src1, DTYPE* src2, int len) { \
        for ( int i =0 ; i < len; ++i ) \
            if (src1[i] != src2[i]) \
                return false; \
        return true; \
    } \
    void mult_##DTYPE(DTYPE *a, DTYPE *b, DTYPE *c, int m, int n, int p) { \
        for (int i = 0; i < m; ++i) { \
            for (int j = 0; j < p; ++j) { \
                c[i * p + j] = 0; \
                for (int k = 0; k < n; ++k) \
                    c[i * p + j] += a[i * n + k] * b[k * p + j]; \
            } \
        } \
    } \
    SCALAR_OPERATION_FN(DTYPE, add, +) \
    SCALAR_OPERATION_FN(DTYPE, sub, -) \
    SCALAR_OPERATION_FN(DTYPE, div, /) \
    SCALAR_OPERATION_FN(DTYPE, smult, *) \
    PRINT_ARRAY(DTYPE) \
    DEBUG(DTYPE)

#endif