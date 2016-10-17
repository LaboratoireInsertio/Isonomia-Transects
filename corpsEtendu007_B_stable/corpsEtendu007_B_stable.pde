import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress myRemoteLocation;

// String for incoming data
String inData;
// long for frequency of data retrival
long previousRetrieveTime = 0;

// integer for storing heart rate in beats per minute (bpm)
int bpm = 60;

// speed test
int bpmTest = 60;

void setup() {
  size(400, 400);

  oscP5 = new OscP5(this, 12000);
  myRemoteLocation = new NetAddress("127.0.0.1", 5001);

  // mark the initial time
  previousRetrieveTime = millis();
}

void draw() {

  // for retrieving information from given webpage
  // if 1 second (1000 milliseconds) have passed since last mark
  // and is not beating
  if ((millis() - previousRetrieveTime) >= 2000) {
    // get webpage (returns an array of Strings where each line is a 
    // String)

    String[] inData = loadStrings("http://p-al.co/jaime/vitrinaqc/F.php");
    // if there is no mistake retrieving data
    if (inData != null) {
      // go through the lines (Strings in the array)
      for (int i=0; i<inData.length; i++) {
        // look for the begining and the end of the message 
        // it comes in the form of +++value*** (e.g. +++140***)
        int firstIndex = inData[i].indexOf("+++");
        int lastIndex = inData[i].indexOf("***");
        // if the beggining and the end where found
        if (firstIndex >= 0 || lastIndex >= 0) {
          // remove what doesn't matter
          String result = inData[i].substring(firstIndex+3, lastIndex);
          // save it in the bpm variable
          bpm = int(result);

          // create an osc message
          OscMessage myMessage = new OscMessage("/test");
          // add an bom to the osc message
          myMessage.add(bpm);
          // send the message
          oscP5.send(myMessage, myRemoteLocation);
        }
      }
    }

    // mark time again
    previousRetrieveTime = millis();
  }
}


void keyPressed(){
  // for speed test
  if (key == 'k') bpmTest++;
  if (key == 'm') bpmTest--;
}
