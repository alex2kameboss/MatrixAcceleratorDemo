#include <stdint.h>
#include "printf.h"

#define M 1
#define N 16

typedef int32_t mi32 __attribute__((matrix_type(M,N)));

void vec_add(mi32 *pva, mi32 *pvb, mi32 *pvc) {
  *pva = *pvb + *pvc;
}

int main() {
    mi32 a, b, c;

    for ( int i = 0; i < M; ++i )
        for ( int j = 0; j < N; ++j ) {
            a[i][j] = i + j;
            b[i][j] = i - j;
        }
    
    vec_add(&a, &b, &c);

    for ( int i = 0; i < M; ++i ) {
        for ( int j = 0; j < N; ++j )
            printf("%d ", c[i][j]);
        printf("\n");
    }
    

    return 0;
}