#include "guided_filter.h"
#include "printf.h"
#include "soc_metrics.h"

int main(void) {
    printf("hw,lanes,img_w,img_h,tile_w,tile_h,box_w,box_h,#tiles,tile_load,tile_compute,tile_store,total,MA_VS_ADD,MA_VS_MULT,MA_VS_SRA,MA_VS_SRL,MA_VV_ADD,MA_VV_CNV,MA_VV_NW,MA_VV_SMULT,MA_VV_SUB,MA_DEFINE_int32_t,MA_LOC_RECT\n\r");

    int image_sizes[][2] = {
//        {1280, 720},
//        {1920, 1080},
        {3840, 2160}
    };
    int tile_sizes[][3] = {
//        {32, 32},
        {64, 64}
//        {128, 128}
    };
    int kernel_sizes[] = {
//        31, 
//        33,
        35
    };

    int repetitions = 1;
    int image_case_count = sizeof(image_sizes) / sizeof(image_sizes[0]);
    int tile_case_count = sizeof(tile_sizes) / sizeof(tile_sizes[0]);
    int kernel_case_count = sizeof(kernel_sizes) / sizeof(kernel_sizes[0]);

    for (int image_case = 0; image_case < image_case_count; image_case++) {
        int img_w = image_sizes[image_case][0];
        int img_h = image_sizes[image_case][1];

        for (int tile_case = 0; tile_case < tile_case_count; tile_case++) {
            int tile_w = tile_sizes[tile_case][0];
            int tile_h = tile_sizes[tile_case][1];

            for (int kernel_case = 0; kernel_case < kernel_case_count; kernel_case++) {
                int box_w = kernel_sizes[kernel_case];
                int box_h = kernel_sizes[kernel_case];

                for (int repeat = 0; repeat < repetitions; repeat++) {
                    guided_filter_acc (
                        img_w,
                        img_h,
                        tile_w,
                        tile_h,
                        box_w,
                        box_h,
                        true
                    );

                    //guided_filter_cpu(
                    //    gf_rgbx_stage_input,
                    //    gf_rgbx_stage_output,
                    //    img_w,
                    //    img_h,
                    //    tile_w,
                    //    tile_h,
                    //    box_w,
                    //    box_h,
                    //    4
                    //);
                }
            }
        }
    }

    // call me!
    //void guided_filter(
    //int img_w,
    //int img_h,
    //int tile_w,
    //int tile_h,
    //int box_w,
    //int box_h
    //);

    printf("DONE!\n");

    return 0;
}
