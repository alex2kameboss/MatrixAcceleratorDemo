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
void debug_##DTYPE(DTYPE *a, DTYPE *b, DTYPE *res_sw, DTYPE *res_hw, int m, int n, int p) { \
    if ( DEBUG_EN ) { \
        printf("\na = \n"); \
        print_array_##DTYPE(a, n, m); \
        printf("b = \n"); \
        print_array_##DTYPE(b, p, n); \
        printf("sw = \n"); \
        print_array_##DTYPE(res_sw, p, m); \
        printf("hw = \n"); \
        print_array_##DTYPE(res_hw, p, m); \
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

#define CONVOLUTION(DTYPE) \
    void print_array_cnv_##DTYPE(DTYPE *ptr, int w, int h, int hw_w) { \
        for (int i = 0; i < h; ++i) { \
            for (int j = 0; j < w; ++j) \
                printf("%#08x ", ptr[i * hw_w + j]); \
            printf("\n"); \
        } \
    } \
    void debug_cnv_##DTYPE(DTYPE *a, DTYPE *b, DTYPE *res_sw, DTYPE *res_hw, int m, int n, int k_m, int k_n, int kernel_n) { \
        if ( DEBUG_EN ) { \
            printf("\na = \n"); \
            print_array_##DTYPE(a, n, m); \
            printf("b = \n"); \
            print_array_cnv_##DTYPE(b, k_n, k_m, kernel_n); \
            printf("sw = \n"); \
            print_array_cnv_##DTYPE(res_sw, m - k_m + 1, n - k_n + 1, n); \
            printf("hw = \n"); \
            print_array_cnv_##DTYPE(res_hw, m - k_m + 1, n - k_n + 1, n); \
        } \
    } \
    void cnv_##DTYPE(DTYPE *a, DTYPE *b, DTYPE *c, int m, int n, int k_m, int k_n, int kernel_n) { \
        for (int i = 0; i < m - k_m + 1; ++i) { \
            for (int j = 0; j < n - k_n + 1; ++j) { \
                c[i * n + j] = 0; \
                for ( int ii = 0; ii < k_m; ++ii ) \
                    for ( int jj = 0; jj < k_n; ++jj ) \
                        c[i * n + j] += a[(i + ii) * m + j + jj] * b[ii * kernel_n + jj]; \
            } \
        } \
    } \
    bool cmp_cnv_##DTYPE(DTYPE* src1, DTYPE* src2, int w, int h, int hw_w) { \
        for (int i = 0; i < h; ++i) \
            for (int j = 0; j < w; ++j) \
                if (src1[i * hw_w + j] != src2[i * hw_w + j]) \
                    return false; \
        return true; \
    } \

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
    DEBUG(DTYPE) \
    CONVOLUTION(DTYPE)

#endif