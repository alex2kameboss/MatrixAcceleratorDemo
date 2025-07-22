#include "ma_test_helper.h"
#include "ImtMatrixAccelerator.h"
#include "soc_metrics.h"

#define MAX_WIDTH 1024
#define MAX_HEIGHT 1024

#ifndef SEED
#define SEED 0
#endif

#define N_LANES 8
#define DATA_WIDTH 4
#define BUS_WIDTH (N_LANES * DATA_WIDTH)

int seed = SEED;

int numberOfTests = 0;
int passedTests = 0;

INIT(int8_t)
INIT(int16_t)
INIT(int32_t)

#define VV_TEST_BASE(DTYPE_I, DTYPE_O, ACC, REF) \
    DTYPE_I a[m * n] __attribute__((aligned(512))); \
    DTYPE_I b[n * p] __attribute__((aligned(512))); \
    DTYPE_O res_sw[m * p]; \
    DTYPE_O res_hw[m * p] __attribute__((aligned(512))); \
    init_array_##DTYPE_I(a, n, m); \
    init_array_##DTYPE_I(b, p, n); \
    start_timer(); \
    MA_DEFINE_##DTYPE_I(0, m, n); \
    MA_DEFINE_##DTYPE_I(1, n, p); \
    MA_DEFINE_##DTYPE_O(2, m, p); \
    MA_LOC_RECT(0, 0, 0); \
    MA_LOC_RECT(1, 0, MAX_HEIGHT/2); \
    MA_LOC_RECT(2, MAX_WIDTH/2, MAX_HEIGHT/2); \
    MA_LOAD_REGISTER(0, a); \
    MA_LOAD_REGISTER(1, b); \
    ACC(2, 0, 1); \
    MA_STORE_REGISTER(2, res_hw); \
    stop_timer(); \
    print_timer_value_hex(); \
    printf(","); \
    start_timer(); \
    REF##_##DTYPE_O(a, b, res_sw, m, n, p); \
    stop_timer(); \
    print_timer_value_hex(); \
    printf(","); \
    FLUSH_D_CACHE(); \
    debug_##DTYPE_I(a, b, res_sw, res_hw, m, n, p); \
    return cmp_##DTYPE_O(res_hw, res_sw, m * p);

#define VS_TEST_BASE(DTYPE_I, DTYPE_O, ACC, REF, B) \
    DTYPE_I a[m * n] __attribute__((aligned(512))); \
    DTYPE_O res_sw[m * p]; \
    DTYPE_O res_hw[m * p] __attribute__((aligned(512))); \
    init_array_##DTYPE_I(a, n, m); \
    start_timer(); \
    MA_DEFINE_##DTYPE_I(0, m, n); \
    MA_DEFINE_##DTYPE_O(2, m, p); \
    MA_LOC_RECT(0, 0, 0); \
    MA_LOC_RECT(2, MAX_WIDTH/2, MAX_HEIGHT/2); \
    MA_LOAD_REGISTER(0, a); \
    ACC(2, 0, B); \
    MA_STORE_REGISTER(2, res_hw); \
    stop_timer(); \
    print_timer_value_dec(); \
    clear_timer(); \
    printf(","); \
    start_timer(); \
    REF##_##DTYPE_O(a, B, res_sw, m, n, p); \
    stop_timer(); \
    print_timer_value_dec(); \
    clear_timer(); \
    printf(","); \
    FLUSH_D_CACHE(); \
    debug_vs_##DTYPE_I(a, B, res_sw, res_hw, m, n, p); \
    return cmp_##DTYPE_O(res_hw, res_sw, m * p);

#define CNV_TEST_BASE(DTYPE_I, DTYPE_O) \
    int kernel_n = BUS_WIDTH / sizeof(DTYPE_I); \
    DTYPE_I a[m * n] __attribute__((aligned(512))); \
    DTYPE_I b[k_m * kernel_n] __attribute__((aligned(512))); \
    int res_m = m - k_m + 1; \
    int res_n = n - k_n + 1; \
    DTYPE_O res_sw[m * n]; \
    DTYPE_O res_hw[m * n] __attribute__((aligned(512))); \
    init_array_##DTYPE_I(a, n, m); \
    init_array_##DTYPE_I(b, kernel_n, k_m); \
    start_timer(); \
    MA_DEFINE_##DTYPE_I(0, m, n); \
    MA_DEFINE_##DTYPE_I(1, k_m, kernel_n); \
    MA_DEFINE_##DTYPE_O(2, res_m, res_n); \
    MA_LOC_RECT(0, 0, 0); \
    MA_LOC_RECT(1, 0, MAX_HEIGHT/2); \
    MA_LOC_RECT(2, MAX_WIDTH/2, MAX_HEIGHT/2); \
    MA_LOAD_REGISTER(0, a); \
    MA_LOAD_REGISTER(1, b); \
    MA_DEFINE_##DTYPE_I(1, k_m, k_n); \
    MA_VV_CNV(2, 0, 1); \
    MA_DEFINE_##DTYPE_I(2, res_m, n); \
    MA_STORE_REGISTER(2, res_hw); \
    stop_timer(); \
    print_timer_value_dec(); \
    clear_timer(); \
    printf(","); \
    start_timer(); \
    cnv_##DTYPE_O(a, b, res_sw, m, n, k_m, k_n, kernel_n); \
    stop_timer(); \
    print_timer_value_dec(); \
    clear_timer(); \
    printf(","); \
    FLUSH_D_CACHE(); \
    debug_cnv_##DTYPE_I(a, b, res_sw, res_hw, m, n, k_m, k_n, kernel_n); \
    return cmp_cnv_##DTYPE_O(res_hw, res_sw, res_n, res_m, n);

#define ADD_TEST_BASE(DTYPE_I, DTYPE_O) VV_TEST_BASE(DTYPE_I, DTYPE_O, MA_VV_ADD, add)
#define SUB_TEST_BASE(DTYPE_I, DTYPE_O) VV_TEST_BASE(DTYPE_I, DTYPE_O, MA_VV_SUB, sub)
#define MULT_TEST_BASE(DTYPE_I, DTYPE_O) VV_TEST_BASE(DTYPE_I, DTYPE_O, MA_VV_MULT, mult)
#define SMULT_TEST_BASE(DTYPE_I, DTYPE_O) VV_TEST_BASE(DTYPE_I, DTYPE_O, MA_VV_SMULT, smult)
#define SLL_TEST_BASE(DTYPE_I, DTYPE_O) VS_TEST_BASE(DTYPE_I, DTYPE_O, MA_VS_SLL, sll, 3)
#define SRA_TEST_BASE(DTYPE_I, DTYPE_O) VS_TEST_BASE(DTYPE_I, DTYPE_O, MA_VS_SRA, sra, 3)

#define ADD_TEST(DTYPE) bool add_test_##DTYPE(int m, int n, int p) { ADD_TEST_BASE(DTYPE, DTYPE) }
#define SUB_TEST(DTYPE) bool sub_test_##DTYPE(int m, int n, int p) { SUB_TEST_BASE(DTYPE, DTYPE) }
#define MULT_TEST(DTYPE) bool mult_test_##DTYPE(int m, int n, int p) { MULT_TEST_BASE(DTYPE, DTYPE) }
#define SMULT_TEST(DTYPE) bool smult_test_##DTYPE(int m, int n, int p) { SMULT_TEST_BASE(DTYPE, DTYPE) }
#define CNV_GENERIC_TEST(DTYPE) bool cnv_generic_test_##DTYPE(int m, int n, int k_m, int k_n) { CNV_TEST_BASE(DTYPE, DTYPE) }
#define CNV_TEST(DTYPE) bool cnv_test_4x4_##DTYPE(int m, int n, int p) { return cnv_generic_test_##DTYPE(m, n, 4, 4); }
#define SLL_TEST(DTYPE) bool sll_test_##DTYPE(int m, int n, int p) { SLL_TEST_BASE(DTYPE, DTYPE) }
#define SRA_TEST(DTYPE) bool sra_test_##DTYPE(int m, int n, int p) { SRA_TEST_BASE(DTYPE, DTYPE) }

#define GROUP_TEST(DTYPE) \
    ADD_TEST(DTYPE) \
    SUB_TEST(DTYPE) \
    MULT_TEST(DTYPE) \
    SMULT_TEST(DTYPE) \
    CNV_GENERIC_TEST(DTYPE) \
    CNV_TEST(DTYPE) \
    SLL_TEST(DTYPE) \
    SRA_TEST(DTYPE)

GROUP_TEST(int8_t)
GROUP_TEST(int16_t)
GROUP_TEST(int32_t)

int printResult(bool result) {
    printf("%s,%d\n", result ? "PASSED" : "FAILED", seed - 1);
    return result;
}

#define RUN_TEST(TEST_NAME, TEST_FN, SIZE) { \
    srand(seed++); \
    numberOfTests++; \
    printf("%s,%s,", _STR(TEST_NAME), _STR(SIZE));\
    passedTests += printResult(TEST_FN(SIZE, SIZE, SIZE)); \
}

#define RUN_TEST_GROUP(DTYPE, SIZE) {\
    RUN_TEST(Addition, DTYPE, add_test_##DTYPE, SIZE) \
    RUN_TEST(Substraction, DTYPE, sub_test_##DTYPE, SIZE) \
    RUN_TEST(DotProduct, DTYPE, mult_test_##DTYPE, SIZE) \
    RUN_TEST(CrossProduct, DTYPE, smult_test_##DTYPE, SIZE) \
    RUN_TEST(Convolution_4x4, DTYPE, cnv_test_4x4_##DTYPE, SIZE) \
    RUN_TEST(SLL_3, DTYPE, sll_test_##DTYPE, SIZE) \
    RUN_TEST(SRA_3, DTYPE, sra_test_##DTYPE, SIZE) \
}

#define RUN_TEST_GROUP_SIZE(SIZE) { \
    RUN_TEST_GROUP(int8_t, SIZE) \
    RUN_TEST_GROUP(int16_t, SIZE) \
    RUN_TEST_GROUP(int32_t, SIZE) \
}

int main() {
    printf("test,size,hw,sw,result,seed\n");
    
#ifdef TEST_16
    RUN_TEST_GROUP_SIZE(16)
#endif

#ifdef TEST_32
    RUN_TEST_GROUP_SIZE(32) 
#endif

#ifdef TEST_64
    RUN_TEST_GROUP_SIZE(64) 
#endif

#ifdef TEST_128
    RUN_TEST_GROUP_SIZE(128)
#endif

#ifdef TEST_256
    RUN_TEST_GROUP_SIZE(256)
#endif


    printf("%d/%d\n", passedTests, numberOfTests);
}