/**
 * OscSpectDAQ.Duino (Oscilloscope, Spectrum Analyzer & DAQ System using just single Arduino Due)
 * by Ayad Bin Saleem
 * 
 * This project uses Arduino Due to collecting signals in real world, and send them to computer to process it.
 * The processing is represented in real-time plotting of raw data just as coming from the board, 
 * and plot its spectrum synchronously.
 * The additional utility of this project is DAQ System (Data Acquisition System),
 * where it provide the date in a file created by user. It stored in it as uint16_t.
 * The computer side processing achieved by MATLAB.
 * 
 * How to use
 * 1- Install this code to your arduino Deu bord and connet it to computer using native USB.
 * 2- Go to MATLAB and run the MATLAB code, setup your serial port address.
 *
 * REFERANCE
 * 1- https://gist.github.com/pklaus/5921022
 * 2- http://nicecircuits.com/playing-with-analog-to-digital-converter-on-arduino-due/
 * 3- http://engineeringleague.org/?p=150
 */


#undef HID_ENABLED

#define BufferCount  4                        // Buffer Count (must equal to 2's power).
#define BufferSize   10000                    // Buffer Size.
#define RESET        BufferCount-1
volatile int bufn, obufn;
uint16_t buff[ BufferCount ][ BufferSize ];     // BufferCount buffers of BufferSize readings.

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
