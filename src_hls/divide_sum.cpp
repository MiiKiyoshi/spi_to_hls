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
