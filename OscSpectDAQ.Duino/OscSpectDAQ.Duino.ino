/** REFERANCE
 *  1- 
 *  2- 
 *  3- http://nicecircuits.com/playing-with-analog-to-digital-converter-on-arduino-due/
 *  4- http://engineeringleague.org/?p=150
 */


#undef HID_ENABLED

#define BufferCount  4                        // Buffer Count (must equal to 2's power).
#define BufferSize   10000                    // Buffer Size.
#define RESET        BufferCount-1
volatile int bufn, obufn;
uint16_t buff[ BufferCount ][ BufferSize ];     // 4 buffers of 256 readings.

#define bytesPerBuffer (int)(BufferSize * sizeof(uint16_t))

#define ENDRX  1 << 27                     // End of RX Buffer bit 0x08000000. See SAM3X8E datasheet ( Page 1345 ).

void ADC_Handler(){                        // move DMA pointers to next buffer
  if (ADC->ADC_ISR & ENDRX){
    ++bufn &= RESET;
    ADC->ADC_RNPR = (uint32_t)buff[bufn];  // Receive Next Pointer Register.
    ADC->ADC_RNCR = BufferSize;            // Receive Next Counter Register.
  } 
}

void setup(){
  SerialUSB.begin(0);
//  while(!SerialUSB);
  Serial.begin(250000);

  // Power Management Controller. see "http://asf.atmel.com/docs/latest/sam3a/html/group__sam__drivers__pmc__group.html"
  //                                  SAM3X8E datasheet (page 1319).
  // To use peripheral, we must enable clock distributon to it.
  pmc_enable_periph_clk(ID_ADC) != 0;
  adc_init(ADC, SystemCoreClock, ADC_FREQ_MAX, ADC_STARTUP_FAST);  // initialize, set maximum possible speed.
  ADC->ADC_MR = 0x00000080;           // Run FREERUNNING mode. See SAM3X8E datasheet ( page : 1333 ).
  ADC->ADC_CHER = (1 << 7);           // Enable CH7. See SAM3X8E datasheet ( page : 1338 ).
  NVIC_EnableIRQ(ADC_IRQn);
  ADC->ADC_IER = (1 << 27);           // Enable (End of Receive Buffer) Interrupt. See SAM3X8E datasheet ( page : 1342 ).
  ADC->ADC_IDR = ~(1 << 27);          // Disable (End of Receive Buffer) Interrupt. See SAM3X8E datasheet ( page : 1343 ).
  ADC->ADC_RPR  = (uint32_t)buff[0];  // Set Receive Pointer Register (DMA buffer). See SAM3X8E datasheet ( page 509 ).
  ADC->ADC_RCR  = BufferSize;         // Set Receive Counter Register (DMA buffer). See SAM3X8E datasheet ( page 510 ).
  ADC->ADC_RNPR = (uint32_t)buff[1];  // Set Receive Next Pointer Register (next DMA buffer). See SAM3X8E datasheet ( page 513 ).
  ADC->ADC_RNCR = BufferSize;         // Set Receive Next Counter Register (next DMA buffer). See SAM3X8E datasheet ( page 514 ).
  bufn = obufn = 1;
  ADC->ADC_PTCR = 0x00000001;         // Set Receiver Transfer Enable bit in Transfer Control Register. See SAM3X8E datasheet ( page 517 ).
  ADC->ADC_CR  = 0x00000002;          // Begins analog-to-digital conversion. See SAM3X8E datasheet ( page : 1332 ).
}

void loop(){
  while(obufn == bufn);          // wait for buffer to be full.
  SerialUSB.write((uint8_t*)buff[obufn-1], bytesPerBuffer);    // send it - 20000 bytes = 10000 uint16_t
  ++obufn &= RESET;
}
