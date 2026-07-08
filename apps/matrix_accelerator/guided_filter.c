#include "printf.h"
#include "ImtMatrixAccelerator.h"
#include <stdint.h>

#define N_LANES 8

#define WIDTH N_LANES
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

int main() {
    int32_t base[HEIGHT * WIDTH];
    int32_t res[(HEIGHT + 2) * (WIDTH + N_LANES)];

    for ( int i = 0; i < HEIGHT; i++ )
        for ( int j = 0; j < WIDTH; j++ )
            base[i * WIDTH + j] = i * WIDTH + j;

    MA_DEFINE_int32_t(0, HEIGHT, WIDTH);
    MA_LOC_RECT(0, 2, N_LANES);
    MA_LOAD_REGISTER(0, base);

    MA_DEFINE_int32_t(1, HEIGHT, N_LANES);
    MA_LOC_RECT(1, 2, 0);
    MA_VV_BC(1, 0);

    ROW_BC(int32_t, 3, 2, (WIDTH + N_LANES), 2, 0, 0, 0);

    MA_DEFINE_int32_t(2, (HEIGHT + 2), (WIDTH + N_LANES));
    MA_LOC_RECT(2, 0, 0);
    MA_STORE_REGISTER(2, res);

    for ( int i = 0; i < HEIGHT + 2; i++ ) {
        for ( int j = 0; j < WIDTH + N_LANES; j++ )
            printf("%d ", res[i * (WIDTH + N_LANES) + j]);
        printf("\n");
    }
}