#include "Solenoid.h"

void Solenoid::setOff() { 
  this->isOn = false;
  digitalWrite(this->pin, this->low);
}
void Solenoid::setOn() { 
  this->isOn = true;;
  digitalWrite(this->pin, this->high);
}
void Solenoid::toggle() { 
  if( this->isOn ) { 
    this->setOff();
  } else {
    this->setOn();
  }
}

void Solenoid::begin(byte pin, byte lowDefinition) {
  this->pin = pin;
  this->low = lowDefinition;
  this->high = !lowDefinition;
  this->setOff();

  // then set the pin to OUTPUT
  pinMode(this->pin, OUTPUT);

  Serial << F("Solenoid initializing.  pin=") << this->pin << F(" low=") << this->low << endl;

  this->set(0,0,0,0); // start with doing nothing.
}

void Solenoid::set(unsigned long onDuration, unsigned long offDuration, byte cycles, unsigned long startDelay) {
  this->cyclesTotal = cycles;
  this->onDuration = onDuration;
  this->offDuration = offDuration;
  this->startDelay = startDelay;
  this->remainingCycles = 0;
}

boolean Solenoid::wouldRun() {
  return( this->cyclesTotal>0 ? true : false );
}

void Solenoid::show() {
  Serial << F("Solenoid settings.  pin=") << this->pin << F(". on/off=") << this->onDuration << "/";
  Serial << this->offDuration << F(" ms. cycles=") << this->cyclesTotal << F(". start delay=") << this->startDelay; 
  Serial << " ms." << endl; 
}

void Solenoid::start() {
  // assign the work load.
  this->remainingCycles = this->cyclesTotal;
  this->setOff();
  
  if( startDelay> 0 ) {
    // we need to add some delay here
    this->timer.interval(startDelay);
    this->timer.reset();
  } else {
    // so will go HIGH ASAP
    this->timer.interval(0);
    this->timer.reset();
  }
}

boolean Solenoid::running() {
  // bail out if we're not needed
  if( this->remainingCycles<1 ) return(false);
   
  // is the timer up?
  if( this->timer.check() ) {
    this->toggle();
    if( this->isOn ) {
      // started a new cycle
      this->timer.interval(this->onDuration);
    } else {
      // ended a cycle
      this->timer.interval(this->offDuration);
      // decrement work
      this->remainingCycles--;
    }
    this->timer.reset();
  }
  
  return(true);
}

void Solenoid::stop() {
  this->remainingCycles = 0;
  this->setOff();
}

