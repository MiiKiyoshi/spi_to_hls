#include <stdio.h>
#include <unistd.h>
#include "spi_to_hls_driver.h"

void clearScreen() {
    printf("\033[2J");
    printf("\033[H");
    fflush(stdout);
}

void printStatus() {
    clearScreen();

    printf("SPI to HLS Status Monitor\n");
    printf("-------------------------\n\n");

    // System Control and SPI Status
    uint32_t systemControl = SYSTEM_CONTROL;
    uint32_t spiStatus = SPI_STATUS;
    printf("Reset=%lu\n", systemControl & 0x1);
    printf("Store Word=%lu, Vals=%lu, Load=%lu, Byte=%lu, StAddr=%lu, LdAddr=%lu, State=%lu\n",
           (spiStatus >> 18) & 1, (spiStatus >> 17) & 1, (spiStatus >> 16) & 1,
           (spiStatus >> 10) & 3, (spiStatus >> 6) & 0xF, (spiStatus >> 2) & 0xF, spiStatus & 3);

    uint32_t spiData = SPI_DATA;
    printf("RX Valid=%lu, TX Valid=%lu, RX=0x%02X, TX=0x%02X\n",
           (spiData >> 17) & 1, (spiData >> 16) & 1,
           (unsigned int)((spiData >> 8) & 0xFF), (unsigned int)(spiData & 0xFF));

    uint32_t dataBuffer = DATA_BUFFER;
    printf("Data Buffer: 0x%08lX\n", dataBuffer);

    uint32_t hlsStatus = HLS_STATUS;
    printf("Done Latch=%lu, Select=%lu, Start=%lu, Done=%lu, Idle=%lu, Ready=%lu\n",
           (hlsStatus >> 5) & 1, (hlsStatus >> 4) & 1, (hlsStatus >> 3) & 1,
           (hlsStatus >> 2) & 1, (hlsStatus >> 1) & 1, hlsStatus & 1);

    int32_t result1 = RESULT1;
    int32_t result2 = RESULT2;
    printf("R1=%ld, R2=%ld\n", result1, result2);

    uint32_t bramDataOut1 = BRAM_DATA_OUT1;
    uint32_t bramDataOut2 = BRAM_DATA_OUT2;
    uint32_t bramAddr = BRAM_ADDR;
    printf("Out1=0x%08X, Out2=0x%08X, Addr=%lu\n",
           (unsigned int)bramDataOut1, (unsigned int)bramDataOut2, bramAddr);

    fflush(stdout);
}

int main() {
    while(1) {
        printStatus();
        usleep(100000); // 0.1s
    }
    return 0;
}
