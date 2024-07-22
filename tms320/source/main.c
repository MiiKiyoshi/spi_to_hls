#include "DSP2834x_Device.h"
#include "DSP2834x_Examples.h"

#define CMD_WRITE_VALS    0x01
#define CMD_READ_VALS     0x02
#define CMD_CHECK_DONE    0x03
#define CMD_READ_RESULT1  0x04
#define CMD_READ_RESULT2  0x05
#define NUM_VALUES_PER_BRAM 10

#define LSPCLK 50000000
#define CALC_SPIBRR(baud_rate) ((LSPCLK / (baud_rate)) - 1)

// ���� ���� ����
int32 data1[NUM_VALUES_PER_BRAM];
int32 data2[NUM_VALUES_PER_BRAM];
int32 result1, result2;
int32 stored_data1[NUM_VALUES_PER_BRAM], stored_data2[NUM_VALUES_PER_BRAM];
Uint8 done_status;
Uint16 spi_status;
Uint8 temp;
Uint16 error_flag = 0;
Uint32 error_count = 0;
Uint32 timeout = 0;

// �Լ� ������Ÿ��
void InitializeSPIAGpio(void);
void InitializeSPIA(void);
Uint8 SPITransaction(Uint8 data, Uint16 send);
void writeAllVals(void);
Uint8 checkDone(void);
void readResults(void);
void readStoredVals(void);

void main(void)
{
    int i;

    // �ý��� �ʱ�ȭ
    InitSysCtrl();
    InitializeSPIAGpio();
    InitializeSPIA();

    // ���ͷ�Ʈ �ʱ�ȭ
    DINT;
    InitPieCtrl();
    IER = 0x0000;
    IFR = 0x0000;
    InitPieVectTable();

    data1[0] = 1;    data2[0] = 10;
    data1[1] = 2;    data2[1] = 20;
    data1[2] = 3;    data2[2] = 30;
    data1[3] = 4;    data2[3] = 40;
    data1[4] = 5;    data2[4] = 50;
    data1[5] = 60;   data2[5] = 6;
    data1[6] = 70;   data2[6] = 7;
    data1[7] = 80;   data2[7] = 8;
    data1[8] = 90;   data2[8] = 9;
    data1[9] = 100;  data2[9] = 10;

    // ���� ����
    while(1)
    {
        for (i = 0; i < 10; i++){
            data1[i]++;
            data2[i]++;
        }

        writeAllVals();

        // �Ϸ� ���
        timeout = 0;
        do {
            done_status = checkDone();
            timeout++;
            if (timeout > 1000) {
                break;
            }
        } while (!done_status);

        readResults();
        readStoredVals();

        for (i = 0; i < NUM_VALUES_PER_BRAM; i++) {
            if (stored_data1[i] != data1[i] || stored_data2[i] != data2[i]) {
                error_flag = 1;
                error_count++;
            } else {
                error_flag = 0;
            }
        }

    }
}

void InitializeSPIAGpio(void)
{
    EALLOW;
    // GPIO Ǯ�� Ȱ��ȭ
    GpioCtrlRegs.GPAPUD.bit.GPIO16 = 0;   // SPISIMOA
    GpioCtrlRegs.GPAPUD.bit.GPIO17 = 0;   // SPISOMIA
    GpioCtrlRegs.GPAPUD.bit.GPIO18 = 0;   // SPICLKA
    GpioCtrlRegs.GPAPUD.bit.GPIO19 = 0;   // SPISTEA
    // GPIO �񵿱� ����
    GpioCtrlRegs.GPAQSEL2.bit.GPIO16 = 3; // SPISIMOA
    GpioCtrlRegs.GPAQSEL2.bit.GPIO17 = 3; // SPISOMIA
    GpioCtrlRegs.GPAQSEL2.bit.GPIO18 = 3; // SPICLKA
    GpioCtrlRegs.GPAQSEL2.bit.GPIO19 = 3; // SPISTEA
    // GPIO ��� ����
    GpioCtrlRegs.GPAMUX2.bit.GPIO16 = 1; // SPISIMOA
    GpioCtrlRegs.GPAMUX2.bit.GPIO17 = 1; // SPISOMIA
    GpioCtrlRegs.GPAMUX2.bit.GPIO18 = 1; // SPICLKA
    GpioCtrlRegs.GPAMUX2.bit.GPIO19 = 1; // SPISTEA
    EDIS;
}

void InitializeSPIA(void)
{
    // SPI �ʱ�ȭ
    SpiaRegs.SPICCR.bit.SPISWRESET = 0;      // SPI ����
    SpiaRegs.SPICCR.bit.CLKPOLARITY = 1;     // Ŭ�� �ؼ� ����
    SpiaRegs.SPICCR.bit.SPICHAR = (8-1);     // 8��Ʈ ������
    SpiaRegs.SPICTL.bit.MASTER_SLAVE = 1;    // ������ ���
    SpiaRegs.SPICTL.bit.TALK = 1;            // ���� Ȱ��ȭ
    SpiaRegs.SPICTL.bit.CLK_PHASE = 1;       // Ŭ�� ���� ����
    SpiaRegs.SPIBRR = CALC_SPIBRR(7000000);  // ��� �ӵ� ����
    SpiaRegs.SPICCR.bit.SPISWRESET = 1;      // SPI Ȱ��ȭ
}

Uint8 SPITransaction(Uint8 data, Uint16 send)
{
    // Ŭ�� ������ ���� (send�� 1�̸� CLK_PHASE = 1, �ƴϸ� CLK_PHASE = 0)
    SpiaRegs.SPICTL.bit.CLK_PHASE = send;

    // Ŭ�� ������ ���� �� �ణ�� ������
    DELAY_US(1);

    // ������ ���� (���� 8��Ʈ�� ������ ��ġ)
    SpiaRegs.SPITXBUF = ((Uint16)data) << 8;

    // ���� �Ϸ� ���
    while(SpiaRegs.SPISTS.bit.INT_FLAG == 0);

    spi_status = SpiaRegs.SPISTS.all;

    // ���� ������ �б� (���� 8��Ʈ�� ���)
    return (Uint8)(SpiaRegs.SPIRXBUF & 0xFF);
}

void writeAllVals(void)
{
    int i;
    SPITransaction(CMD_WRITE_VALS, 1);  // ��ɾ� ����

    for (i = 0; i < NUM_VALUES_PER_BRAM; i++) {
        // data1 (little endian)
        SPITransaction(data1[i] & 0xFF, 1);
        SPITransaction((data1[i] >> 8) & 0xFF, 1);
        SPITransaction((data1[i] >> 16) & 0xFF, 1);
        SPITransaction((data1[i] >> 24) & 0xFF, 1);

        // data2 (little endian)
        SPITransaction(data2[i] & 0xFF, 1);
        SPITransaction((data2[i] >> 8) & 0xFF, 1);
        SPITransaction((data2[i] >> 16) & 0xFF, 1);
        SPITransaction((data2[i] >> 24) & 0xFF, 1);
    }
}

Uint8 checkDone(void)
{
    SPITransaction(CMD_CHECK_DONE, 1);  // ��ɾ� ����
    return SPITransaction(0, 0) & 0x01;  // ���� �б�
}

void readResults(void)
{
    SPITransaction(CMD_READ_RESULT1, 1);  // ��ɾ� ����
    temp = SPITransaction(0, 0);
    result1 = temp;
    temp = SPITransaction(0, 0);
    result1 |= (int32)temp << 8;
    temp = SPITransaction(0, 0);
    result1 |= (int32)temp << 16;
    temp = SPITransaction(0, 0);
    result1 |= (int32)temp << 24;

    SPITransaction(CMD_READ_RESULT2, 1);  // ��ɾ� ����
    temp = SPITransaction(0, 0);
    result2 = temp;
    temp = SPITransaction(0, 0);
    result2 |= (int32)temp << 8;
    temp = SPITransaction(0, 0);
    result2 |= (int32)temp << 16;
    temp = SPITransaction(0, 0);
    result2 |= (int32)temp << 24;
}

void readStoredVals(void)
{
    int i;

    SPITransaction(CMD_READ_VALS, 1);  // ��ɾ� ����

    for (i = 0; i < NUM_VALUES_PER_BRAM; i++) {
        // data1 (little endian)
        temp = SPITransaction(0, 0);
        stored_data1[i] = temp;
        temp = SPITransaction(0, 0);
        stored_data1[i] |= (int32)temp << 8;
        temp = SPITransaction(0, 0);
        stored_data1[i] |= (int32)temp << 16;
        temp = SPITransaction(0, 0);
        stored_data1[i] |= (int32)temp << 24;

        // data2 (little endian)
        temp = SPITransaction(0, 0);
        stored_data2[i] = temp;
        temp = SPITransaction(0, 0);
        stored_data2[i] |= (int32)temp << 8;
        temp = SPITransaction(0, 0);
        stored_data2[i] |= (int32)temp << 16;
        temp = SPITransaction(0, 0);
        stored_data2[i] |= (int32)temp << 24;
    }
}
