#include <stdint.h>

extern char fake_uart;

#define VIVADO

void _putchar(char character) {
  char *p = (char *)0xC0000008;
  while (p[0] & (1 << 3)) ;
  // send char to console
  fake_uart = character;
}