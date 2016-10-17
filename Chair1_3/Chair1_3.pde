/*
 * Based on code by Rob Faludi http://faludi.com
 */

// Processing opengl libray for map managing:
import processing.opengl.*;

// Modest Maps library:
// ModestMaps: http://modestmaps.com/index.html
// ModestMaps processing: https://github.com/RandomEtc/modestmaps-processing
import com.modestmaps.*;
import com.modestmaps.core.*;
import com.modestmaps.geo.*;
import com.modestmaps.providers.*;




// Processing OSC library for imput from the chair
import oscP5.*;
import netP5.*;

OscP5 oscP5;

float rcvSlider = 0;
float rcvCompass = 0;




// InteractiveMap object:
InteractiveMap map;

// Initial latitude, longitude and zomm:
//float lat = 48.41929163001349;
//float lon = -71.05295866727829;
float lat = 48.4239603812326;
float lon = -71.07255404821697;
int zoom = 18;



// variables for data comming from the chair
float rotation = 0;
float distance = 0;

// vector for virtual position
PVector vPos;



// Router object:
Router router;

// Last time we cheked for nodes:
float lastNodeDiscovery;

// Font for display:
PFont font;

// Array of switches:
ArrayList <Switch> switches;
// Number of switches that are not visible:
int noVisible = 0;

// Program posible status:
static int MAIN = 1;
static int ASSIGN = 2;

// Program current status:
int status = MAIN;


void setup() {
  // Window size:
  //size(displayWidth, displayHeight);
  size(600, 600, OPENGL);

  // Anti-aliasing for graphic display:
  smooth();

  // Prints a list of serial ports in case the selected one 
  // doesn't work out:
  println("Available serial ports:");
  println(Serial.list());

  // REPLACE WITH THE SERIAL PORT (COM PORT) FOR YOUR LOCAL XBEE
  router = new Router("/dev/tty.usbserial-A4007UjV");

  // Creates the switches array:
  switches = new ArrayList();

  // Loads switches from "assignedSwitches.txt" if abalable:
  String[] data = loadStrings( "assignedSwitches.txt" );
  if (data != null) {
    for (int i = 0; i < data.length; i++) {
      String currSwitch[] = split(data[i], '_');

      println(currSwitch[0]);
      println(float(currSwitch[1]));
      println(float(currSwitch[2]));
      switches.add(new Switch(currSwitch[0], false));
      Location loc = new Location(float(currSwitch[1]), float(currSwitch[2]));
      switches.get(i).assignPosition(0, 0, loc);
    }
  }

  // Fills the array with all non existing nodes:
  nodeSwitchManager();

  // Initializes map with given map provider:
  // For more providers look at the modestMaps example provided with the library.
  String template = "http://{S}.mqcdn.com/tiles/1.0.0/osm/{Z}/{X}/{Y}.png";
  String[] subdomains = new String[] { 
    "otile1", "otile2", "otile3", "otile4"
  };
  map = new InteractiveMap(this, new TemplatedMapProvider(template, subdomains));

  // Sets the initial location and zoom level:
  map.setCenterZoom(new Location(lat, lon), zoom);  




  // initializes vectors
  vPos = new PVector(width/2, height/2);
  
  // start oscP5, listening for incoming messages at port 12000
  oscP5 = new OscP5(this,12001);




  // You’ll need to generate a font before you can run this sketch.
  // Click the Tools menu and choose Create Font. Click Sans Serif,
  // choose a size of 10, and click OK.
  font =  loadFont("SansSerif-10.vlw");
  textFont(font);

  lastNodeDiscovery = millis();
}


void draw() {
  // Draw a white background:
  background(0);

  // Draws the map:
  // Dont need the map for interaction with the chair.
  //map.draw();




  // updates data from chair
  // uses mouse coordinates for testing
  //rotation = map(mouseX, 0, width, 0, 360);
  //distance = mouseY/2;
  // REPLACE FOR INCOMING CHAIR DATA //////////////////////////////////////
  rotation = rcvCompass * 360;
  if (width>height) distance = rcvSlider * (height/2);
  else distance = rcvSlider * (width/2);
  /////////////////////////////////////////////////////////////////////////




  // marks the center
  fill(255, 15);
  if (width>height)ellipse(width/2, height/2, height, height);
  else ellipse(width/2, height/2, width, width);
  fill(255);
  ellipse(width/2, height/2, 5, 5);

  // calculates the the virtual position on the window
  vPos.x = (width/2) + (cos(radians(rotation-90))*distance);
  vPos.y = (height/2) + (sin(radians(rotation-90))*distance);
  // draws the virtual position
  fill(200, 50, 100);
  ellipse(vPos.x, vPos.y, 10, 10);




  if (status == MAIN) {
    // Looks for changes in the Visual Interface and generates sends changes
    // to the Router and Nodes:
    for (int i  = 0; i < switches.size(); i++) {
      // Temporal switch:
      Switch tempSwitch = (Switch) switches.get(i);
      // Temporal boolean for monitoring changes:
      Boolean lastState = tempSwitch.getState();


      if (tempSwitch.isVisible()) {
        // Turns the switch ON if the mouse is over it:
        float distMouseSwitch = dist(tempSwitch.getX(), tempSwitch.getY(), vPos.x, vPos.y);
        if (distMouseSwitch < tempSwitch.getD()) {
          switches.get(i).assignState(true);
        } 
        else {
          switches.get(i).assignState(false);
        }

        // Displays switch:
        switches.get(i).render();
      }
      else {
        // Turns all switches OFF:
        if (switches.get(i).getState()) {
          switches.get(i).assignState(false);
        }
      }


      if (lastState != tempSwitch.getState()) {
        updateNode(tempSwitch);
      }
    }
  } 
  else if (status == ASSIGN) {

    boolean once = false;
    for (int i  = 0; i < switches.size(); i++) {
      // Temporal switch:
      Switch tempSwitch = (Switch) switches.get(i);
      // Temporal boolean for monitoring changes:
      Boolean lastState = tempSwitch.getState();

      if (tempSwitch.isVisible()) {
        // Turns all switches OFF:
        switches.get(i).assignState(false);
        switches.get(i).render();
      }
      else {
        if (!once) {
          switches.get(i).assignState(true);
          once = true;
        }
      }

      if (lastState != tempSwitch.getState()) {
        updateNode(tempSwitch);
      }
    }
  }


  // Periodic node re-discovery every 0.3 minutes:
  // Only adds new switches if the address doesn't exist.
  if (millis() - lastNodeDiscovery > 0.3 * 60 * 1000) {
    // Moved to work with letter 'd' in the keyboard.
    // nodeSwitchManager();

    lastNodeDiscovery = millis();
  }

  // Report any serial port problems in the main window:
  if (router.error == 1) {
    fill(0);
    text("** Error opening XBee port: **\n"+
      "Is your XBee plugged in to your computer?\n" +
      "Did you set your COM port in the code?", 
    width/3, height/2);
  }
}


// Function for updating the node of the given switch:
void updateNode(Switch tempSwitch) {
  // Temporal switch address:
  String tempAddress = tempSwitch.getAddress();
  // Temporal Node:
  Node tempNode = router.getNode(tempAddress);

  // Changes the state of the node if it is different from the 
  // state of the switch:
  if (tempNode != null) {
    if (tempSwitch.getState() != tempNode.getStateP2()) {
      tempNode.toggleState();
    }
  } 
  else {
    println("Node: " + tempAddress + " must be disconnected.");
  }
}


void mousePressed() {
  if (status == ASSIGN) {
    for (int i  = 0; i < switches.size(); i++) {
      if (!switches.get(i).isVisible()) {
        switches.get(i).assignPosition(mouseX, mouseY, map.pointLocation(mouseX, mouseY));
        noVisible--;
        break;
      }
    }

    ArrayList <String> switchesToSave = new ArrayList();
    for (int i = 0; i <switches.size(); i++) {
      if (switches.get(i).isVisible()) {
        String currAdd = switches.get(i).getAddress();
        float currLat = ((Location) switches.get(i).getLocation()).lat;
        float currLon = ((Location) switches.get(i).getLocation()).lon;

        String currSwitch = currAdd + "_" + currLat + "_" + currLon;
        switchesToSave.add(currSwitch);
      }
    }
    if (switchesToSave != null) {
      String[] data = switchesToSave.toArray(new String[switchesToSave.size()]);
      String path = dataPath("assignedSwitches.txt");

      saveStrings(path, data);
    }
  }
}


// Controls map interactions through keyboard:
void keyPressed() {
  if (key == CODED) {
    if (keyCode == LEFT) {
      //map.tx += 5.0/map.sc;
    }
    else if (keyCode == RIGHT) {
      //map.tx -= 5.0/map.sc;
    }
    else if (keyCode == UP) {
      //map.ty += 5.0/map.sc;
    }
    else if (keyCode == DOWN) {
      //map.ty -= 5.0/map.sc;
    }
  }  
  else if (key == '+' || key == '=') {
    //map.sc *= 1.05;
  }
  else if (key == '_' || key == '-' && map.sc > 2) {
    //map.sc *= 1.0/1.05;
  }
}


void keyReleased() {
  if (key == 'm' || key == 'M') {
    status = MAIN;
  }
  if (key == 'a' || key == 'A') {
    status = ASSIGN;
  }
  if (key == 'd' || key == 'D') {
    nodeSwitchManager();
  }
}


// Function for asigning new nodes to new switches:
void nodeSwitchManager() {
  noVisible = 0;

  // Looks for new nodes in the network:
  router.nodeDiscovery();

  // Creates new switches corresponding the nodes address:
  for (int i = 0; i < router.getNumNodes(); i++) {
    boolean notExist = true;
    String tempAddressNode = ((Node) router.getNodesArray().get(i)).getAddress().toLowerCase();
    for (int j = 0; j < switches.size() && notExist; j++) {
      String tempAddressSwitch = ((Switch) switches.get(j)).getAddress().toLowerCase();
      if (tempAddressNode.equals(tempAddressSwitch)) notExist = false;
      println(tempAddressNode);
      println(tempAddressSwitch);
      println(notExist);
    }

    if (notExist) {
      switches.add(new Switch(((Node) router.getNodesArray().get(i)).getAddress(), 
      ((Node) router.getNodesArray().get(i)).getStateP2()));
    }
    println(". . .");
  }

  // Counts the number of switches that don't have a position 
  // in the visual interface assigned:
  for (int i = 0; i< switches.size(); i++) {
    if (!switches.get(i).isVisible()) noVisible++;
  }

  println("Nodes:       " + router.getNodesArray().size());
  println("Switches:    " + switches.size());
  println("No visibles: " + noVisible);
}


// incoming osc message are forwarded to the oscEvent method
void oscEvent(OscMessage theOscMessage) {
  if(theOscMessage.addrPattern().equals("/compass")){
    rcvCompass = theOscMessage.get(0).floatValue();
  }
  if(theOscMessage.addrPattern().equals("/slider")){
    rcvSlider = theOscMessage.get(0).floatValue();
  }
  //println("Compass "+rcvCompass);
  //println("Slider "+rcvSlider);
}


//// Launches application full screen:
//boolean sketchFullScreen() {
//  return true;
//}

