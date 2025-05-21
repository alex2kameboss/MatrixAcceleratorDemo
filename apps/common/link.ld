/* Copyright lowRISC contributors.
   Licensed under the Apache License, Version 2.0, see LICENSE for details.
   SPDX-License-Identifier: Apache-2.0 */

OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    ram         : ORIGIN = 0x80000000, LENGTH = 0x02000000
}

/* Stack information variables */
_stack_len     = 0x4000;
_stack_start   = ORIGIN(ram) + LENGTH(ram);

SECTIONS
{
    .text : {
        . = ALIGN(32);
        *(.text)
        *(.text.*)
    }  > ram

    .rodata : {
        . = ALIGN(32);
        /* Small RO data before large RO data */
        *(.srodata)
        *(.srodata.*)
        *(.rodata);
        *(.rodata.*)
    } > ram

    .data : {
        . = ALIGN(32);
        /* Small data before large data */
        *(.sdata)
        *(.sdata.*)
        *(.data);
        *(.data.*)
    } > ram

    .bss :
    {
        . = ALIGN(32);
        _bss_start = .;
        /* Small BSS before large BSS */
        *(.sbss)
        *(.sbss.*)
        *(.bss)
        *(.bss.*)
        *(COMMON)
        _bss_end = .;
    } > ram

    /* ensure there is enough room for stack */
    .stack (NOLOAD): {
        . = ALIGN(32);
        . = . + _stack_len ;
        . = ALIGN(32);
        stack = . ;
        _stack = . ;
    } > ram

    fake_uart = 0xC0000004;
    control_base = 0xD0000000;
    timer_control = 0xD0000001;
    timer_value = 0xD0000008;
}
