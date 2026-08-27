#ifndef SOC_METRICS_H
#define SOC_MATRIX_H

#include <stdint.h>

extern volatile char timer_control;
extern volatile uint64_t timer_value;

void start_timer();
void stop_timer();
void clear_timer();
uint64_t get_timer_value();
void print_timer_value_hex();
void print_timer_value_dec();

#endif