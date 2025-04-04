#ifndef SOC_METRICS_H
#define SOC_MATRIX_H

#include <stdint.h>
#include "printf.h"

extern char timer_control;
extern uint64_t timer_value;

void start_timer() {
    timer_control = 0b1;
}

void stop_timer() {
    timer_control = 0b0;
}

void clear_timer() {
    timer_control = 0b10;
    timer_control = 0b00;
}

uint64_t get_timer_value() {
    return timer_value;
}

void print_timer_value_hex() {
    printf("%#016llx", timer_value);
}

void print_timer_value_dec() {
    printf("%llu", timer_value);
}

#endif