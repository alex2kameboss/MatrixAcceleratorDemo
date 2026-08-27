#ifndef GUIDED_FILTER_H
#define GUIDED_FILTER_H

#include <stdint.h>

void guided_filter_process_tile_i32(int guidance_x,
                                    int guidance_y,
                                    int input_x,
                                    int input_y,
                                    int kernel_x,
                                    int kernel_y,
                                    int output_x,
                                    int output_y);

void reset_profile_counters();

extern uint64_t MA_VS_ADD_cc;
extern uint64_t MA_VS_MULT_cc;
extern uint64_t MA_VS_SRA_cc;
extern uint64_t MA_VS_SRL_cc;
extern uint64_t MA_VV_ADD_cc;
extern uint64_t MA_VV_CNV_cc;
extern uint64_t MA_VV_NW_cc;
extern uint64_t MA_VV_SMULT_cc;
extern uint64_t MA_VV_SUB_cc;
extern uint64_t MA_DEFINE_int32_t_cc;
extern uint64_t MA_LOC_RECT_cc;

#endif // GUIDED_FILTER_H