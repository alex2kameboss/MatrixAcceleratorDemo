#include "printf.h"
#include "ImtMatrixAccelerator.h"
#include <stdint.h>

#define N_LANES 8

#define WIDTH N_LANES
#define HEIGHT 4

int main() {
    int32_t base[HEIGHT * WIDTH];
    int32_t res[HEIGHT * (WIDTH + N_LANES)];

    for ( int i = 0; i < HEIGHT; i++ )
        for ( int j = 0; j < WIDTH; j++ )
            base[i * WIDTH + j] = i * WIDTH + j;

    MA_DEFINE_int32_t(0, HEIGHT, WIDTH);
    MA_LOC_RECT(0, 0, N_LANES);

    MA_DEFINE_int32_t(1, HEIGHT, N_LANES);
    MA_LOC_RECT(1, 0, 0);

    MA_DEFINE_int32_t(2, HEIGHT, (WIDTH + N_LANES));
    MA_LOC_RECT(2, 0, 0);

    MA_LOAD_REGISTER(0, base);
    MA_VV_BC(1, 0);
    MA_STORE_REGISTER(2, res);

    for ( int i = 0; i < HEIGHT; i++ ) {
        for ( int j = 0; j < WIDTH + N_LANES; j++ )
            printf("%d ", res[i * (WIDTH + N_LANES) + j]);
        printf("\n");
    }
}