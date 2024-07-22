#include <stdio.h>

void divide_sum(int in_val1[10], int in_val2[10], int *out_result1, int *out_result2);

int main() {
    int test_cases[][10] = {
    		{1, 2, 3, 4, 5, 60, 70, 80, 90, 100}, // in_val1
    		{10, 20, 30, 40, 50, 6, 7, 8, 9, 10 } // in_val2
    };

    int in_val1[10], in_val2[10];
    int out_result1, out_result2;

    for (int i = 0; i < 10; i++) {
        in_val1[i] = test_cases[0][i];
        in_val2[i] = test_cases[1][i];
    }

    divide_sum(in_val1, in_val2, &out_result1, &out_result2);

    printf("Test Case:\n");
    printf("  Inputs:\n");
    for (int i = 0; i < 10; i++) {
        printf("    in_val1[%d] = %d, in_val2[%d] = %d\n", i, in_val1[i], i, in_val2[i]);
    }
    printf("  Outputs:\n");
    printf("    out_result1 (cumulative sum of divisions) = %d\n", out_result1);
    printf("    out_result2 (cumulative sum of inverse divisions) = %d\n", out_result2);

    // Verification
    int expected_result1 = 0, expected_result2 = 0;
    for (int i = 0; i < 10; i++) {
        if (in_val2[i] != 0) expected_result1 += in_val1[i] / in_val2[i];
        if (in_val1[i] != 0) expected_result2 += in_val2[i] / in_val1[i];
    }
    printf("  Verification:\n");
    printf("    Expected out_result1 = %d\n", expected_result1);
    printf("    Expected out_result2 = %d\n", expected_result2);

    return 0;
}
