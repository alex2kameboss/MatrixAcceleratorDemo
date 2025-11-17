#include "printf.h"

int main() {
    int i;
    while (1) {
        printf("Hello world!\r\n");
        for ( i = 0; i < 1e6; i = i + 1 ) ;
    }
    return 0;
}