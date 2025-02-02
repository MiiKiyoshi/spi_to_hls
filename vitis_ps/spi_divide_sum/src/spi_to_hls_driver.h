#ifndef SPI_TO_HLS_DRIVER_H
#define SPI_TO_HLS_DRIVER_H

#include <xparameters.h>
#include <stdint.h>

#define SPI_TO_HLS_BASEADDR XPAR_SPI_TO_HLS_0_BASEADDR

// Register offsets
#define SYSTEM_CONTROL_REG   0x00
#define SPI_STATUS_REG       0x04
#define SPI_DATA_REG         0x08
#define DATA_BUFFER_REG      0x0C
#define HLS_STATUS_REG       0x10
#define RESULT1_REG          0x14
#define RESULT2_REG          0x18
#define BRAM_DATA_OUT1_REG   0x1C
#define BRAM_DATA_OUT2_REG   0x20
#define BRAM_ADDR_REG        0x24

// Direct memory access to the registers
#define SYSTEM_CONTROL       (*(volatile uint32_t *)(SPI_TO_HLS_BASEADDR + SYSTEM_CONTROL_REG))
#define SPI_STATUS           (*(volatile uint32_t *)(SPI_TO_HLS_BASEADDR + SPI_STATUS_REG))
#define SPI_DATA             (*(volatile uint32_t *)(SPI_TO_HLS_BASEADDR + SPI_DATA_REG))
#define DATA_BUFFER          (*(volatile uint32_t *)(SPI_TO_HLS_BASEADDR + DATA_BUFFER_REG))
#define HLS_STATUS           (*(volatile uint32_t *)(SPI_TO_HLS_BASEADDR + HLS_STATUS_REG))
#define RESULT1              (*(volatile int32_t *)(SPI_TO_HLS_BASEADDR + RESULT1_REG))
#define RESULT2              (*(volatile int32_t *)(SPI_TO_HLS_BASEADDR + RESULT2_REG))
#define BRAM_DATA_OUT1       (*(volatile uint32_t *)(SPI_TO_HLS_BASEADDR + BRAM_DATA_OUT1_REG))
#define BRAM_DATA_OUT2       (*(volatile uint32_t *)(SPI_TO_HLS_BASEADDR + BRAM_DATA_OUT2_REG))
#define BRAM_ADDR            (*(volatile uint32_t *)(SPI_TO_HLS_BASEADDR + BRAM_ADDR_REG))

#endif // SPI_TO_HLS_DRIVER_H
