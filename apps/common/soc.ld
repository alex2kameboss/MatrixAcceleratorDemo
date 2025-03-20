OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY {
  RAM : ORIGIN = 0x80000000, LENGTH = 0x02000000
}

SECTIONS {
  .text : {
    *(.text.init)
    *(.text)
    *(.text.*)
  } > RAM

  .data : ALIGN(16) {
    *(.data)
    *(.data.*)
  } > RAM

  .rodata  : ALIGN(16) { *(.rodata .rodata.* .gnu.linkonce.r.*) } > RAM
  .rodata1 : ALIGN(16) { *(.rodata1) } > RAM
  .sdata2  : ALIGN(16) {
    *(.sdata2 .sdata2.* .gnu.linkonce.s2.*)
  } > RAM

  .sdata   : ALIGN(16) {
    __global_pointer$ = . + 0x800;
    *(.srodata.cst16) *(.srodata.cst8) *(.srodata.cst4) *(.srodata.cst2) *(.srodata .srodata.*)
    *(.sdata .sdata.* .gnu.linkonce.s.*)
  } > RAM

  .bss : ALIGN(16) {
    __bss_start = .;
    *(.bss)
    *(.sbss .sbss.* .sbss2 .sbss2.* .gnu.linkonce.sb2.*);
    __bss_end = .;
  } > RAM

  .ram : ALIGN(16) {
    *(.ram)
    timer = .;
    . = . + 0x8;
    ram_alloc_base = ALIGN(16);
  } > RAM

  .comment : ALIGN(16) { *(.comment) } > RAM

  fake_uart              = 0xC0000004;
}