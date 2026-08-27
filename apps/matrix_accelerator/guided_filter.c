#include "guided_filter.h"
#include "ImtMatrixAccelerator.h"
#include "soc_metrics.h"

#include "printf.h"

#ifndef GF_LANES
#define GF_LANES 16
#endif

#ifndef GF_RADIUS
#define GF_RADIUS 16
#endif

#ifndef GF_TILE_H
#define GF_TILE_H 64
#endif

#ifndef GF_TILE_W
#define GF_TILE_W 64
#endif

#ifndef GF_EPS
#define GF_EPS 4
#endif

#ifndef GF_Q_SHIFT
#define GF_Q_SHIFT 16
#endif

#define GF_BOX_H (2 * GF_RADIUS - 1)
#define GF_BOX_W (2 * GF_RADIUS - 1)
#define GF_IN_H (GF_TILE_H + 4 * GF_RADIUS)
#define GF_IN_W (GF_TILE_W + 4 * GF_RADIUS)
#define GF_MID_H (GF_TILE_H + 2 * GF_RADIUS)
#define GF_MID_W (GF_TILE_W + 2 * GF_RADIUS)
#define GF_BOX_N (GF_BOX_H * GF_BOX_W)
#define GF_INV_N_Q16 ((uint32_t)(((uint64_t)1 << GF_Q_SHIFT) / GF_BOX_N))

#define GF_R_I 0
#define GF_R_P 1
#define GF_R_BOX 2
#define GF_R_WORK 3
#define GF_R_MEAN_I 4
#define GF_R_MEAN_P 5
#define GF_R_CORR_I 6
#define GF_R_CORR_IP 7

#define GF_X_WORK 0
#define GF_Y_MID (GF_IN_W + GF_LANES)
#define GF_X_M0 0
#define GF_X_M1 GF_MID_H
#define GF_X_M2 (2 * GF_MID_H)
#define GF_X_M3 (3 * GF_MID_H)
#define GF_X_M4 (4 * GF_MID_H)

#define PROFILE_GFi32_EN 1

#if PROFILE_GFi32_EN

#define PROFILE_MA_FN(FN, ARG0, ARG1, ARG2) { \
    clear_timer(); \
    start_timer(); \
    FN(ARG0, ARG1, ARG2); \
    stop_timer(); \
    FN##_cc += get_timer_value(); \
}

#else

#define PROFILE_MA_FN(FN, ARG0, ARG1, ARG2) { \
    FN(ARG0, ARG1, ARG2); \
}

#endif

uint64_t MA_VS_ADD_cc;
uint64_t MA_VS_MULT_cc;
uint64_t MA_VS_SRA_cc;
uint64_t MA_VS_SRL_cc;
uint64_t MA_VV_ADD_cc;
uint64_t MA_VV_CNV_cc;
uint64_t MA_VV_NW_cc;
uint64_t MA_VV_SMULT_cc;
uint64_t MA_VV_SUB_cc;
uint64_t MA_DEFINE_int32_t_cc;
uint64_t MA_LOC_RECT_cc;

void reset_profile_counters() {
    MA_VS_ADD_cc = 0;
    MA_VS_MULT_cc = 0;
    MA_VS_SRA_cc = 0;
    MA_VS_SRL_cc = 0;
    MA_VV_ADD_cc = 0;
    MA_VV_CNV_cc = 0;
    MA_VV_NW_cc = 0;
    MA_VV_SMULT_cc = 0;
    MA_VV_SUB_cc = 0;
    MA_DEFINE_int32_t_cc = 0;
    MA_LOC_RECT_cc = 0;
}

void guided_filter_process_tile_i32(int guidance_x,
                                    int guidance_y,
                                    int input_x,
                                    int input_y,
                                    int kernel_x,
                                    int kernel_y,
                                    int output_x,
                                    int output_y) {
    PROFILE_MA_FN(MA_DEFINE_int32_t, GF_R_I, GF_IN_H, GF_IN_W);
    PROFILE_MA_FN(MA_LOC_RECT, GF_R_I, guidance_x, guidance_y);
    PROFILE_MA_FN(MA_DEFINE_int32_t, GF_R_P, GF_IN_H, GF_IN_W);
    PROFILE_MA_FN(MA_LOC_RECT, GF_R_P, input_x, input_y);
    PROFILE_MA_FN(MA_DEFINE_int32_t, GF_R_BOX, GF_BOX_H, GF_BOX_W);
    PROFILE_MA_FN(MA_LOC_RECT, GF_R_BOX, kernel_x, kernel_y);

    PROFILE_MA_FN(MA_DEFINE_int32_t, GF_R_CORR_IP, GF_MID_H, GF_MID_W);
    PROFILE_MA_FN(MA_LOC_RECT, GF_R_CORR_IP, GF_X_M0, GF_Y_MID);
    PROFILE_MA_FN(MA_VV_CNV, GF_R_CORR_IP, GF_R_I, GF_R_BOX);
    PROFILE_MA_FN(MA_VS_MULT, GF_R_CORR_IP, GF_R_CORR_IP, GF_INV_N_Q16);
    PROFILE_MA_FN(MA_VS_SRL, GF_R_CORR_IP, GF_R_CORR_IP, GF_Q_SHIFT);

    PROFILE_MA_FN(MA_DEFINE_int32_t, GF_R_CORR_IP, GF_MID_H, GF_MID_W);
    PROFILE_MA_FN(MA_LOC_RECT, GF_R_CORR_IP, GF_X_M1, GF_Y_MID);
    PROFILE_MA_FN(MA_VV_CNV, GF_R_CORR_IP, GF_R_P, GF_R_BOX);
    PROFILE_MA_FN(MA_VS_MULT, GF_R_CORR_IP, GF_R_CORR_IP, GF_INV_N_Q16);
    PROFILE_MA_FN(MA_VS_SRL, GF_R_CORR_IP, GF_R_CORR_IP, GF_Q_SHIFT);

    PROFILE_MA_FN(MA_DEFINE_int32_t, GF_R_WORK, GF_IN_H, GF_IN_W);
    PROFILE_MA_FN(MA_LOC_RECT, GF_R_WORK, GF_X_WORK, 0);
    PROFILE_MA_FN(MA_VV_SMULT, GF_R_WORK, GF_R_I, GF_R_I);

    PROFILE_MA_FN(MA_DEFINE_int32_t, GF_R_CORR_IP, GF_MID_H, GF_MID_W);
    PROFILE_MA_FN(MA_LOC_RECT, GF_R_CORR_IP, GF_X_M2, GF_Y_MID);
    PROFILE_MA_FN(MA_VV_CNV, GF_R_CORR_IP, GF_R_WORK, GF_R_BOX);
    PROFILE_MA_FN(MA_VS_MULT, GF_R_CORR_IP, GF_R_CORR_IP, GF_INV_N_Q16);
    PROFILE_MA_FN(MA_VS_SRL, GF_R_CORR_IP, GF_R_CORR_IP, GF_Q_SHIFT);

    PROFILE_MA_FN(MA_DEFINE_int32_t, GF_R_WORK, GF_IN_H, GF_IN_W);
    PROFILE_MA_FN(MA_LOC_RECT, GF_R_WORK, GF_X_WORK, 0);
    PROFILE_MA_FN(MA_VV_SMULT, GF_R_WORK, GF_R_I, GF_R_P);

    PROFILE_MA_FN(MA_DEFINE_int32_t, GF_R_CORR_IP, GF_MID_H, GF_MID_W);
    PROFILE_MA_FN(MA_LOC_RECT, GF_R_CORR_IP, GF_X_M3, GF_Y_MID);
    PROFILE_MA_FN(MA_VV_CNV, GF_R_CORR_IP, GF_R_WORK, GF_R_BOX);
    PROFILE_MA_FN(MA_VS_MULT, GF_R_CORR_IP, GF_R_CORR_IP, GF_INV_N_Q16);
    PROFILE_MA_FN(MA_VS_SRL, GF_R_CORR_IP, GF_R_CORR_IP, GF_Q_SHIFT);

    PROFILE_MA_FN(MA_DEFINE_int32_t, GF_R_I, GF_MID_H, GF_MID_W);
    PROFILE_MA_FN(MA_LOC_RECT, GF_R_I, GF_X_M0, GF_Y_MID);
    PROFILE_MA_FN(MA_DEFINE_int32_t, GF_R_P, GF_MID_H, GF_MID_W);
    PROFILE_MA_FN(MA_LOC_RECT, GF_R_P, GF_X_M1, GF_Y_MID);
    PROFILE_MA_FN(MA_DEFINE_int32_t, GF_R_WORK, GF_MID_H, GF_MID_W);
    PROFILE_MA_FN(MA_LOC_RECT, GF_R_WORK, GF_X_M2, GF_Y_MID);
    PROFILE_MA_FN(MA_DEFINE_int32_t, GF_R_MEAN_I, GF_MID_H, GF_MID_W);
    PROFILE_MA_FN(MA_LOC_RECT, GF_R_MEAN_I, GF_X_M3, GF_Y_MID);

    PROFILE_MA_FN(MA_DEFINE_int32_t, GF_R_MEAN_P, GF_MID_H, GF_MID_W);
    PROFILE_MA_FN(MA_LOC_RECT, GF_R_MEAN_P, GF_X_WORK, 0);
    PROFILE_MA_FN(MA_VV_SMULT, GF_R_MEAN_P, GF_R_I, GF_R_I);
    PROFILE_MA_FN(MA_DEFINE_int32_t, GF_R_CORR_I, GF_MID_H, GF_MID_W);
    PROFILE_MA_FN(MA_LOC_RECT, GF_R_CORR_I, GF_X_M4, GF_Y_MID);
    PROFILE_MA_FN(MA_VV_SUB, GF_R_CORR_I, GF_R_WORK, GF_R_MEAN_P);

    PROFILE_MA_FN(MA_DEFINE_int32_t, GF_R_WORK, GF_MID_H, GF_MID_W);
    PROFILE_MA_FN(MA_LOC_RECT, GF_R_WORK, GF_X_M2, GF_Y_MID);
    PROFILE_MA_FN(MA_VV_SMULT, GF_R_WORK, GF_R_I, GF_R_P);
    PROFILE_MA_FN(MA_DEFINE_int32_t, GF_R_MEAN_P, GF_MID_H, GF_MID_W);
    PROFILE_MA_FN(MA_LOC_RECT, GF_R_MEAN_P, GF_X_WORK, 0);
    PROFILE_MA_FN(MA_VV_SUB, GF_R_MEAN_P, GF_R_MEAN_I, GF_R_WORK);

    PROFILE_MA_FN(MA_VS_ADD, GF_R_WORK, GF_R_CORR_I, GF_EPS);
    PROFILE_MA_FN(MA_VV_NW, GF_R_MEAN_I, GF_R_MEAN_P, GF_R_WORK);

    PROFILE_MA_FN(MA_DEFINE_int32_t, GF_R_MEAN_P, GF_MID_H, GF_MID_W);
    PROFILE_MA_FN(MA_LOC_RECT, GF_R_MEAN_P, GF_X_WORK, 0);
    PROFILE_MA_FN(MA_VV_SMULT, GF_R_MEAN_P, GF_R_MEAN_I, GF_R_I);
    PROFILE_MA_FN(MA_VS_SRL, GF_R_MEAN_P, GF_R_MEAN_P, GF_Q_SHIFT);
    PROFILE_MA_FN(MA_VV_SUB, GF_R_CORR_I, GF_R_P, GF_R_MEAN_P);

    PROFILE_MA_FN(MA_DEFINE_int32_t, GF_R_CORR_IP, GF_TILE_H, GF_TILE_W);
    PROFILE_MA_FN(MA_LOC_RECT, GF_R_CORR_IP, GF_X_M0, GF_Y_MID);
    PROFILE_MA_FN(MA_VV_CNV, GF_R_CORR_IP, GF_R_MEAN_I, GF_R_BOX);
    PROFILE_MA_FN(MA_VS_MULT, GF_R_CORR_IP, GF_R_CORR_IP, GF_INV_N_Q16);
    PROFILE_MA_FN(MA_VS_SRL, GF_R_CORR_IP, GF_R_CORR_IP, GF_Q_SHIFT);

    PROFILE_MA_FN(MA_DEFINE_int32_t, GF_R_CORR_IP, GF_TILE_H, GF_TILE_W);
    PROFILE_MA_FN(MA_LOC_RECT, GF_R_CORR_IP, GF_X_M1, GF_Y_MID);
    PROFILE_MA_FN(MA_VV_CNV, GF_R_CORR_IP, GF_R_CORR_I, GF_R_BOX);
    PROFILE_MA_FN(MA_VS_MULT, GF_R_CORR_IP, GF_R_CORR_IP, GF_INV_N_Q16);
    PROFILE_MA_FN(MA_VS_SRA, GF_R_CORR_IP, GF_R_CORR_IP, GF_Q_SHIFT);

    PROFILE_MA_FN(MA_DEFINE_int32_t, GF_R_I, GF_TILE_H, GF_TILE_W);
    PROFILE_MA_FN(MA_LOC_RECT, GF_R_I, GF_X_M0, GF_Y_MID);
    PROFILE_MA_FN(MA_DEFINE_int32_t, GF_R_P, GF_TILE_H, GF_TILE_W);
    PROFILE_MA_FN(MA_LOC_RECT, GF_R_P, GF_X_M1, GF_Y_MID);
    PROFILE_MA_FN(MA_DEFINE_int32_t, GF_R_WORK, GF_TILE_H, GF_TILE_W);
    PROFILE_MA_FN(MA_LOC_RECT, GF_R_WORK, guidance_x + 2 * GF_RADIUS, guidance_y + 2 * GF_RADIUS);
    PROFILE_MA_FN(MA_DEFINE_int32_t, GF_R_MEAN_P, GF_TILE_H, GF_TILE_W);
    PROFILE_MA_FN(MA_LOC_RECT, GF_R_MEAN_P, output_x, output_y);
    PROFILE_MA_FN(MA_VV_SMULT, GF_R_MEAN_P, GF_R_I, GF_R_WORK);
    PROFILE_MA_FN(MA_VS_SRA, GF_R_MEAN_P, GF_R_MEAN_P, GF_Q_SHIFT);
    PROFILE_MA_FN(MA_VV_ADD, GF_R_MEAN_P, GF_R_MEAN_P, GF_R_P);
}
