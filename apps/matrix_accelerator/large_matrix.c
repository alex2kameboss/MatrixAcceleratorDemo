#include "ma_test_helper.h"
#include "ImtMatrixAccelerator.h"
#include "soc_metrics.h"

INIT(int32_t)

void acc_mult(int32_t* a, int32_t* b, int32_t *c, int32_t m, int32_t n, int32_t p) {
    MA_DEFINE_int32_t(2, 512, 512); 
    MA_LOC_RECT(2, 0, 512); // acc.define_matrix(2, 512, 512, 0, 512);
    
    MA_DEFINE_int32_t(3, 512, 512); 
    MA_LOC_RECT(3, 512, 512); // acc.define_matrix(3, 512, 512, 512, 512);

    uint64_t mem_time = 0;
    uint64_t compute_time = 0;

    for ( int32_t i = 0; i < m; i += 512 )
        for ( int32_t j = 0; j < p; j += 512 ) {
            for ( int32_t k = 0 ; k < n; k+= 512 ) {
                //printf("%d %d %d\r\n", i, j, k);
                // load 512x512 from A @ i, j + k -> M0
                // load 512x512 from B @ k, j -> M1
                MA_DEFINE_int32_t(0, 1, 512);
                MA_DEFINE_int32_t(1, 1, 512); 
                for ( int32_t l = 0; l < 512; l++ ) {
                    //printf("laod %d line\r\n", l);
                    MA_LOC_RECT(0, l, 0); // acc.define_matrix(0, 1, 512, l, 0);
                    start_timer();
                    MA_LOAD_REGISTER(0, a[(i + l) * n + k]); // acc.load_matrix(0, &a[(i + l) * n + k]); // a[i + l][j + k]
                    stop_timer();
                    mem_time += get_timer_value();
                    clear_timer();
                    MA_LOC_RECT(1, 512 + l, 0); // acc.define_matrix(1, 1, 512, 512 + l, 0);
                    start_timer();
                    MA_LOAD_REGISTER(1, b[(k + l) * p + j]);// acc.load_matrix(1, &b[(k + l) * p + j]); // b[k + l][j]
                    stop_timer();
                    mem_time += get_timer_value();
                    clear_timer();
                }
                MA_DEFINE_int32_t(0, 512, 512); 
                MA_LOC_RECT(0, 0, 0); // acc.define_matrix(0, 512, 512, 0, 0);
                MA_DEFINE_int32_t(0, 512, 512); 
                MA_LOC_RECT(0, 512, 0); // acc.define_matrix(1, 512, 512, 512, 0);

                //printf("Start compute\r\n");
                if ( k != 0 ) {
                    start_timer();
                    // M3 = M0 * M1
                    MA_VV_MULT(3, 0, 1) // acc.multiply_matrix(0, 1, 3);
                    // M2 += M3
                    MA_VV_ADD(2, 2, 3) // acc.add_matrix(2, 3, 2);
                    stop_timer();
                    compute_time += get_timer_value();
                    clear_timer();
                } else {
                    start_timer();
                    // M2 = M0 * M1
                    MA_VV_MULT(2, 0, 1) // acc.multiply_matrix(0, 1, 2);
                    stop_timer();
                    compute_time += get_timer_value();
                    clear_timer();
                }
                //printf("End compute\r\n");
            }

            MA_DEFINE_int32_t(4, 1, 512); 
            for ( int32_t l = 0; l < 512; l++ ) {
                //printf("store %d line\r\n", l);
                MA_LOC_RECT(4, l, 512); // acc.define_matrix(4, 1, 512, l, 512);
                start_timer();
                MA_STORE_REGISTER(4, c[(i + l) * p + j]); // acc.store_matrix(4, &c[(i + l) * p + j]); // c[i + l][j]
                stop_timer();
                mem_time += get_timer_value();
                clear_timer();
            }
        }

    printf("Memory time: %llu\r\n", mem_time);
    printf("Compute time: %llu\r\n", compute_time);
    printf("Total time: %llu\r\n", mem_time + compute_time);
}

void acc_mult_hw_burst(int32_t* a, int32_t* b, int32_t *c, int32_t m, int32_t n, int32_t p) {
    MA_DEFINE_int32_t(2, 256, 1024); 
    MA_LOC_RECT(2, 256 * 3, 0); // acc.define_matrix(2, 256, 1024, 256 * 3, 0);
    
    MA_DEFINE_int32_t(3, 256, 1024); 
    MA_LOC_RECT(3, 512, 0); // acc.define_matrix(3, 256, 1024, 512, 0);

    uint64_t mem_time = 0;
    uint64_t compute_time = 0;

    for ( int32_t i = 0; i < m; i+=256 )
        for ( int32_t j = 0; j < p; j+=1024 ) {

            for ( int32_t k = 0 ; k < n; k+= 1024 ) {
                //printf("%d %d %d\r\n", i, j, k);
                // load 256x1024 from A @ i, j + k -> M0
                MA_DEFINE_int32_t(0, 1, 1024); 
                start_timer();
                for ( int32_t l = 0; l < 256; l++ ) {
                    //printf("load A line: %d\r\n", l);
                    MA_LOC_RECT(0, l, 0); // acc.define_matrix(0, 1, 1024, l, 0);
                    MA_LOAD_REGISTER(0, a[(i + l) * n + k]); // acc.load_matrix(0, &a[(i + l) * n + k]); // a[i + l][j + k]
                }
                stop_timer();
                mem_time += get_timer_value();
                clear_timer();

                for ( int idx = 0; idx < 4; idx++ ) {
                    // load 256x1024 from B @ k + idx * 256 + 0, j -> M1
                    MA_DEFINE_int32_t(1, 1, 1024); 
                    for ( int32_t l = 0; l < 256; l++ ) {
                        //printf("load B line: %d\r\n", l);
                        MA_LOC_RECT(1, 256 + l, 0); // acc.define_matrix(1, 1, 1024, 256 + l, 0);
                        start_timer();
                        MA_LOAD_REGISTER(1, b[(k + idx * 256 + l) * p + j]); // acc.load_matrix(1, &b[(k + idx * 256 + l) * p + j]); // b[k + idx * 256 + l][j]
                        stop_timer();
                        mem_time += get_timer_value();
                        clear_timer();
                    }

                    MA_DEFINE_int32_t(0, 256, 256); 
                    MA_LOC_RECT(0, 0, idx * 256); // acc.define_matrix(0, 256, 256, 0, idx * 256);

                    for ( int l = 0; l < 4; l++ ) {
                        //printf("compute submatrix: %d\r\n", l);
                        MA_DEFINE_int32_t(1, 256, 256); 
                        MA_LOC_RECT(1, 256, l * 256); // acc.define_matrix(1, 256, 256, 256, l * 256);

                        //printf("start compute\r\n");
                        MA_DEFINE_int32_t(4, 256, 256);
                        if ( k != 0 || idx != 0 ) {
                            MA_LOC_RECT(4, 512, l * 256); // acc.define_matrix(4, 256, 256, 512, l * 256);
                            start_timer(); 
                            // M4 = M0 * M1
                            MA_VV_MULT(4, 0, 1); // acc.multiply_matrix(0, 1, 4);
                            stop_timer();
                            compute_time += get_timer_value();
                            clear_timer();
                        } else {
                            MA_LOC_RECT(4, 256 * 3, l * 256); // acc.define_matrix(4, 256, 256, 256 * 3, l * 256); // initialize result matrix
                            start_timer();
                            // M4 = M0 * M1
                            MA_VV_MULT(4, 0, 1); // acc.multiply_matrix(0, 1, 4);
                            stop_timer();
                            compute_time += get_timer_value();
                            clear_timer();
                        }
                        //printf("stop compute\r\n");
                    }
                    if ( k != 0 || idx != 0 ) {
                        //printf("start compute\r\n");
                        start_timer();
                        MA_VV_ADD(2, 2, 3); // acc.add_matrix(2, 3, 2);
                        stop_timer();
                        compute_time += get_timer_value();
                        clear_timer();
                        //printf("stop compute\r\n");
                    }
                }
            }

            MA_DEFINE_int32_t(4, 1, 1024); 
            for ( int32_t l = 0; l < 256; l++ ) {
                //printf("store line: %d\r\n", l);
                MA_LOC_RECT(4, 256 * 3 + l, 0); // acc.define_matrix(4, 1, 1024, 256 * 3 + l, 0);
                start_timer();
                MA_STORE_REGISTER(4, c[(i + l) * p + j]); // acc.store_matrix(4, &c[(i + l) * p + j]); // c[i + l][j]
                stop_timer();
                mem_time += get_timer_value();
                clear_timer();
            }
        }

    printf("Memory time: %llu\r\n", mem_time);
    printf("Compute time: %llu\r\n", compute_time);
    printf("Total time: %llu\r\n", mem_time + compute_time);
}

int main() {
    for ( int i = 1; i <= 4; i++ ) {
        int n = i * 1024;
        printf("Size: %d\r\n", n);
        int32_t a[n * n] __attribute__((aligned(4096)));
        int32_t b[n * n] __attribute__((aligned(4096)));
        int32_t c[n * n] __attribute__((aligned(4096)));
    
        //printf("Naive mult: ");
        //start_timer();
        //mult_int32_t(a, b, c, n, n, n);
        //stop_timer();
        //print_timer_value_dec();
        //clear_timer();
        //printf("\r\n");
    
        printf("Baisic block multiplication\r\n");
        acc_mult(a, b, c, n, n, n);
        
        printf("Burst access - block multiplication\r\n");
        acc_mult_hw_burst(a, b, c, n, n, n);
    }

    while(1) ;

    return 0;
}