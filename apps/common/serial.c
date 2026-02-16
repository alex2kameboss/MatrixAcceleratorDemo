#include <stdint.h>

extern volatile char fake_uart;

#define VIVADO

void _putchar(char character) {
  volatile char *p = (char *)0x40000008;
  while (p[0] & (1 << 3)) ;
  // send char to console
  fake_uart = character;
}