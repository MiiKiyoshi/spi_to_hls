// ==============================================================
// Vitis HLS - High-Level Synthesis from C, C++ and OpenCL v2023.2 (64-bit)
// Tool Version Limit: 2023.10
// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
// 
// ==============================================================
# 1 "C:/works/verilog/kria_prj/spi_add_100/src_hls/divide_sum.cpp"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "C:/works/verilog/kria_prj/spi_add_100/src_hls/divide_sum.cpp"
void divide_sum(int in_val1[10], int in_val2[10], int *out_result1, int *out_result2) {
#pragma HLS INTERFACE mode=ap_memory port=in_val1
#pragma HLS INTERFACE mode=ap_memory port=in_val2
#pragma HLS INTERFACE mode=ap_vld port=out_result1
#pragma HLS INTERFACE mode=ap_vld port=out_result2

    *out_result1 = 0;
    *out_result2 = 0;

    for (int i = 0; i < 10; i++) {
#pragma HLS PIPELINE
        if (in_val2[i] != 0) *out_result1 += in_val1[i] / in_val2[i];
        if (in_val1[i] != 0) *out_result2 += in_val2[i] / in_val1[i];
    }
}
#ifndef HLS_FASTSIM
#ifdef __cplusplus
extern "C"
#endif
void apatb_divide_sum_ir(int *, int *, int *, int *);
#ifdef __cplusplus
extern "C"
#endif
void divide_sum_hw_stub(int *in_val1, int *in_val2, int *out_result1, int *out_result2){
divide_sum(in_val1, in_val2, out_result1, out_result2);
return ;
}
#ifdef __cplusplus
extern "C"
#endif
void refine_signal_handler();
#ifdef __cplusplus
extern "C"
#endif
void apatb_divide_sum_sw(int *in_val1, int *in_val2, int *out_result1, int *out_result2){
refine_signal_handler();
apatb_divide_sum_ir(in_val1, in_val2, out_result1, out_result2);
return ;
}
#endif
# 15 "C:/works/verilog/kria_prj/spi_add_100/src_hls/divide_sum.cpp"

