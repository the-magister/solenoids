#ifndef Solenoid_h
#define Solenoid_h

#include <Arduino.h>
#include <Streaming.h>
#include <Metro.h>

class Solenoid {
  public: 
    // setup
    void begin(byte pin, byte lowDefinition=LOW); // set the pin
    void set(unsigned long onDuration, unsigned long offDuration, byte cycles=1, unsigned long startDelay=0);

    // operations
    void start(); // start the run
    boolean running(); // returns false if we're done
    void stop(); // halt any time

  private:
    byte pin, low, high, cyclesTotal, remainingCycles;

    unsigned long onDuration, offDuration, startDelay;

    Metro timer;

    boolean isOn;

    void setOff();
    void setOn();
    void toggle();
};

#endif
