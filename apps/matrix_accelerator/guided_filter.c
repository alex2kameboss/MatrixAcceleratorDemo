#include "printf.h"
#include "ImtMatrixAccelerator.h"

#include <stdint.h>

#define N_LANES 8

#define WIDTH (2 * N_LANES)
#define HEIGHT 4

#define ROW_BC(DTYPE, ID, H, W, SRC_X, SRC_Y, DST_X, DST_Y) { \
    MA_DEFINE_##DTYPE(31, 1, W); \
    MA_LOC_RECT(31, SRC_X, SRC_Y); \
    MA_DEFINE_##DTYPE(30, 1, W); \
    for ( int II = 0; II < H; II++ ) { \
        MA_LOC_RECT(30, DST_X + II, DST_Y); \
        MA_VS_ADD(30, 31, 0); \
    } \
    MA_DEFINE_##DTYPE(ID, H, W); \
    MA_LOC_RECT(ID, DST_X, DST_Y); \
}

#define LOAD_SUB_MATRIX(DTYPE, ID, PTR, ORIG_W, TILE_H, TILE_W, TILE_X, TILE_Y, PRF_X, PRF_Y) { \
    MA_DEFINE_##DTYPE(31, 1, TILE_W); \
    for ( int II = 0; II < TILE_H; II++ ) { \
        MA_LOC_RECT(31, PRF_X + II, PRF_Y); \
        MA_LOAD_REGISTER(31, PTR[(TILE_X + II) * ORIG_W + TILE_Y]); \
    } \
    MA_DEFINE_##DTYPE(ID, TILE_H, TILE_W); \
    MA_LOC_RECT(ID, PRF_X, PRF_Y); \
}

#define STORE_SUB_MATRIX(DTYPE, PTR, ORIG_W, TILE_H, TILE_W, TILE_X, TILE_Y, PRF_X, PRF_Y) { \
    MA_DEFINE_##DTYPE(31, 1, TILE_W); \
    for ( int II = 0; II < TILE_H; II++ ) { \
        MA_LOC_RECT(31, PRF_X + II, PRF_Y); \
        MA_STORE_REGISTER(31, PTR[(TILE_X + II) * ORIG_W + TILE_Y]); \
    } \
}

int main() {
    //int32_t base[HEIGHT * WIDTH] __attribute__((aligned(32)));
    //int32_t res[(HEIGHT + 2) * (WIDTH + N_LANES)] __attribute__((aligned(32)));

    //for ( int i = 0; i < HEIGHT; i++ )
    //    for ( int j = 0; j < WIDTH; j++ )
    //        base[i * WIDTH + j] = i * WIDTH + j;

    //MA_DEFINE_int32_t(0, HEIGHT, WIDTH);
    //MA_LOC_RECT(0, 2, N_LANES);
    //MA_LOAD_REGISTER(0, base[0]);

    //LOAD_SUB_MATRIX(int32_t, 0, base, WIDTH, HEIGHT, (WIDTH / 2), 0, (WIDTH / 2), 2, N_LANES);
    //LOAD_SUB_MATRIX(int32_t, 4, base, WIDTH, HEIGHT, (WIDTH / 2), 0, (WIDTH / 2), 2, (N_LANES + WIDTH / 2));

    //MA_VS_MULT(0, 0, 2);

    //MA_DEFINE_int32_t(1, HEIGHT, N_LANES);
    //MA_LOC_RECT(1, 2, 0);
    //MA_VV_BC_L(1, 0);

    //ROW_BC(int32_t, 3, 2, (WIDTH + N_LANES), 2, 0, 0, 0);

    //MA_DEFINE_int32_t(2, (HEIGHT + 2), (WIDTH + N_LANES));
    //MA_LOC_RECT(2, 0, 0);
    //MA_STORE_REGISTER(2, res);

    ///MA_VV_BC_R(1, 0);

    //STORE_SUB_MATRIX(int32_t, res, (WIDTH + N_LANES), (HEIGHT + 2), N_LANES, 0, WIDTH, 0, 0);

    //for ( int i = 0; i < HEIGHT + 2; i++ ) {
    //    for ( int j = 0; j < WIDTH + N_LANES; j++ )
    //        printf("%3d ", res[i * (WIDTH + N_LANES) + j]);
    //    printf("\n");
    //}

    int8_t a[4 * 32] __attribute__((aligned(32)));
    int32_t b[4 * 32] __attribute__((aligned(32)));
    int32_t c[4 * 32] __attribute__((aligned(32)));

    for ( int i = 0; i < 4; i++ )
        for ( int j = 0; j < 32; j++ ) {
            a[i * 32 + j] = j;
            b[i * 32 + j] = i;
        }

    MA_DEFINE_int8_t(0, 4, 32);
    MA_LOC_RECT(0, 0, 0);
    MA_LOAD_REGISTER(0, a);

    MA_DEFINE_int32_t(1, 4, 32);
    MA_LOC_RECT(1, 0, 32);
    MA_LOAD_REGISTER(1, b);

    MA_DEFINE_int32_t(2, 4, 32);
    MA_LOC_RECT(2, 32, 32);
    MA_VV_SMULT(2, 0, 1);
    MA_STORE_REGISTER(2, c);

    for ( int i = 0; i < 4; i++ ) {
        for ( int j = 0; j < 32; j++ )
            printf("%3d ", c[i * 32 + j]);
        printf("\n");
    }
}