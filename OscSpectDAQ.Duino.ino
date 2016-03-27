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
 * 1 - Install this code to your arduino Deu bord and connet it to computer using native USB.
 * 2 - Go to MATLAB and run the MATLAB code, setup your serial port address.
 */

#undef HID_ENABLED

#define BufferCont 4
#define BufferSize 1<<10 // 1024

volatile int bufn,obufn;
uint16_t buf[BufferCont][BufferSize];   // 4 buffers of 1024 readings

void ADC_Handler(){     // move DMA pointers to next buffer
  ADC->ADC_ISR;
  if (ADC->ADC_ISR &(1<<27)){
   ADC->ADC_RNPR = (uint32_t)buf[bufn];
   bufn = (bufn+1)&3;  // 0, 1, 2, 3
   ADC->ADC_RNCR = BufferSize;
  } 
}

void setup(){
  SerialUSB.begin(0);
  while(!SerialUSB);
  pmc_enable_periph_clk(ID_ADC);
  adc_init(ADC, SystemCoreClock, ADC_FREQ_MAX, ADC_STARTUP_FAST);
  ADC->ADC_MR |= B10000000; // free running

  ADC->ADC_CHER = B10000000;

  NVIC_EnableIRQ(ADC_IRQn);
  ADC->ADC_IDR =~ (1<<27);
  ADC->ADC_IER =  (1<<27);
  ADC->ADC_RPR =  (uint32_t)buf[0];  // DMA buffer
  ADC->ADC_RCR =  BufferSize;
  ADC->ADC_RNPR = (uint32_t)buf[1];  // next DMA buffer
  ADC->ADC_RNCR = BufferSize;
  bufn = obufn =  1;
  ADC->ADC_PTCR = 1;
  ADC->ADC_CR = 2;
}

void loop(){
  if(obufn == bufn);   // wait for buffer to be full
    SerialUSB.write((uint8_t *)buf[obufn],2048); // send it - 2048 bytes = 1024 uint16_t
  obufn=(obufn+1)&3;
  analogWrite(6, 10 );  // Write PWM to pin 6
}
