#include <Streaming.h>
#include <Metro.h>
#include <CmdMessenger.h>
#include "Solenoid.h"

const unsigned long minDuration = 10UL;
const unsigned long maxDuration = 10000UL;

/*
const byte N_PORTS = 2;
const byte pins[N_PORTS] = {13, 13};
const byte lowDef[N_PORTS] = {LOW, LOW};
*/

const byte N_PORTS = 16;
// pin hookups
const byte pins[N_PORTS] = {
  // for the 8x SSRs (AC)
  28, 26, 24, 22, 46, 48, 50, 52, 
  // for the 8x relays (DC)
  23, 25, 27, 29, 47, 49, 51, 53 
};
const byte lowDef[N_PORTS] = {
  LOW, LOW, LOW, LOW, LOW, LOW, LOW, LOW,   // SS (AC) relays are off when pin is LOW
  HIGH,HIGH,HIGH,HIGH,HIGH,HIGH,HIGH,HIGH // EM (DC) relays are off when pin is HIGH
};

Solenoid sol[N_PORTS];

// Attach a new CmdMessenger object to the default Serial port
CmdMessenger cmdMessenger(Serial);

// This is the list of recognized commands.
// In order to receive, attach a callback function to these events
enum
{
  kCommandList,    // 0: Request list of available commands
  kClear,          // 1: clear timings
  kSetTiming,      // 2: Set timings
  kShowTiming,     // 3: Show timings
  kFiring,         // 4: Execute firing sequence
  kShutdown        // 5: Execute shutdown.  just in case.
};

// Called when a received command has no attached function
void OnUnknownCommand()
{
  Serial << F("This command is unknown!") << endl;
  OnCommandList();
}
void OnCommandList() {
  Serial << F("* COMMANDS *") << endl;
  Serial << F(" 0;  -> This list.") << endl;
  Serial << F(" 1;  -> clear port timings.") << endl;
  Serial << F(" 2,<port>,<onDuration[=]ms>,<offDuration[=]ms>,<cycles[=]N>[,<startDelay[=]ms]; -> set port delay timings.") << endl;
  Serial << F(" 3;  -> show port timings [in mode].") << endl;
  Serial << F(" 4;  -> fire the ports.") << endl;
  Serial << F(" 5;  -> shutdown the ports.") << endl;
  Serial << endl;

}
void OnSetTiming() {
  Serial << F("* SET TIMING *") << endl;  
  byte port = cmdMessenger.readInt16Arg();
  unsigned long onDuration = cmdMessenger.readInt32Arg();
  unsigned long offDuration = cmdMessenger.readInt32Arg();
  byte cycles = cmdMessenger.readInt16Arg();
  unsigned long startDelay = cmdMessenger.readInt32Arg();

  // do some serious error checking
  if( port<0 || port >=N_PORTS ) {
    Serial << F("ERROR: port ") << port << F(" must be within [0,") << N_PORTS-1 << F("]") << endl;
    return;
  }
  if( onDuration<minDuration || onDuration>maxDuration ) {
    Serial << F("ERROR: onDuration ") << onDuration << F(" must be within [") << minDuration << F(",") << maxDuration << F("]") << endl;
    return;
  }
  if( offDuration<minDuration ) {
    Serial << F("ERROR: offDuration ") << offDuration << F(" must be within [") << minDuration << F(",Inf]") << endl;
    return;
  }
  if( cycles<0 ) {
    Serial << F("ERROR: offDuration ") << offDuration << F(" must be within [") << minDuration << F(",Inf]") << endl;
    return;
  }
  // update
  sol[port].set(onDuration, offDuration, cycles, startDelay);
}
void OnShowTiming() {
  Serial << F("* SHOW TIMING *") << endl;
  for( byte i=0; i<N_PORTS; i++ ) 
    if( sol[i].wouldRun() ) sol[i].show();
}
void OnFiring() {
  Serial << F("*** FIRING ***") << endl;
  for( byte i=0; i<N_PORTS; i++ ) sol[i].start();
}
void OnShutdown() {
  Serial << F("*** SHUTDOWN ***") << endl;
  for( byte i=0; i<N_PORTS; i++ ) sol[i].stop();
}
void OnClear() {
  Serial << F("* CLEAR *") << endl;
  for( byte i=0; i<N_PORTS; i++ ) sol[i].set(0,0,0,0);
}
// Callbacks define on which received commands we take action
void attachCommandCallbacks()
{
  // Attach callback methods
  cmdMessenger.attach(OnUnknownCommand);
  cmdMessenger.attach(kClear, OnClear);
  cmdMessenger.attach(kCommandList, OnCommandList);
  cmdMessenger.attach(kSetTiming, OnSetTiming);
  cmdMessenger.attach(kShowTiming, OnShowTiming);
  cmdMessenger.attach(kFiring, OnFiring);
  cmdMessenger.attach(kShutdown, OnShutdown);
}


void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);

  attachCommandCallbacks(); 
  
  for( byte i=0; i<N_PORTS; i++ ) {
    sol[i].begin(pins[i], lowDef[i]);
  }
//  sol[0].set(250, 500, 2, 2000);
//  sol[1].set(50, 500, 3, 100);

//  for( byte i=0; i<N_PORTS; i++ ) sol[i].show();
  
  OnCommandList();
}

boolean UpdatePorts() {
  boolean keepRunning = false;
  for( byte i=0; i<N_PORTS; i++ ) keepRunning |= sol[i].running();
  return( keepRunning );
}

void loop() {
  cmdMessenger.feedinSerialData();

  static boolean wasRunning = false;
  boolean isRunning = UpdatePorts();
  
  if( !isRunning && wasRunning ) {
    Serial << F("*** COMPLETE ***") << endl;
    OnShutdown(); // just make sure.
  }

  wasRunning = isRunning;
}

