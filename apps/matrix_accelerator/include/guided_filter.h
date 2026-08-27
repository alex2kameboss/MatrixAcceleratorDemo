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

#ifndef GF_LANES
#define GF_LANES 16
#endif

#ifndef GF_RADIUS
#define GF_RADIUS 16
#endif

//#define GF_BOX_H (2 * GF_RADIUS + 1)
//#define GF_BOX_W (2 * GF_RADIUS + 1)
//#define GF_IN_H (GF_TILE_H + 4 * GF_RADIUS)
//#define GF_IN_W (GF_TILE_W + 4 * GF_RADIUS)
#define GF_HALO (2 * GF_RADIUS)
//#define GF_MID_H (GF_TILE_H + 2 * GF_RADIUS)
//#define GF_Y_MID (GF_IN_W + GF_LANES)
#define GF_PAD_TO_LANES(W) ((((W) + GF_LANES - 1) / GF_LANES) * GF_LANES)
//#define GF_TILES_X ((GF_RGBX_IMAGE_W + GF_TILE_W - 1) / GF_TILE_W)
//#define GF_TILES_Y ((GF_RGBX_IMAGE_H + GF_TILE_H - 1) / GF_TILE_H)
//#define GF_STORAGE_W (GF_TILES_X * GF_TILE_W)
//#define GF_STORAGE_H (GF_TILES_Y * GF_TILE_H)
//#define GF_STORAGE_WORDS (GF_STORAGE_W * GF_STORAGE_H)
//#define GF_KERNEL_W GF_PAD_TO_LANES(GF_BOX_W)

typedef struct {
    int output_x;
    int output_y;
    int raw_x;
    int raw_y;
    int raw_w;
    int raw_h;
    int pad_top;
    int pad_bottom;
    int pad_left;
    int pad_right;
} gf_tile_t;

extern int GF_RGBX_IMAGE_W, GF_RGBX_IMAGE_H;
extern int GF_TILE_W, GF_TILE_H;
extern int GF_BOX_H, GF_BOX_W, GF_KERNEL_W;
extern int GF_IN_H, GF_IN_W;
extern int GF_MID_H, GF_Y_MID;
extern int GF_TILES_X, GF_TILES_Y;
extern int GF_STORAGE_W, GF_STORAGE_H, GF_STORAGE_WORDS;

void guided_filter(
    int img_w,
    int img_h,
    int tile_w,
    int tile_h,
    int box_w,
    int box_h
);

#endif // GUIDED_FILTER_H