#include "ma_test_helper.h"
#include "ImtMatrixAccelerator.h"
#include "soc_metrics.h"

#define MAX_WIDTH 1024
#define MAX_HEIGHT 1024

#ifndef SEED
#define SEED 0
#endif

int seed = SEED;

int numberOfTests = 0;
int passedTests = 0;

INIT(int8_t)
INIT(int16_t)
INIT(int32_t)

#define TEST_BASE(DTYPE_I, DTYPE_O, ACC, REF) \
    DTYPE_I a[m * n], b[n * p]; \
    DTYPE_O res_sw[m * p], res_hw[m * p]; \
    init_array_##DTYPE_I(a, n, m); \
    init_array_##DTYPE_I(b, p, n); \
    start_timer(); \
    MA_DEFINE_##DTYPE_I(0, n, m); \
    MA_DEFINE_##DTYPE_I(1, p, n); \
    MA_DEFINE_##DTYPE_O(2, p, m); \
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

#define ADD_TEST_BASE(DTYPE_I, DTYPE_O) TEST_BASE(DTYPE_I, DTYPE_O, MA_VV_ADD, add)
#define SUB_TEST_BASE(DTYPE_I, DTYPE_O) TEST_BASE(DTYPE_I, DTYPE_O, MA_VV_SUB, sub)
#define MULT_TEST_BASE(DTYPE_I, DTYPE_O) TEST_BASE(DTYPE_I, DTYPE_O, MA_VV_MULT, mult)
#define SMULT_TEST_BASE(DTYPE_I, DTYPE_O) TEST_BASE(DTYPE_I, DTYPE_O, MA_VV_SMULT, smult)

#define ADD_TEST(DTYPE) bool add_test_##DTYPE(int m, int n, int p) { ADD_TEST_BASE(DTYPE, DTYPE) }
#define SUB_TEST(DTYPE) bool sub_test_##DTYPE(int m, int n, int p) { SUB_TEST_BASE(DTYPE, DTYPE) }
#define MULT_TEST(DTYPE) bool mult_test_##DTYPE(int m, int n, int p) { MULT_TEST_BASE(DTYPE, DTYPE) }
#define SMULT_TEST(DTYPE) bool smult_test_##DTYPE(int m, int n, int p) { SMULT_TEST_BASE(DTYPE, DTYPE) }

#define GROUP_TEST(DTYPE) \
    ADD_TEST(DTYPE) \
    SUB_TEST(DTYPE) \
    MULT_TEST(DTYPE) \
    SMULT_TEST(DTYPE) 

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
    RUN_TEST(Addition_##DTYPE, add_test_##DTYPE, SIZE) \
    RUN_TEST(Substraction_##DTYPE, sub_test_##DTYPE, SIZE) \
    RUN_TEST(Multiplication_##DTYPE, mult_test_##DTYPE, SIZE) \
    RUN_TEST(SMultiplication_##DTYPE, smult_test_##DTYPE, SIZE) \
}

#define RUN_TEST_GROUP_SIZE(SIZE) { \
    RUN_TEST_GROUP(int8_t, SIZE) \
    RUN_TEST_GROUP(int16_t, SIZE) \
    RUN_TEST_GROUP(int32_t, SIZE) \
}

int main() {
    printf("test,size,hw,sw,result,seed\n");
    
    RUN_TEST_GROUP_SIZE(32)
    RUN_TEST_GROUP_SIZE(64)
    RUN_TEST_GROUP_SIZE(128)
    RUN_TEST_GROUP_SIZE(256)

    printf("%d/%d\n", passedTests, numberOfTests);
}