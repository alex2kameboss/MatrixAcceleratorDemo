#include "printf.h"
#include <stdint.h>
#include <string.h>
#include "guided_filter.h"
#include "ImtMatrixAccelerator.h"



#define IMG_MAX_W 1280
#define IMG_MAX_H 720

#define TILE_SIZE 64
#define KERNEL_SIZE 33
#define STAGE_MAX_W (((IMG_MAX_W + TILE_SIZE - 1) / TILE_SIZE) * TILE_SIZE)
#define STAGE_MAX_H (((IMG_MAX_H + TILE_SIZE - 1) / TILE_SIZE) * TILE_SIZE)

#define MAX_BUFFER_SIZE 1024


volatile uint8_t *uart_rx_fifo =  (uint8_t *)0x40000000;
volatile uint8_t *uart_tx_fifo =  (uint8_t *)0x40000004;
volatile uint8_t *uart_stat_reg = (uint8_t *)0x40000008;
volatile uint8_t *uart_ctrl_reg = (uint8_t *)0x4000000C;

uint32_t bufStartsWith(uint8_t* buf, uint32_t size, const char* text) {
    uint32_t text_size = strlen(text);
    if ( text_size > size )
        return -1;

    uint32_t i =0;
    for ( i = 0; i < text_size; i++ ) {
        //printf("%c/%c\n\r", buf[i], text[i]);
        if ( buf[i] != text[i] ) {
            return -1;
        }
    }

    return i;
}

void txSendByte(const uint8_t d) {
    while (uart_stat_reg[0] & (1 << 3)) ;
    // send char to console
    uart_tx_fifo[0] = d;
}

inline bool rxAvailable() {
    return uart_stat_reg[0] & (1 << 0);
}

inline uint8_t rxReadByte() {
    while( !rxAvailable() );
    return uart_rx_fifo[0];
}

uint32_t rxReadLine(uint8_t* buf, uint32_t maxSize) {
    uint32_t idx = 0;
    char c;
    do {
        c = buf[idx++] = rxReadByte();
    } while( c != '\r' && idx != maxSize );

    buf[--idx] = 0;
    //printf("Received: %s\n\r", buf);
    return idx;
}

uint32_t waitMessage(uint8_t* buf, uint32_t maxSize, const char* msg) {
    uint32_t size, idx;
    do {
        size = rxReadLine(buf, maxSize);
    } while( (idx = bufStartsWith(buf, size, msg)) == UINT32_MAX );

    return idx;
}

int main() {
    // reset fifos
    uart_ctrl_reg[0] = 3;

    // buffers
    uint8_t buf[MAX_BUFFER_SIZE];
    uint8_t imageInBuf[STAGE_MAX_W * STAGE_MAX_H * 4] __attribute__((aligned(4096)));
    uint8_t imageOutBuf[STAGE_MAX_W * STAGE_MAX_H * 4] __attribute__((aligned(4096)));
    int32_t kernel[64 * 64] __attribute__((aligned(4096)));

    // variables
    int imageWidth, imageHeight;
    uint32_t numberStartIdx;
    int stageWidth, stageHeight, stageRowBytes;

    // assign buffers
    gf_rgbx_stage_input = (uint32_t*)imageInBuf;
    gf_rgbx_stage_output = (uint32_t*)imageOutBuf;
    gf_box_kernel = kernel;

    printf("Final demo start\n\r");

    while (1) {
        // START
        //printf("Wait start\n\r");
        waitMessage(buf, MAX_BUFFER_SIZE, "$START");
        // WIDTH
        //printf("Wait width\n\r");
        numberStartIdx = waitMessage(buf, MAX_BUFFER_SIZE, "$WIDTH");
        imageWidth = atoi(&buf[numberStartIdx]);
        //printf("width: %d\n\r", imageWidth);
        // HEIGHT
        //printf("Wait height\n\r");
        numberStartIdx = waitMessage(buf, MAX_BUFFER_SIZE, "$HEIGHT");
        imageHeight = atoi(&buf[numberStartIdx]);
        //printf("height: %d\n\r", imageHeight);
        // DATA START
        //printf("Wait data start\n\r");
        stageWidth = ((imageWidth + TILE_SIZE - 1) / TILE_SIZE) * TILE_SIZE;
        stageHeight = ((imageHeight + TILE_SIZE - 1) / TILE_SIZE) * TILE_SIZE;
        stageRowBytes = stageWidth * 4;
        waitMessage(buf, MAX_BUFFER_SIZE, "$DATA_START");
        // DATA INPUT
        //printf("Data\n\r");
        for (int y = 0; y < imageHeight; y++) {
            int rowBase = y * stageRowBytes;
            for (int x = 0; x < imageWidth * 4; x++) {
                imageInBuf[rowBase + x] = rxReadByte();
            }
            for (int x = imageWidth; x < stageWidth; x++) {
                for (int channel = 0; channel < 4; channel++) {
                    imageInBuf[rowBase + x * 4 + channel] =
                        imageInBuf[rowBase + (imageWidth - 1) * 4 + channel];
                }
            }
        }
        for (int y = imageHeight; y < stageHeight; y++) {
            int rowBase = y * stageRowBytes;
            for (int x = 0; x < stageRowBytes; x++) {
                imageInBuf[rowBase + x] = 0;
            }
        }
        for (int i = 0; i < stageHeight * stageRowBytes; i++) {
            imageOutBuf[i] = imageInBuf[i];
        }
        // DATA END
        //printf("\n\rWait data end\n\r");
        waitMessage(buf, MAX_BUFFER_SIZE, "$DATA_END");
        // EXECUTE
        FLUSH_D_CACHE();
        guided_filter_acc (
            imageWidth,
            imageHeight,
            TILE_SIZE ,
            TILE_SIZE,
            KERNEL_SIZE,
            KERNEL_SIZE,
            false
        );
        //printf("Execute\n\r");
        //for ( int i = 0; i < imageSize; ++i ) {
        //    imageOutBuf[i] = imageInBuf[i];
        //}
        printf("$RESULT_IMAGE\r\n");
        for (int y = 0; y < imageHeight; y++) {
            int rowBase = y * stageRowBytes;
            for (int x = 0; x < imageWidth * 4; x++) {
                txSendByte(imageOutBuf[rowBase + x]);
            }
        }
        printf("$RESULT_METRICS\r\n");
        printf("hw,lanes,img_w,img_h,tile_w,tile_h,box_w,box_h,#tiles,tile_load,tile_compute,tile_store,total,MA_VS_ADD,MA_VS_MULT,MA_VS_SRA,MA_VS_SRL,MA_VV_ADD,MA_VV_CNV,MA_VV_NW,MA_VV_SMULT,MA_VV_SUB,MA_DEFINE_int32_t,MA_LOC_RECT\r\n");
        print_metrics (
            imageWidth,
            imageHeight,
            TILE_SIZE ,
            TILE_SIZE,
            KERNEL_SIZE,
            KERNEL_SIZE
        );
        //printf("test,size\r\nmytest,%d\r\n", imageSize);
        printf("$END\r\n");
    }
}
