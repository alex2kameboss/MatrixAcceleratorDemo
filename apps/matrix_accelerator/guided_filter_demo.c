#include "guided_filter.h"
#include "ImtMatrixAccelerator.h"
#include "printf.h"
#include "soc_metrics.h"
#include "img.c"

#ifndef GF_LANES
#define GF_LANES 16
#endif

#ifndef GF_RADIUS
#define GF_RADIUS 16
#endif

#ifndef GF_TILE_H
#define GF_TILE_H 128
#endif

#ifndef GF_TILE_W
#define GF_TILE_W 128
#endif

#ifndef GF_RGBX_IMAGE_W
#define GF_RGBX_IMAGE_W 769
#endif

#ifndef GF_RGBX_IMAGE_H
#define GF_RGBX_IMAGE_H 432
#endif

#ifndef GF_RGBX_CLOCK_HZ
#define GF_RGBX_CLOCK_HZ UINT64_C(100000000)
#endif

#define GF_BOX_H (2 * GF_RADIUS + 1)
#define GF_BOX_W (2 * GF_RADIUS + 1)
#define GF_IN_H (GF_TILE_H + 4 * GF_RADIUS)
#define GF_IN_W (GF_TILE_W + 4 * GF_RADIUS)
#define GF_HALO (2 * GF_RADIUS)
#define GF_MID_H (GF_TILE_H + 2 * GF_RADIUS)
#define GF_Y_MID (GF_IN_W + GF_LANES)
#define GF_PAD_TO_LANES(W) ((((W) + GF_LANES - 1) / GF_LANES) * GF_LANES)
#define GF_TILES_X ((GF_RGBX_IMAGE_W + GF_TILE_W - 1) / GF_TILE_W)
#define GF_TILES_Y ((GF_RGBX_IMAGE_H + GF_TILE_H - 1) / GF_TILE_H)
#define GF_STORAGE_W (GF_TILES_X * GF_TILE_W)
#define GF_STORAGE_H (GF_TILES_Y * GF_TILE_H)
#define GF_STORAGE_WORDS (GF_STORAGE_W * GF_STORAGE_H)
#define GF_KERNEL_W GF_PAD_TO_LANES(GF_BOX_W)
#define GF_INPUT_LOADED_MAGIC UINT32_C(0x47524658)

#define GF_R_I 0
#define GF_R_P 1
#define GF_R_BOX 2
#define GF_R_MEAN_P 5
#define GF_R_CORR_IP 7

#define GF_X_C0 0
#define GF_X_C1 GF_TILE_H
#define GF_X_C2 (2 * GF_TILE_H)
#define GF_X_C3 (3 * GF_TILE_H)
#define GF_X_ACC (4 * GF_TILE_H)
#define GF_X_SHIFTED (5 * GF_TILE_H)
#define GF_X_CHANNEL 512
#define GF_Y_CHANNEL 0
#define GF_X_PACKED 640
#define GF_X_TEMP 768
#define GF_X_KERNEL (GF_X_TEMP + GF_IN_H)
#define GF_Y_KERNEL 0
#define GF_X_RESULT (2 * GF_MID_H)
#define GF_Y_RESULT GF_Y_MID

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

uint32_t* gf_rgbx_stage_input = img_bin;
uint32_t gf_rgbx_stage_output[GF_STORAGE_WORDS] __attribute__((aligned(4096)));
uint32_t gf_rgbx_stage_width = GF_RGBX_IMAGE_W;
uint32_t gf_rgbx_stage_height = GF_RGBX_IMAGE_H;
uint32_t gf_rgbx_stage_stride = GF_STORAGE_W;
uint32_t gf_rgbx_stage_storage_height = GF_STORAGE_H;
uint32_t gf_rgbx_stage_storage_words = GF_STORAGE_WORDS;
// volatile uint32_t gf_rgbx_stage_input_loaded __attribute__((section(".gf_demo"), aligned(4))) = 0;
int32_t gf_box_kernel[GF_BOX_H * GF_KERNEL_W] __attribute__((aligned(4096)));

int gf_min(int a, int b) {
    return (a < b) ? a : b;
}

int gf_max(int a, int b) {
    return (a > b) ? a : b;
}

int gf_clamp(int value, int low, int high) {
    return gf_min(gf_max(value, low), high);
}

int gf_describe_tile(gf_tile_t *tile, int tile_y, int tile_x) {
    int patch_x = tile_x * GF_TILE_W - GF_HALO;
    int patch_y = tile_y * GF_TILE_H - GF_HALO;
    int raw_x1;
    int raw_y1;

    tile->output_x = tile_x * GF_TILE_W;
    tile->output_y = tile_y * GF_TILE_H;
    tile->raw_x = gf_clamp(patch_x, 0, GF_RGBX_IMAGE_W);
    tile->raw_y = gf_clamp(patch_y, 0, GF_RGBX_IMAGE_H);
    raw_x1 = gf_clamp(patch_x + GF_IN_W, 0, GF_RGBX_IMAGE_W);
    raw_y1 = gf_clamp(patch_y + GF_IN_H, 0, GF_RGBX_IMAGE_H);
    tile->raw_w = raw_x1 - tile->raw_x;
    tile->raw_h = raw_y1 - tile->raw_y;
    tile->pad_left = tile->raw_x - patch_x;
    tile->pad_top = tile->raw_y - patch_y;
    tile->pad_right = GF_IN_W - tile->pad_left - tile->raw_w;
    tile->pad_bottom = GF_IN_H - tile->pad_top - tile->raw_h;

    return (tile->raw_w > 0 && tile->raw_h > 0) ? 0 : -1;
}

void gf_initialize_kernel(void) {
    int row;
    int column;

    for (row = 0; row < GF_BOX_H; row++) {
        for (column = 0; column < GF_KERNEL_W; column++) {
            gf_box_kernel[row * GF_KERNEL_W + column] =
                (column < GF_BOX_W) ? 1 : 0;
        }
    }

    MA_DEFINE_int32_t(GF_R_BOX, GF_BOX_H, GF_KERNEL_W);
    MA_LOC_RECT(GF_R_BOX, GF_X_KERNEL, GF_Y_KERNEL);
    MA_LOAD_REGISTER(GF_R_BOX, gf_box_kernel[0]);
}

void gf_load_packed_patch(const gf_tile_t *tile) {
    int row;
    int load_width = GF_PAD_TO_LANES(tile->raw_w);

    for (row = 0; row < tile->raw_h; row++) {
        int source_index =
            (tile->raw_y + row) * GF_STORAGE_W + tile->raw_x;

        MA_DEFINE_uint32_t(31, 1, load_width);
        MA_LOC_RECT(31, GF_X_PACKED + tile->pad_top + row, tile->pad_left);
        MA_LOAD_REGISTER(31, gf_rgbx_stage_input[source_index]);
    }
}

void gf_pad_packed_patch(const gf_tile_t *tile) {
    int row;

    if (tile->pad_left > 0) {
        MA_DEFINE_uint32_t(GF_R_MEAN_P, tile->raw_h, tile->raw_w);
        MA_LOC_RECT(GF_R_MEAN_P,
                    GF_X_PACKED + tile->pad_top,
                    tile->pad_left);
        MA_DEFINE_uint32_t(GF_R_CORR_IP, tile->raw_h, tile->pad_left);
        MA_LOC_RECT(GF_R_CORR_IP, GF_X_PACKED + tile->pad_top, 0);
        MA_VV_BC_L(GF_R_CORR_IP, GF_R_MEAN_P);
    }

    if (tile->pad_right > 0) {
        MA_DEFINE_uint32_t(GF_R_MEAN_P, tile->raw_h, tile->raw_w);
        MA_LOC_RECT(GF_R_MEAN_P,
                    GF_X_PACKED + tile->pad_top,
                    tile->pad_left);
        MA_DEFINE_uint32_t(GF_R_CORR_IP, tile->raw_h, tile->pad_right);
        MA_LOC_RECT(GF_R_CORR_IP,
                    GF_X_PACKED + tile->pad_top,
                    tile->pad_left + tile->raw_w);
        MA_VV_BC_R(GF_R_CORR_IP, GF_R_MEAN_P);
    }

    for (row = 0; row < tile->pad_top; row++) {
        MA_DEFINE_uint32_t(GF_R_MEAN_P, 1, GF_IN_W);
        MA_LOC_RECT(GF_R_MEAN_P, GF_X_PACKED + tile->pad_top, 0);
        MA_DEFINE_uint32_t(GF_R_CORR_IP, 1, GF_IN_W);
        MA_LOC_RECT(GF_R_CORR_IP, GF_X_PACKED + row, 0);
        MA_VS_ADD(GF_R_CORR_IP, GF_R_MEAN_P, 0);
    }

    if (tile->pad_bottom > 0) {
        int source_x = GF_X_PACKED + tile->pad_top + tile->raw_h - 1;
        int destination_x = GF_X_PACKED + tile->pad_top + tile->raw_h;

        for (row = 0; row < tile->pad_bottom; row++) {
            MA_DEFINE_uint32_t(GF_R_MEAN_P, 1, GF_IN_W);
            MA_LOC_RECT(GF_R_MEAN_P, source_x, 0);
            MA_DEFINE_uint32_t(GF_R_CORR_IP, 1, GF_IN_W);
            MA_LOC_RECT(GF_R_CORR_IP, destination_x + row, 0);
            MA_VS_ADD(GF_R_CORR_IP, GF_R_MEAN_P, 0);
        }

        MA_DEFINE_uint32_t(GF_R_CORR_IP, tile->pad_bottom, GF_IN_W);
        MA_LOC_RECT(GF_R_CORR_IP, destination_x, 0);
        MA_VV_SUB(GF_R_CORR_IP, GF_R_CORR_IP, GF_R_CORR_IP);
    }
}

void gf_extract_channel(int source_x,
                        int source_y,
                        int height,
                        int width,
                        int channel,
                        int destination_x,
                        int destination_y) {
    int left_shift = 24 - 8 * channel;

    MA_DEFINE_uint32_t(GF_R_I, height, width);
    MA_LOC_RECT(GF_R_I, source_x, source_y);
    MA_DEFINE_uint32_t(GF_R_CORR_IP, height, width);
    MA_LOC_RECT(GF_R_CORR_IP, destination_x, destination_y);

    if (channel == 3) {
        MA_VS_SRL(GF_R_CORR_IP, GF_R_I, 24);
    } else {
        MA_DEFINE_uint32_t(GF_R_MEAN_P, height, width);
        MA_LOC_RECT(GF_R_MEAN_P, GF_X_TEMP, 0);
        MA_VS_SLL(GF_R_MEAN_P, GF_R_I, left_shift);
        MA_VS_SRL(GF_R_CORR_IP, GF_R_MEAN_P, 24);
    }
}

void gf_load_output_tile(const gf_tile_t *tile) {
    int row;

    for (row = 0; row < GF_TILE_H; row++) {
        int output_index =
            (tile->output_y + row) * GF_STORAGE_W + tile->output_x;

        MA_DEFINE_uint32_t(31, 1, GF_TILE_W);
        MA_LOC_RECT(31, GF_X_PACKED + row, 0);
        MA_LOAD_REGISTER(31, gf_rgbx_stage_output[output_index]);
    }
}

void gf_add_shifted_plane(int source_x, int shift) {
    MA_DEFINE_uint32_t(GF_R_P, GF_TILE_H, GF_TILE_W);
    MA_LOC_RECT(GF_R_P, source_x, 0);

    if (shift == 0) {
        MA_VV_ADD(GF_R_CORR_IP, GF_R_CORR_IP, GF_R_P);
    } else {
        MA_DEFINE_uint32_t(GF_R_MEAN_P, GF_TILE_H, GF_TILE_W);
        MA_LOC_RECT(GF_R_MEAN_P, GF_X_SHIFTED, 0);
        MA_VS_SLL(GF_R_MEAN_P, GF_R_P, shift);
        MA_VV_ADD(GF_R_CORR_IP, GF_R_CORR_IP, GF_R_MEAN_P);
    }
}

void gf_repack_output_tile(const gf_tile_t *tile, int channel) {
    const int plane_x[4] = {GF_X_C0, GF_X_C1, GF_X_C2, GF_X_C3};
    int preserved_channel;
    int row;

    gf_load_output_tile(tile);
    for (preserved_channel = 0; preserved_channel < 4; preserved_channel++) {
        if (preserved_channel != channel) {
            gf_extract_channel(GF_X_PACKED,
                               0,
                               GF_TILE_H,
                               GF_TILE_W,
                               preserved_channel,
                               plane_x[preserved_channel],
                               0);
        }
    }

    MA_DEFINE_uint32_t(GF_R_I, GF_TILE_H, GF_TILE_W);
    MA_LOC_RECT(GF_R_I, GF_X_RESULT, GF_Y_RESULT);
    MA_DEFINE_uint32_t(GF_R_CORR_IP, GF_TILE_H, GF_TILE_W);
    MA_LOC_RECT(GF_R_CORR_IP, GF_X_ACC, 0);
    if (channel == 0) {
        MA_VS_ADD(GF_R_CORR_IP, GF_R_I, 0);
    } else {
        MA_VS_SLL(GF_R_CORR_IP, GF_R_I, 8 * channel);
    }

    for (preserved_channel = 0; preserved_channel < 4; preserved_channel++) {
        if (preserved_channel != channel) {
            gf_add_shifted_plane(plane_x[preserved_channel],
                                 8 * preserved_channel);
        }
    }

    for (row = 0; row < GF_TILE_H; row++) {
        int output_index =
            (tile->output_y + row) * GF_STORAGE_W + tile->output_x;

        MA_DEFINE_uint32_t(31, 1, GF_TILE_W);
        MA_LOC_RECT(31, GF_X_ACC + row, 0);
        MA_STORE_REGISTER(31, gf_rgbx_stage_output[output_index]);
    }

    asm volatile("" ::: "memory");
    FLUSH_D_CACHE();
    asm volatile("" ::: "memory");
}

uint64_t tile_load_cc;
uint64_t tile_compute_cc;
uint64_t tile_store_cc;

int main(void) {
    int channel;
    int tile_y;
    int tile_x;
    int channel_tile_passes = 0;
    uint64_t cycles = 0;
    uint64_t pixels = (uint64_t)GF_RGBX_IMAGE_W * GF_RGBX_IMAGE_H;
    uint64_t cycles_per_rgb_pixel_x1000;
    uint64_t throughput_mpix_s_x1000;

    printf("lanes,img_w,img_h,tile_w,tile_h,tile_load,tile_compute,tile_store,total,MA_VS_ADD,MA_VS_MULT,MA_VS_SRA,MA_VS_SRL,MA_VV_ADD,MA_VV_CNV,MA_VV_NW,MA_VV_SMULT,MA_VV_SUB,MA_DEFINE_int32_t,MA_LOC_RECT\n\r");

    //if (gf_rgbx_stage_input_loaded != GF_INPUT_LOADED_MAGIC) {
    //    printf("guided_filter_done status=2 reason=rgbx_input_not_loaded\n\r");
    //    return 2;
    //}

    //printf("guided_filter packed RGBX full-color test start\n\r");
    //printf("image=%dx%d storage=%dx%d tiles=%dx%d patch=%dx%d "
    //       "output=%dx%d lanes=%d\n\r",
    //       GF_RGBX_IMAGE_W,
    //       GF_RGBX_IMAGE_H,
    //       GF_STORAGE_W,
    //       GF_STORAGE_H,
    //       GF_TILES_X,
    //       GF_TILES_Y,
    //       GF_IN_W,
    //       GF_IN_H,
    //       GF_TILE_W,
    //       GF_TILE_H,
    //       GF_LANES);

    gf_initialize_kernel();
    // cahe-ul e write through, la scris e ok
    //asm volatile("" ::: "memory");
    //FLUSH_D_CACHE();
    //asm volatile("" ::: "memory");

    //printf("ch,x,y,gf_load_packed_patch,gf_pad_packed_patch,gf_extract_channel,guided_filter_process_tile_i32,gf_repack_output_tile\n\r");
    /* TEST START */
    /* reset counters */
    reset_profile_counters();
    tile_load_cc = 0;
    tile_compute_cc = 0;
    tile_store_cc = 0;
    for (channel = 0; channel < 3; channel++) {
        for (tile_y = 0; tile_y < GF_TILES_Y; tile_y++) {
            for (tile_x = 0; tile_x < GF_TILES_X; tile_x++) {
                //printf("ch,x,y:%d,%d,%d\n\r", channel, tile_y, tile_x);
                gf_tile_t tile;

                if (gf_describe_tile(&tile, tile_y, tile_x) != 0) {
                    printf("guided_filter_done status=3 reason=invalid_tile\n\r");
                    return 3;
                }

                clear_timer();
                start_timer();
                gf_load_packed_patch(&tile);
                gf_pad_packed_patch(&tile);
                gf_extract_channel(GF_X_PACKED,
                    0,
                    GF_IN_H,
                    GF_IN_W,
                    channel,
                    GF_X_CHANNEL,
                    GF_Y_CHANNEL);
                stop_timer();
                tile_load_cc += get_timer_value();
                //print_timer_value_dec(); printf(",");

                //clear_timer();
                //start_timer();
                guided_filter_process_tile_i32(GF_X_CHANNEL,
                                               GF_Y_CHANNEL,
                                               GF_X_CHANNEL,
                                               GF_Y_CHANNEL,
                                               GF_X_KERNEL,
                                               GF_Y_KERNEL,
                                               GF_X_RESULT,
                                               GF_Y_RESULT);
                //stop_timer();
                //cycles += get_timer_value();
                //print_timer_value_dec(); printf(",");

                clear_timer();
                start_timer();
                gf_repack_output_tile(&tile, channel);
                stop_timer();
                tile_store_cc += get_timer_value();
                //cycles += get_timer_value();
                //print_timer_value_dec(); printf("\n\r");
                channel_tile_passes++;
                //printf("=== RGBX channel=%d tile=(%d,%d) done errors=0 ===\n\r", channel, tile_y, tile_x);
            }
        }
        //printf("=== RGB channel=%d done cumulative_errors=0 ===\n\r", channel);
    }
    tile_compute_cc = 
                    MA_VS_ADD_cc + 
                    MA_VS_MULT_cc + 
                    MA_VS_SRA_cc + 
                    MA_VS_SRL_cc + 
                    MA_VV_ADD_cc + 
                    MA_VV_CNV_cc + 
                    MA_VV_NW_cc + 
                    MA_VV_SMULT_cc + 
                    MA_VV_SUB_cc + 
                    MA_DEFINE_int32_t_cc + 
                    MA_LOC_RECT_cc;

    //printf("lanes,img_w,img_h,tile_w,tile_h,tile_load,tile_compute,tile_store,total,MA_VS_ADD,MA_VS_MULT,MA_VS_SRA,MA_VS_SRL,MA_VV_ADD,MA_VV_CNV,MA_VV_NW,MA_VV_SMULT,MA_VV_SUB,MA_DEFINE_int32_t,MA_LOC_RECT\n\r");
    printf("%d,%d,%d,%d,%d,", GF_LANES, GF_RGBX_IMAGE_W, GF_RGBX_IMAGE_H, GF_TILE_H, GF_TILE_W);
    printf("%llu,%llu,%llu,%llu,", tile_load_cc, tile_compute_cc, tile_store_cc, tile_load_cc + tile_compute_cc + tile_store_cc);
    printf("%llu,%llu,%llu,%llu,%llu,%llu,%llu,%llu,%llu,%llu,%llu\n\r",
        MA_VS_ADD_cc,
        MA_VS_MULT_cc,
        MA_VS_SRA_cc,
        MA_VS_SRL_cc,
        MA_VV_ADD_cc,
        MA_VV_CNV_cc,
        MA_VV_NW_cc,
        MA_VV_SMULT_cc,
        MA_VV_SUB_cc,
        MA_DEFINE_int32_t_cc,
        MA_LOC_RECT_cc);
    /* TEST END */

    //if (cycles == 0) {
    //    cycles = 1;
    //}
    //cycles_per_rgb_pixel_x1000 = (cycles * UINT64_C(1000)) / pixels;
    //throughput_mpix_s_x1000 =
    //    (pixels * GF_RGBX_CLOCK_HZ) / (cycles * UINT64_C(1000));
//
    //printf("hardware_metrics pixels=%llu channels=3 channel_tile_passes=%d "
    //       "cycles=%llu clock_hz=%llu cycles_per_rgb_pixel=%llu.%03llu "
    //       "throughput_mpix_s=%llu.%03llu\n\r",
    //       pixels,
    //       channel_tile_passes,
    //       cycles,
    //       (uint64_t)GF_RGBX_CLOCK_HZ,
    //       cycles_per_rgb_pixel_x1000 / 1000,
    //       cycles_per_rgb_pixel_x1000 % 1000,
    //       throughput_mpix_s_x1000 / 1000,
    //       throughput_mpix_s_x1000 % 1000);
    //printf("packed samples first=%x middle=%x last=%x\n\r",
    //       gf_rgbx_stage_output[0],
    //       gf_rgbx_stage_output[(GF_RGBX_IMAGE_H / 2) * GF_STORAGE_W +
    //                            GF_RGBX_IMAGE_W / 2],
    //       gf_rgbx_stage_output[(GF_RGBX_IMAGE_H - 1) * GF_STORAGE_W +
    //                            GF_RGBX_IMAGE_W - 1]);
    //printf("guided_filter packed RGBX full-color test done "
    //       "pixels=%llu channels=3 q_tiles=%d r_stage_checks=0 errors=0\n\r",
    //       pixels,
    //       channel_tile_passes);
    //printf("guided_filter_done status=0\n\r");
    return 0;
}
