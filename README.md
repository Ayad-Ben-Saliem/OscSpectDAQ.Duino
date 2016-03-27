# OscSpectDAQ.Duino

OscSpectDAQ.Duino (Oscilloscope, Spectrum Analyzer & DAQ System using just single Arduino Due)
by Ayad Bin Saleem

  This project uses Arduino Due to collecting signals in real world, and send them to computer to process it.
  The processing is represented in real-time plotting of raw data just as coming from the board, 
  and plot its spectrum synchronously.
  The additional utility of this project is DAQ System (Data Acquisition System),
  where it provide the date in a file created by user. It stored in it as uint16_t.
  The computer side processing achieved by MATLAB.
  
  How to use
  1 - Install this code to your arduino Deu bord and connet it to computer using native USB.
  2 - Go to MATLAB and run the MATLAB code, setup your serial port address.
