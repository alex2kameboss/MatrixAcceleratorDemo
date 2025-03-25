#include "printf.h"
#include "ImtMatrixAccelerator.h"
#include <stdint.h>
#include <stdlib.h>

#define RND_FACTOR 10
#define RIDX 0

int main() {
    const int n = 16;
    int32_t a[n * n];
    int32_t b[n * n];

    // randomize
    for ( int i = 0; i < n * n; ++i )
        a[i] = rand() % RND_FACTOR + 1;

    printf("Init done.\n");
    // accelerator operations
    MA_DEFINE_int32_t(RIDX, n, n);
    MA_LOC_RECT(RIDX, 0, 0);
    MA_LOAD_REGISTER(RIDX, a);
    MA_STORE_REGISTER(RIDX, b);

    // check
    int ok = 1;
    int diff = 0;
    for ( int i = 0; i < n * n; ++i )
        if ( a[i] != b[i] ) {
            ok = 0;
            diff++;
        }

    if ( ok ) {
        printf("LOAD STORE test passed!\n");
    } else {
        printf("LOAD STORE test failed, with %d different data!\n", diff);
    }
    return 0;
}