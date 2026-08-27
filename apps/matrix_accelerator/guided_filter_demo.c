#include "guided_filter.h"
#include "ImtMatrixAccelerator.h"
#include "printf.h"
#include "soc_metrics.h"
#include "img.c"

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



uint32_t* gf_rgbx_stage_input = img_bin;
uint32_t gf_rgbx_stage_output[GF_STORAGE_WORDS] __attribute__((aligned(4096)));
uint32_t gf_rgbx_stage_width = GF_RGBX_IMAGE_W;
uint32_t gf_rgbx_stage_height = GF_RGBX_IMAGE_H;
uint32_t gf_rgbx_stage_stride = GF_STORAGE_W;
uint32_t gf_rgbx_stage_storage_height = GF_STORAGE_H;
uint32_t gf_rgbx_stage_storage_words = GF_STORAGE_WORDS;
// volatile uint32_t gf_rgbx_stage_input_loaded __attribute__((section(".gf_demo"), aligned(4))) = 0;
int32_t gf_box_kernel[GF_BOX_H * GF_KERNEL_W] __attribute__((aligned(4096)));

int main(void) {
    gf_initialize_kernel();
    printf("lanes,img_w,img_h,tile_w,tile_h,box_w,box_h,#tiles,tile_load,tile_compute,tile_store,total,MA_VS_ADD,MA_VS_MULT,MA_VS_SRA,MA_VS_SRL,MA_VV_ADD,MA_VV_CNV,MA_VV_NW,MA_VV_SMULT,MA_VV_SUB,MA_DEFINE_int32_t,MA_LOC_RECT\n\r");

    // call me!
    //void guided_filter(
    //int img_w,
    //int img_h,
    //int tile_w,
    //int tile_h,
    //int box_w,
    //int box_h
    //);

    return 0;
}
