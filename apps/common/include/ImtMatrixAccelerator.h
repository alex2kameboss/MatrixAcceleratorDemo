#ifndef IMT_MATRIX_ACCELERATOR_H
#define IMT_MATRIX_ACCELERATOR_H

#define _STR(X) #X

#define FLUSH_D_CACHE() ({ \
    asm volatile("csrwi 0x7C1, 0"); \
    asm volatile("csrwi 0x7C1, 1");})

#define MA_DEFINE_int8_t(ID, H, W) ({ \
        asm volatile \
        ( \
            "v2ddef8 x" _STR(ID) " , %[x], %[y]\n\t" \
            : \
            : [x] "r" (H), [y] "r" (W) \
        ); \
    })

#define MA_DEFINE_uint8_t(ID, H, W) ({ \
        asm volatile \
        ( \
            "v2ddefu8 x" _STR(ID) " , %[x], %[y]\n\t" \
            : \
            : [x] "r" (H), [y] "r" (W) \
        ); \
    })

#define MA_DEFINE_int16_t(ID, H, W) ({ \
        asm volatile \
        ( \
            "v2ddef16 x" _STR(ID) " , %[x], %[y]\n\t" \
            : \
            : [x] "r" (H), [y] "r" (W) \
        ); \
    })

#define MA_DEFINE_uint16_t(ID, H, W) ({ \
        asm volatile \
        ( \
            "v2ddef16 x" _STR(ID) " , %[x], %[y]\n\t" \
            : \
            : [x] "r" (H), [y] "r" (W) \
        ); \
    })

#define MA_DEFINE_int32_t(ID, H, W) ({ \
        asm volatile \
        ( \
            "v2ddef32 x" _STR(ID) " , %[x], %[y]\n\t" \
            : \
            : [x] "r" (H), [y] "r" (W) \
        ); \
    })

#define MA_DEFINE_uint32_t(ID, H, W) ({ \
        asm volatile \
        ( \
            "v2ddefu32 x" _STR(ID) " , %[x], %[y]\n\t" \
            : \
            : [x] "r" (H), [y] "r" (W) \
        ); \
    })

#define MA_LOC_RECT(ID, X, Y) ({ \
    asm volatile \
    ( \
        "v2dloc.rect x" _STR(ID) " , %[x], %[y]\n\t" \
        : \
        : [x] "r" (X), [y] "r" (Y) \
    ); \
})

#define MA_LOAD_REGISTER(ID, PTR) ({ \
        asm volatile \
        ( \
            "v2dld x" _STR(ID) ", %[x]\n\t" \
            : \
            : [x] "o" (PTR) \
        ); \
    })

#define MA_STORE_REGISTER(ID, PTR) ({ \
        asm volatile \
        ( \
            "v2dst x" _STR(ID) ", %[x]\n\t" \
            : \
            : [x] "o" (PTR) \
        ); \
    })

#define MA_VV_ADD(RID, S1ID, S2ID) asm volatile( "v2dadd.vv x" _STR(RID) ", x" _STR(S1ID) ", x" _STR(S2ID) );
#define MA_VV_SUB(RID, S1ID, S2ID) asm volatile( "v2dsub.vv x" _STR(RID) ", x" _STR(S1ID) ", x" _STR(S2ID) );
#define MA_VV_CNV(RID, S1ID, S2ID) asm volatile( "v2dcnv.vv x" _STR(RID) ", x" _STR(S1ID) ", x" _STR(S2ID) );
#define MA_VV_DIV(RID, S1ID, S2ID) asm volatile( "v2ddiv.vv x" _STR(RID) ", x" _STR(S1ID) ", x" _STR(S2ID) );
#define MA_VV_MULT(RID, S1ID, S2ID) asm volatile( "v2dmul.vv x" _STR(RID) ", x" _STR(S1ID) ", x" _STR(S2ID) );
#define MA_VV_SMULT(RID, S1ID, S2ID) asm volatile( "v2dsmul.vv x" _STR(RID) ", x" _STR(S1ID) ", x" _STR(S2ID) );

#define MA_VS_ADD(RID, S1ID, S2) ({ \
        asm volatile \
        ( \
            "v2dadd.vs x" _STR(RID) ", x" _STR(S1ID) ", %[x]\n\t" \
            : \
            : [x] "r" (S2) \
        ); \
    })

#define MA_VS_SUB(RID, S1ID, S2) ({ \
        asm volatile \
        ( \
            "v2dsub.vs x" _STR(RID) ", x" _STR(S1ID) ", %[x]\n\t" \
            : \
            : [x] "r" (S2) \
        ); \
    })

#define MA_VS_DIV(RID, S1ID, S2) ({ \
        asm volatile \
        ( \
            "v2ddiv.vs x" _STR(RID) ", x" _STR(S1ID) ", %[x]\n\t" \
            : \
            : [x] "r" (S2) \
        ); \
    })

#define MA_VS_SLL(RID, S1ID, S2) ({ \
        asm volatile \
        ( \
            "v2dsll.vs x" _STR(RID) ", x" _STR(S1ID) ", %[x]\n\t" \
            : \
            : [x] "r" (S2) \
        ); \
    })

#define MA_VS_SRL(RID, S1ID, S2) ({ \
        asm volatile \
        ( \
            "v2dsrl.vs x" _STR(RID) ", x" _STR(S1ID) ", %[x]\n\t" \
            : \
            : [x] "r" (S2) \
        ); \
    })

#define MA_VS_SRA(RID, S1ID, S2) ({ \
        asm volatile \
        ( \
            "v2dsra.vs x" _STR(RID) ", x" _STR(S1ID) ", %[x]\n\t" \
            : \
            : [x] "r" (S2) \
        ); \
    })

#define MA_VS_MULT(RID, S1ID, S2) ({ \
        asm volatile \
        ( \
            "v2dmul.vs x" _STR(RID) ", x" _STR(S1ID) ", %[x]\n\t" \
            : \
            : [x] "r" (S2) \
        ); \
    })

#endif // IMT_MATRIX_ACCELERATOR_H