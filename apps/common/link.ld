/* Copyright lowRISC contributors.
   Licensed under the Apache License, Version 2.0, see LICENSE for details.
   SPDX-License-Identifier: Apache-2.0 */

OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    ram         : ORIGIN = 0x400000000, LENGTH = 2M
}

/* Stack information variables */
_stack_len     = 1M;
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

    _stack_addr = . ;
    .stack_addr : {
        QUAD(_stack_start)
    } > ram

    /* ensure there is enough room for stack */
    .stack (NOLOAD): {
        . = ALIGN(32);
        . = . + _stack_len ;
        . = ALIGN(32);
        stack = . ;
        _stack = . ;
    } > ram

    fake_uart = 0x40000004;
    control_base = 0x50000000;
    timer_control = 0x50000001;
    timer_value = 0x50000008;
}
