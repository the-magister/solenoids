#include <Streaming.h>
#include <Metro.h>
#include "Solenoid.h"

const byte N_pins = 2;
const byte pins[N_pins] = {13, 13};
const byte lowDef[N_pins] = {LOW, LOW};

Solenoid sol[N_pins];

void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);

  for( byte i=0; i<N_pins; i++ ) {
    sol[i].begin(pins[i], lowDef[i]);
  }
  sol[0].set(250, 500, 2, 2000);
  sol[1].set(50, 500, 3, 100);

}

void loop() {
  delay(1000);

  // put your main code here, to run repeatedly:
  Serial << "Start" << endl;
  for( byte i=0; i<N_pins; i++ ) sol[i].start();
  
  boolean keepRunning = true;
  while( keepRunning ) {
    keepRunning = false;
    for( byte i=0; i<N_pins; i++ ) keepRunning |= sol[i].running();
  }
  Serial << "Complete" << endl;

  for( byte i=0; i<N_pins; i++ ) sol[i].stop();
  Serial << "Stopped" << endl;
}

