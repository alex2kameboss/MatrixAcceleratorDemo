#include "guided_filter.h"
#include "soc_metrics.h"
#include "printf.h"

enum {
    GF_CPU_MAX_TILE_W = 128,
    GF_CPU_MAX_TILE_H = 128,
    GF_CPU_MAX_RADIUS = 17,
    GF_CPU_MAX_IN_W = GF_CPU_MAX_TILE_W + 4 * GF_CPU_MAX_RADIUS,
    GF_CPU_MAX_IN_H = GF_CPU_MAX_TILE_H + 4 * GF_CPU_MAX_RADIUS,
    GF_CPU_MAX_MID_W = GF_CPU_MAX_TILE_W + 2 * GF_CPU_MAX_RADIUS,
    GF_CPU_MAX_MID_H = GF_CPU_MAX_TILE_H + 2 * GF_CPU_MAX_RADIUS
};

enum {
    GF_CPU_PROFILE_UNPACK_PAD,
    GF_CPU_PROFILE_MEAN_I,
    GF_CPU_PROFILE_MEAN_P,
    GF_CPU_PROFILE_I_SQUARED,
    GF_CPU_PROFILE_CORR_I,
    GF_CPU_PROFILE_I_TIMES_P,
    GF_CPU_PROFILE_CORR_IP,
    GF_CPU_PROFILE_VAR_I,
    GF_CPU_PROFILE_COV_IP,
    GF_CPU_PROFILE_DENOMINATOR,
    GF_CPU_PROFILE_A_Q16,
    GF_CPU_PROFILE_B,
    GF_CPU_PROFILE_MEAN_A,
    GF_CPU_PROFILE_MEAN_B,
    GF_CPU_PROFILE_Q,
    GF_CPU_PROFILE_REPACK_STORE,
    GF_CPU_PROFILE_COUNT
};

int gf_cpu_tile_w;
int gf_cpu_tile_h;
int gf_cpu_box_w;
int gf_cpu_box_h;
int gf_cpu_radius;
int gf_cpu_epsilon;
int gf_cpu_q_shift;
int gf_cpu_in_w;
int gf_cpu_in_h;
int gf_cpu_mid_w;
int gf_cpu_mid_h;
uint32_t gf_cpu_inv_n_q16;

int32_t gf_cpu_guidance[GF_CPU_MAX_IN_H * GF_CPU_MAX_IN_W];
int32_t gf_cpu_input[GF_CPU_MAX_IN_H * GF_CPU_MAX_IN_W];
int32_t gf_cpu_work[GF_CPU_MAX_IN_H * GF_CPU_MAX_IN_W];
int32_t gf_cpu_mean_i[GF_CPU_MAX_MID_H * GF_CPU_MAX_MID_W];
int32_t gf_cpu_mean_p[GF_CPU_MAX_MID_H * GF_CPU_MAX_MID_W];
int32_t gf_cpu_corr_i[GF_CPU_MAX_MID_H * GF_CPU_MAX_MID_W];
int32_t gf_cpu_corr_ip[GF_CPU_MAX_MID_H * GF_CPU_MAX_MID_W];
int32_t gf_cpu_mean_a[GF_CPU_MAX_TILE_H * GF_CPU_MAX_TILE_W];
int32_t gf_cpu_mean_b[GF_CPU_MAX_TILE_H * GF_CPU_MAX_TILE_W];
uint64_t gf_cpu_profile_cycles[GF_CPU_PROFILE_COUNT];
int gf_cpu_profile_header_printed;

void gf_cpu_profile(int operation, uint64_t start_cycles) {
    stop_timer();
    gf_cpu_profile_cycles[operation] += get_timer_value() - start_cycles;
    start_timer();
}

void gf_cpu_process_tile(const uint32_t *guidance,
                         const uint32_t *input,
                         uint32_t *output,
                         int width,
                         int height,
                         int stride_words,
                         int channel,
                         int tile_row,
                         int tile_column) {
    int image_width = width;
    int image_height = height;
    int output_row = tile_row * gf_cpu_tile_h;
    int output_column = tile_column * gf_cpu_tile_w;
    int patch_row = output_row - 2 * gf_cpu_radius;
    int patch_column = output_column - 2 * gf_cpu_radius;
    int channel_shift = 8 * channel;
    uint64_t q_scale = UINT64_C(1) << gf_cpu_q_shift;
    uint32_t inv_n_q16 = gf_cpu_inv_n_q16;
    unsigned long long start_cycles;

    // Replicate top/left/right edges; preserve zero bottom padding.
    // UNPACK AND PADDING
    start_cycles = get_timer_value();
    for (int row = 0; row < gf_cpu_in_h; row++) {
        int source_row = patch_row + row;
        if (source_row < 0) source_row = 0;

        for (int column = 0; column < gf_cpu_in_w; column++) {
            int index = row * gf_cpu_in_w + column;
            if (source_row >= image_height) {
                gf_cpu_guidance[index] = 0;
                gf_cpu_input[index] = 0;
                continue;
            }

            int source_column = patch_column + column;
            if (source_column < 0) source_column = 0;
            if (source_column >= image_width) source_column = image_width - 1;
            int source_index = source_row * stride_words + source_column;
            gf_cpu_guidance[index] = (guidance[source_index] >> channel_shift) & UINT32_C(0xff);
            gf_cpu_input[index] = (input[source_index] >> channel_shift) & UINT32_C(0xff);
        }
    }
    gf_cpu_profile(GF_CPU_PROFILE_UNPACK_PAD, start_cycles);

    // MEAN_I
    start_cycles = get_timer_value();
    for (int row = 0; row < gf_cpu_mid_h; row++) {
        for (int column = 0; column < gf_cpu_mid_w; column++) {
            uint64_t sum = 0;
            for (int kernel_row = 0; kernel_row < gf_cpu_box_h; kernel_row++) {
                int index = (row + kernel_row) * gf_cpu_in_w + column;
                for (int kernel_column = 0; kernel_column < gf_cpu_box_w; kernel_column++) {
                    uint32_t value = gf_cpu_guidance[index + kernel_column];
                    sum += value;
                }
            }
            gf_cpu_mean_i[row * gf_cpu_mid_w + column] = (sum * inv_n_q16) >> gf_cpu_q_shift;
        }
    }
    gf_cpu_profile(GF_CPU_PROFILE_MEAN_I, start_cycles);

    // MEAN_P
    start_cycles = get_timer_value();
    for (int row = 0; row < gf_cpu_mid_h; row++) {
        for (int column = 0; column < gf_cpu_mid_w; column++) {
            uint64_t sum = 0;
            for (int kernel_row = 0; kernel_row < gf_cpu_box_h; kernel_row++) {
                int index = (row + kernel_row) * gf_cpu_in_w + column;
                for (int kernel_column = 0; kernel_column < gf_cpu_box_w; kernel_column++) {
                    uint32_t value = gf_cpu_input[index + kernel_column];
                    sum += value;
                }
            }
            gf_cpu_mean_p[row * gf_cpu_mid_w + column] = (sum * inv_n_q16) >> gf_cpu_q_shift;
        }
    }
    gf_cpu_profile(GF_CPU_PROFILE_MEAN_P, start_cycles);

    // I_SQUARED
    start_cycles = get_timer_value();
    for (int row = 0; row < gf_cpu_in_h; row++) {
        for (int column = 0; column < gf_cpu_in_w; column++) {
            int index = row * gf_cpu_in_w + column;
            gf_cpu_work[index] = gf_cpu_guidance[index] * gf_cpu_guidance[index];
        }
    }
    gf_cpu_profile(GF_CPU_PROFILE_I_SQUARED, start_cycles);

    // CORR_I
    start_cycles = get_timer_value();
    for (int row = 0; row < gf_cpu_mid_h; row++) {
        for (int column = 0; column < gf_cpu_mid_w; column++) {
            uint64_t sum = 0;
            for (int kernel_row = 0; kernel_row < gf_cpu_box_h; kernel_row++) {
                int index = (row + kernel_row) * gf_cpu_in_w + column;
                for (int kernel_column = 0; kernel_column < gf_cpu_box_w; kernel_column++) {
                    uint32_t value = gf_cpu_work[index + kernel_column];
                    sum += value;
                }
            }
            gf_cpu_corr_i[row * gf_cpu_mid_w + column] = (sum * inv_n_q16) >> gf_cpu_q_shift;
        }
    }
    gf_cpu_profile(GF_CPU_PROFILE_CORR_I, start_cycles);

    // I_TIMES_P
    start_cycles = get_timer_value();
    for (int row = 0; row < gf_cpu_in_h; row++) {
        for (int column = 0; column < gf_cpu_in_w; column++) {
            int index = row * gf_cpu_in_w + column;
            gf_cpu_work[index] = gf_cpu_guidance[index] * gf_cpu_input[index];
        }
    }
    gf_cpu_profile(GF_CPU_PROFILE_I_TIMES_P, start_cycles);

    // CORR_IP
    start_cycles = get_timer_value();
    for (int row = 0; row < gf_cpu_mid_h; row++) {
        for (int column = 0; column < gf_cpu_mid_w; column++) {
            uint64_t sum = 0;
            for (int kernel_row = 0; kernel_row < gf_cpu_box_h; kernel_row++) {
                int index = (row + kernel_row) * gf_cpu_in_w + column;
                for (int kernel_column = 0; kernel_column < gf_cpu_box_w; kernel_column++) {
                    uint32_t value = gf_cpu_work[index + kernel_column];
                    sum += value;
                }
            }
            gf_cpu_corr_ip[row * gf_cpu_mid_w + column] = (sum * inv_n_q16) >> gf_cpu_q_shift;
        }
    }
    gf_cpu_profile(GF_CPU_PROFILE_CORR_IP, start_cycles);

    // VAR_I
    start_cycles = get_timer_value();
    for (int row = 0; row < gf_cpu_mid_h; row++) {
        for (int column = 0; column < gf_cpu_mid_w; column++) {
            int index = row * gf_cpu_mid_w + column;
            int32_t mean_i = gf_cpu_mean_i[index];
            gf_cpu_corr_i[index] -= mean_i * mean_i;
        }
    }
    gf_cpu_profile(GF_CPU_PROFILE_VAR_I, start_cycles);

    // COV_IP
    start_cycles = get_timer_value();
    for (int row = 0; row < gf_cpu_mid_h; row++) {
        for (int column = 0; column < gf_cpu_mid_w; column++) {
            int index = row * gf_cpu_mid_w + column;
            int32_t mean_i = gf_cpu_mean_i[index];
            int32_t mean_p = gf_cpu_mean_p[index];
            gf_cpu_corr_ip[index] -= mean_i * mean_p;
        }
    }
    gf_cpu_profile(GF_CPU_PROFILE_COV_IP, start_cycles);

    // DENOMINATOR
    start_cycles = get_timer_value();
    for (int row = 0; row < gf_cpu_mid_h; row++) {
        for (int column = 0; column < gf_cpu_mid_w; column++) {
            int index = row * gf_cpu_mid_w + column;
            gf_cpu_work[index] = gf_cpu_corr_i[index] + gf_cpu_epsilon;
        }
    }
    gf_cpu_profile(GF_CPU_PROFILE_DENOMINATOR, start_cycles);

    // Keep the unsigned Q16 division and saturation used by the CPU reference.
    // A_Q16
    start_cycles = get_timer_value();
    for (int row = 0; row < gf_cpu_mid_h; row++) {
        for (int column = 0; column < gf_cpu_mid_w; column++) {
            int index = row * gf_cpu_mid_w + column;
            uint32_t denominator = gf_cpu_work[index];
            uint32_t numerator = gf_cpu_corr_ip[index];
            uint64_t quotient = numerator;

            if (denominator == 0) {
                quotient = UINT32_C(0xffff);
            } else {
                quotient = (quotient << gf_cpu_q_shift) / denominator;
                if (quotient > UINT32_C(0xffff)) quotient = UINT32_C(0xffff);
            }
            gf_cpu_corr_ip[index] = quotient;
        }
    }
    gf_cpu_profile(GF_CPU_PROFILE_A_Q16, start_cycles);

    // B
    start_cycles = get_timer_value();
    for (int row = 0; row < gf_cpu_mid_h; row++) {
        for (int column = 0; column < gf_cpu_mid_w; column++) {
            int index = row * gf_cpu_mid_w + column;
            uint32_t a_q16 = gf_cpu_corr_ip[index];
            uint32_t unsigned_mean_i = gf_cpu_mean_i[index];
            uint64_t product = a_q16;
            product *= unsigned_mean_i;
            int32_t a_mean_i = product >> gf_cpu_q_shift;
            gf_cpu_corr_i[index] = gf_cpu_mean_p[index] - a_mean_i;
        }
    }
    gf_cpu_profile(GF_CPU_PROFILE_B, start_cycles);

    // MEAN_A
    start_cycles = get_timer_value();
    for (int row = 0; row < gf_cpu_tile_h; row++) {
        for (int column = 0; column < gf_cpu_tile_w; column++) {
            uint64_t sum = 0;
            for (int kernel_row = 0; kernel_row < gf_cpu_box_h; kernel_row++) {
                int index = (row + kernel_row) * gf_cpu_mid_w + column;
                for (int kernel_column = 0; kernel_column < gf_cpu_box_w; kernel_column++) {
                    uint32_t value = gf_cpu_corr_ip[index + kernel_column];
                    sum += value;
                }
            }
            gf_cpu_mean_a[row * gf_cpu_tile_w + column] = (sum * inv_n_q16) >> gf_cpu_q_shift;
        }
    }
    gf_cpu_profile(GF_CPU_PROFILE_MEAN_A, start_cycles);

    // MEAN_B
    start_cycles = get_timer_value();
    for (int row = 0; row < gf_cpu_tile_h; row++) {
        for (int column = 0; column < gf_cpu_tile_w; column++) {
            int64_t sum = 0;
            for (int kernel_row = 0; kernel_row < gf_cpu_box_h; kernel_row++) {
                int index = (row + kernel_row) * gf_cpu_mid_w + column;
                for (int kernel_column = 0; kernel_column < gf_cpu_box_w; kernel_column++) {
                    sum += gf_cpu_corr_i[index + kernel_column];
                }
            }

            int index = row * gf_cpu_tile_w + column;
            int64_t scaled = sum * inv_n_q16;
            if (scaled >= 0) {
                uint64_t positive = scaled;
                gf_cpu_mean_b[index] = positive >> gf_cpu_q_shift;
            } else {
                uint64_t magnitude = -scaled;
                int32_t rounded = (magnitude + q_scale - 1) >> gf_cpu_q_shift;
                gf_cpu_mean_b[index] = -rounded;
            }
        }
    }
    gf_cpu_profile(GF_CPU_PROFILE_MEAN_B, start_cycles);

    // q = mean(a) * I_crop + mean(b); round negative products toward minus infinity.
    // Q
    start_cycles = get_timer_value();
    for (int row = 0; row < gf_cpu_tile_h; row++) {
        for (int column = 0; column < gf_cpu_tile_w; column++) {
            int index = row * gf_cpu_tile_w + column;
            int crop_index = (row + 2 * gf_cpu_radius) * gf_cpu_in_w + column + 2 * gf_cpu_radius;
            int64_t product = gf_cpu_mean_a[index];
            product *= gf_cpu_guidance[crop_index];
            int32_t scaled;

            if (product >= 0) {
                uint64_t positive = product;
                scaled = positive >> gf_cpu_q_shift;
            } else {
                uint64_t magnitude = -product;
                int32_t rounded = (magnitude + q_scale - 1) >> gf_cpu_q_shift;
                scaled = -rounded;
            }
            gf_cpu_work[index] = scaled + gf_cpu_mean_b[index];
        }
    }
    gf_cpu_profile(GF_CPU_PROFILE_Q, start_cycles);

    // Preserve X and the other RGB bytes.
    uint32_t channel_mask = UINT32_C(0xff) << channel_shift;
    // REPACK AND STORE OUTPUT
    start_cycles = get_timer_value();
    for (int row = 0; row < gf_cpu_tile_h; row++) {
        for (int column = 0; column < gf_cpu_tile_w; column++) {
            int index = (output_row + row) * stride_words + output_column + column;
            uint32_t value = gf_cpu_work[row * gf_cpu_tile_w + column];
            value &= UINT32_C(0xff);
            uint32_t packed = (channel == 0) ? input[index] : output[index];
            output[index] = (packed & ~channel_mask) | (value << channel_shift);
        }
    }
    gf_cpu_profile(GF_CPU_PROFILE_REPACK_STORE, start_cycles);
}

int guided_filter_cpu(const uint32_t *input,
                      uint32_t *output,
                      int img_w,
                      int img_h,
                      int tile_w,
                      int tile_h,
                      int box_w,
                      int box_h,
                      int epsilon) {
    uint64_t in_w;
    uint64_t in_h;
    uint64_t mid_w;
    uint64_t mid_h;
    uint64_t box_area;
    int image_width;
    int image_height;
    int tiles_x = (img_w + tile_w - 1) / tile_w;
    int tiles_y = (img_h + tile_h - 1) / tile_h;
    uint64_t channel_tile_passes;
    uint64_t tile_load_cc;
    uint64_t tile_compute_cc;
    uint64_t tile_store_cc;
    int radius = (box_w - 1) / 2;

    int stride = tiles_x * tile_w;

    in_w = (uint64_t)tile_w + 4 * (uint64_t)radius;
    in_h = (uint64_t)tile_h + 4 * (uint64_t)radius;
    mid_w = in_w - (uint64_t)box_w + 1;
    mid_h = in_h - (uint64_t)box_h + 1;
    box_area = (uint64_t)box_w * (uint64_t)box_h;

    gf_cpu_tile_w = tile_w;
    gf_cpu_tile_h = tile_h;
    gf_cpu_box_w = box_w;
    gf_cpu_box_h = box_h;
    gf_cpu_radius = radius;
    gf_cpu_epsilon = epsilon;
    gf_cpu_q_shift = 16;
    gf_cpu_in_w = (int)in_w;
    gf_cpu_in_h = (int)in_h;
    gf_cpu_mid_w = (int)mid_w;
    gf_cpu_mid_h = (int)mid_h;
    gf_cpu_inv_n_q16 = (uint32_t)((UINT64_C(1) << gf_cpu_q_shift) /
                                  box_area);

    image_width = img_w;
    image_height = img_h;
    tiles_x = (image_width + gf_cpu_tile_w - 1) / gf_cpu_tile_w;
    tiles_y = (image_height + gf_cpu_tile_h - 1) / gf_cpu_tile_h;

    for (int operation = 0; operation < GF_CPU_PROFILE_COUNT; operation++) {
        gf_cpu_profile_cycles[operation] = 0;
    }

    clear_timer();
    start_timer();

    for (int channel = 0; channel < 3; channel++) {
        stop_timer();
        //printf("cpu_progress channel=%d/3 start\n", channel + 1);
        start_timer();
        for (int tile_row = 0; tile_row < tiles_y; tile_row++) {
            for (int tile_column = 0; tile_column < tiles_x; tile_column++) {
                gf_cpu_process_tile(input, input, output, img_w, img_h, stride,
                                    channel, tile_row, tile_column);
            }
        }
        stop_timer();
        //printf("cpu_progress channel=%d/3 done\n", channel + 1);
        start_timer();
    }

    channel_tile_passes = (uint64_t)tiles_x * (uint64_t)tiles_y * UINT64_C(3);
    tile_load_cc = gf_cpu_profile_cycles[GF_CPU_PROFILE_UNPACK_PAD];
    tile_store_cc = gf_cpu_profile_cycles[GF_CPU_PROFILE_REPACK_STORE];
    tile_compute_cc = 0;
    for (int operation = GF_CPU_PROFILE_MEAN_I;
         operation < GF_CPU_PROFILE_REPACK_STORE;
         operation++) {
        tile_compute_cc += gf_cpu_profile_cycles[operation];
    }

    stop_timer();
    //if (gf_cpu_profile_header_printed == 0) {
    //    printf("lanes,img_w,img_h,stride,tile_w,tile_h,box_w,box_h,radius,"
    //           "epsilon,#tiles,tile_load,tile_compute,tile_store,total\n\r");
    //    gf_cpu_profile_header_printed = 1;
    //}
    printf("cpu,N/A,%d,%d,%d,%d,%d,%d,%d,%d,%d,%llu,",
           img_w, img_h, stride, tile_w, tile_h, box_w, box_h,
           radius, epsilon, channel_tile_passes);
    printf("%llu,%llu,%llu,%llu,",
           tile_load_cc,
           tile_compute_cc,
           tile_store_cc,
           tile_load_cc + tile_compute_cc + tile_store_cc);
    //printf("%llu,%llu,%llu,%llu,%llu,%llu,%llu,%llu,%llu,%llu,%llu,%llu,"
    //       "%llu,%llu,%llu,%llu\n\r",
    //       gf_cpu_profile_cycles[GF_CPU_PROFILE_UNPACK_PAD],
    //       gf_cpu_profile_cycles[GF_CPU_PROFILE_MEAN_I],
    //       gf_cpu_profile_cycles[GF_CPU_PROFILE_MEAN_P],
    //       gf_cpu_profile_cycles[GF_CPU_PROFILE_I_SQUARED],
    //       gf_cpu_profile_cycles[GF_CPU_PROFILE_CORR_I],
    //       gf_cpu_profile_cycles[GF_CPU_PROFILE_I_TIMES_P],
    //       gf_cpu_profile_cycles[GF_CPU_PROFILE_CORR_IP],
    //       gf_cpu_profile_cycles[GF_CPU_PROFILE_VAR_I],
    //       gf_cpu_profile_cycles[GF_CPU_PROFILE_COV_IP],
    //       gf_cpu_profile_cycles[GF_CPU_PROFILE_DENOMINATOR],
    //       gf_cpu_profile_cycles[GF_CPU_PROFILE_A_Q16],
    //       gf_cpu_profile_cycles[GF_CPU_PROFILE_B],
    //       gf_cpu_profile_cycles[GF_CPU_PROFILE_MEAN_A],
    //       gf_cpu_profile_cycles[GF_CPU_PROFILE_MEAN_B],
    //       gf_cpu_profile_cycles[GF_CPU_PROFILE_Q],
    //       gf_cpu_profile_cycles[GF_CPU_PROFILE_REPACK_STORE]);

    return 0;
}
