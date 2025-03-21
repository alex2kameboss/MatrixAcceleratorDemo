//#include "printf.h"

extern char fake_uart;

int main() {
    //printf("Hello world\n");
    fake_uart = 'H';
    fake_uart = 'e';
    fake_uart = 'l';
    fake_uart = 'l';
    fake_uart = 'o';
    fake_uart = ' ';
    fake_uart = 'w';
    fake_uart = 'o';
    fake_uart = 'r';
    fake_uart = 'l';
    fake_uart = 'd';
    fake_uart = '!';
    fake_uart = '\n';
    return 0;
}