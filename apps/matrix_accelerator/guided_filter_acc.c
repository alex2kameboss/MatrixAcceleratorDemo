#include "guided_filter.h"

int GF_RGBX_IMAGE_W, GF_RGBX_IMAGE_H;
int GF_TILE_W, GF_TILE_H;
int GF_BOX_H, GF_BOX_W, GF_KERNEL_W;
int GF_IN_H, GF_IN_W;
int GF_MID_H, GF_Y_MID;
int GF_TILES_X, GF_TILES_Y;
int GF_STORAGE_W, GF_STORAGE_H, GF_STORAGE_WORDS;

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

    FLUSH_D_CACHE();
}

void guided_filter(
    int img_w,
    int img_h,
    int tile_w,
    int tile_h,
    int box_w,
    int box_h
) {
    // set up
    GF_RGBX_IMAGE_W = img_w;
    GF_RGBX_IMAGE_H = img_h;
    GF_TILE_W = tile_w;
    GF_TILE_H = tile_h;
    GF_BOX_W = box_w;
    GF_BOX_H = box_h;
    // derived

    GF_IN_H = (GF_TILE_H + 4 * GF_RADIUS);
    GF_IN_W = (GF_TILE_W + 4 * GF_RADIUS);
    GF_MID_H = (GF_TILE_H + 2 * GF_RADIUS);
    GF_Y_MID = (GF_IN_W + GF_LANES);
    GF_TILES_X = ((GF_RGBX_IMAGE_W + GF_TILE_W - 1) / GF_TILE_W);
    GF_TILES_Y = ((GF_RGBX_IMAGE_H + GF_TILE_H - 1) / GF_TILE_H);
    GF_STORAGE_W = (GF_TILES_X * GF_TILE_W);
    GF_STORAGE_H = (GF_TILES_Y * GF_TILE_H);
    GF_STORAGE_WORDS = (GF_STORAGE_W * GF_STORAGE_H);
    GF_KERNEL_W = GF_PAD_TO_LANES(GF_BOX_W);

    int channel;
    int tile_y;
    int tile_x;
    uint64_t channel_tile_passes = 0;
    uint64_t tile_load_cc = 0;
    uint64_t tile_compute_cc = 0;
    uint64_t tile_store_cc = 0;

    /* TEST START */
    /* reset counters */
    reset_profile_counters();
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

                guided_filter_process_tile_i32(GF_X_CHANNEL,
                                               GF_Y_CHANNEL,
                                               GF_X_CHANNEL,
                                               GF_Y_CHANNEL,
                                               GF_X_KERNEL,
                                               GF_Y_KERNEL,
                                               GF_X_RESULT,
                                               GF_Y_RESULT);

                clear_timer();
                start_timer();
                gf_repack_output_tile(&tile, channel);
                stop_timer();
                tile_store_cc += get_timer_value();
                channel_tile_passes++;
            }
        }
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

    printf("%d,%d,%d,%d,%d,%d,%d,%d,", GF_LANES, img_w, img_h, tile_w, tile_h, box_w, box_h, channel_tile_passes);
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
}