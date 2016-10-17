/*
 * Le corps étendu
 * by Jaime Patarroyo
 * 
 * Sketch for managing the xBee modules acording to heart beat
 * readings from a webpage.
 * 
 * Works with xBees Series 2 with the following configurations:
 * One coordinator radio (ZigBee Coordinator API) connected to
 * te computer
 * PAN ID      5333  (Personal area network)
 * API mode    2
 * 
 * Up to 250 roter radios (ZigBee Router AT)
 * ATID        5333  (Personal area network)
 * ATDH        0     (Coordinator address: always 0)
 * ATDL        0     (Coordinator address: always 0)
 * ATJV        1     (Joins the network on startup)
 * ATP2        4     (xBee pin connected to the relay)
 * 
 */

// for OSC communication
import oscP5.*;
import netP5.*;
OscP5 oscP5;
NetAddress myRemoteLocation;


// program possible status
static short BEATING = 1;
static short STOP = 2;
static short OFF = 3;
// current status
short status = STOP;
// last status
short lastStatus = STOP;

// heart beat phases
static short DIASTOLE_ONE = 1;
static short DIASTOLE_TWO = 2;
static short SYSTOLE_ONE = 3;
static short SYSTOLE_TWO = 4;
// current phase
short phase = DIASTOLE_ONE;

// integer for storing heart rate in beats per minute (bpm)
int bpm = 60;
// integer for storing the beat frequency en milliseconds
int beatFrequency = 60000/bpm;
// long for frequency of heart beat
long previousBeatTime = 0;
// long for frequency of phases
long previousPhaseTime = 0;

// xBee router object
Router router;
// long for taking time
long previousNodeDiscovery;

// PFont for information display
PFont font;

// contronl int
int n = 100;

long mark1 = 0;
long mark2 = 0;
long measure = 0;
int phaseInterval = 0;


void setup() { 
  size(600, 600); 
  background(50);
  smooth();


  // for OSC communication
  oscP5 = new OscP5(this, 5001);
  myRemoteLocation = new NetAddress("127.0.0.1", 12000);


  // Prints a list of serial ports in case the selected one 
  // doesn't work out:
  //println("Available serial ports:");
  //println(Serial.list());
  // REPLACE WITH THE SERIAL PORT (COM PORT) FOR YOUR LOCAL XBEE
  router = new Router("/dev/tty.usbserial-A4008dXP");

  // Looks for new nodes in the network:
  router.nodeDiscovery();
  //println(router.getNumNodes());

  // turns all nodes on
  for (int i=0; i<router.getNumNodes(); i++) {
    Node tempNode = (Node) router.getNodesArray().get(i);
    if (!tempNode.getStateP2())
      tempNode.toggleStateSynchronous();
  }

  // You’ll need to generate a font before you can run this sketch.
  // Click the Tools menu and choose Create Font. Click Sans Serif,
  // choose a size of 10, and click OK.
  font =  loadFont("OCRAStd-48.vlw");
  textFont(font, 12);

  // mark the initial time
  previousBeatTime = millis();
  previousNodeDiscovery = millis();
}

void draw() {
  background(50);

  fill(255);
  text("BPM: " + bpm, 10, 22);
  text("BFQ: " + beatFrequency, 10, 44);
  text("PI_: " + phaseInterval, 10, 66);
  text("BI_: " + phaseInterval*4, 10, 88);
  text("DIF: " + measure, 10, 110);


  // While beating
  if (status == BEATING) {

    if (((millis() - previousBeatTime) >= beatFrequency) && (phase == DIASTOLE_ONE)) {
      // turns all nodes off
      router.turnAllOff();

      n = 0;

      phase = DIASTOLE_TWO;
      previousPhaseTime = millis();
      previousBeatTime = millis();

      mark1 = millis();
    } 
    else if ((millis() - previousPhaseTime >= phaseInterval) && (phase == DIASTOLE_TWO)) {
      router.turnAllOn();

      n = 100;

      phase = SYSTOLE_ONE;
      previousPhaseTime = millis();
    } 
    else if ((millis() - previousPhaseTime >= phaseInterval) && (phase == SYSTOLE_ONE)) {
      router.turnAllOff();

      n = 0;

      phase = SYSTOLE_TWO;
      previousPhaseTime = millis();
    } 
    else if ((millis() - previousPhaseTime >= phaseInterval) && (phase == SYSTOLE_TWO)) {
      router.turnAllOn();

      n = 100;

      phase = DIASTOLE_ONE;
      previousPhaseTime = millis();

      measure = millis() - mark1;
    }
  } 
  else if (status == STOP) {
    if (lastStatus != STOP) {
      router.turnAllOn();
    }
  }
  else if (status == OFF) {
    if (lastStatus != OFF) {
      router.turnAllOff();
    }
  }

  lastStatus = status;

  ellipse (height/2, width/2, n, n);

  // Report any serial port problems in the main window:
  if (router.error == 1) {
    fill(0);
    text("** Error opening XBee port: **\n"+
      "Is your XBee plugged in to your computer?\n" +
      "Did you set your COM port in the code?", 
    width/3, height/2);
  }
}

void keyReleased() {
  if (key == 'm' || key == 'M') {
    status = BEATING;
  }
  if (key == 's' || key == 'S') {
    status = STOP;
  }
  if (key == 'o' || key == 'O') {
    status = OFF;
  }
  if (key == 'd' || key == 'D') {
    router.nodeDiscovery();
  }
}

void oscEvent(OscMessage theOscMessage) {
  bpm = theOscMessage.get(0).intValue();

  if (bpm <= 0)
    bpm = 1;

  //bpm = 70;
  // calculate beat frequency in  milliseconds
  beatFrequency = 60000/bpm;
  // int for storing duration of phase intervals
  phaseInterval = ((beatFrequency/4)*3)/4;
  if (phaseInterval>100)
    phaseInterval = 100;
}

