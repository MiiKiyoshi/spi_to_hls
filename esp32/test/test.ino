#include <esp_system.h>
#include <SPI.h>

#define SPI_SCK 18
#define SPI_MISO 19
#define SPI_MOSI 23
#define SPI_SS 5

#define CMD_WRITE_VALS    0x01
#define CMD_READ_VALS     0x02
#define CMD_CHECK_DONE    0x03
#define CMD_READ_RESULT1  0x04
#define CMD_READ_RESULT2  0x05

#define NUM_VALUES_PER_BRAM 10

void setup() {
  Serial.begin(115200);
  
  SPI.begin(SPI_SCK, SPI_MISO, SPI_MOSI, SPI_SS);
  SPI.beginTransaction(SPISettings(10000000, MSBFIRST, SPI_MODE2));
  
  pinMode(SPI_SS, OUTPUT);
  digitalWrite(SPI_SS, HIGH);

  Serial.println("ESP32 SPI Sender initialized");
}

void loop() {
  static uint8_t counter = 0;
  int32_t data1[NUM_VALUES_PER_BRAM];
  int32_t data2[NUM_VALUES_PER_BRAM];

  for (int i = 0; i < NUM_VALUES_PER_BRAM; i++) {
    data1[i] = (int32_t)esp_random();
    data2[i] = (int32_t)esp_random();
  }

  writeAllVals(data1, data2);

  Serial.println("Sent data:");
  for (int i = 0; i < NUM_VALUES_PER_BRAM; i++) {
    Serial.printf("data1[%d] = %d, data2[%d] = %d\n", i, data1[i], i, data2[i]);
  }

  while (!checkDone());
  Serial.println("Operation completed");

  int32_t result1, result2;
  readResults(&result1, &result2);
  Serial.printf("Result 1: %d, Result 2: %d\n", result1, result2);

  int32_t stored_data1[NUM_VALUES_PER_BRAM], stored_data2[NUM_VALUES_PER_BRAM];
  readStoredVals(stored_data1, stored_data2);

  Serial.println("Stored data:");
  bool dataCorrect = true;
  for (int i = 0; i < NUM_VALUES_PER_BRAM; i++) {
    Serial.printf("stored_data1[%d] = %d, stored_data2[%d] = %d\n", i, stored_data1[i], i, stored_data2[i]);
    if (stored_data1[i] != data1[i] || stored_data2[i] != data2[i]) {
      dataCorrect = false;
    }
  }

  if (dataCorrect) {
    Serial.println("Data verification successful");
  } else {
    Serial.println("Data verification failed");
  }

  Serial.println("--------------------");
  // delay(100);  
}

void writeAllVals(int32_t* data1, int32_t* data2) {
  digitalWrite(SPI_SS, LOW);
  SPI.transfer(CMD_WRITE_VALS);
  
  for (int i = 0; i < NUM_VALUES_PER_BRAM; i++) {
    // data1 (little endian)
    SPI.transfer(data1[i] & 0xFF);
    SPI.transfer((data1[i] >> 8) & 0xFF);
    SPI.transfer((data1[i] >> 16) & 0xFF);
    SPI.transfer((data1[i] >> 24) & 0xFF);
    
    // data2 (little endian)
    SPI.transfer(data2[i] & 0xFF);
    SPI.transfer((data2[i] >> 8) & 0xFF);
    SPI.transfer((data2[i] >> 16) & 0xFF);
    SPI.transfer((data2[i] >> 24) & 0xFF);
  }
  
  digitalWrite(SPI_SS, HIGH);
}

bool checkDone() {
  digitalWrite(SPI_SS, LOW);
  SPI.transfer(CMD_CHECK_DONE);
  uint8_t status = SPI.transfer(0);
  digitalWrite(SPI_SS, HIGH);
  
  return (status & 0x01) != 0;
}

void readResults(int32_t* result1, int32_t* result2) {
  digitalWrite(SPI_SS, LOW);
  SPI.transfer(CMD_READ_RESULT1);
  *result1 = SPI.transfer(0);
  *result1 |= SPI.transfer(0) << 8;
  *result1 |= SPI.transfer(0) << 16;
  *result1 |= SPI.transfer(0) << 24;
  digitalWrite(SPI_SS, HIGH);
  
  digitalWrite(SPI_SS, LOW);
  SPI.transfer(CMD_READ_RESULT2);
  *result2 = SPI.transfer(0);
  *result2 |= SPI.transfer(0) << 8;
  *result2 |= SPI.transfer(0) << 16;
  *result2 |= SPI.transfer(0) << 24;
  digitalWrite(SPI_SS, HIGH);
}

void readStoredVals(int32_t* data1, int32_t* data2) {
  digitalWrite(SPI_SS, LOW);
  SPI.transfer(CMD_READ_VALS);
  
  for (int i = 0; i < NUM_VALUES_PER_BRAM; i++) {
    // data1 (little endian)
    data1[i] = SPI.transfer(0);
    data1[i] |= SPI.transfer(0) << 8;
    data1[i] |= SPI.transfer(0) << 16;
    data1[i] |= SPI.transfer(0) << 24;
    
    // data2 (little endian)
    data2[i] = SPI.transfer(0);
    data2[i] |= SPI.transfer(0) << 8;
    data2[i] |= SPI.transfer(0) << 16;
    data2[i] |= SPI.transfer(0) << 24;
  }
  
  digitalWrite(SPI_SS, HIGH);
}