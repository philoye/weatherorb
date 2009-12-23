#include <string.h>
#include <Ethernet.h>
#include "Dhcp.h"
#include "Wire.h"
#include "BlinkM_funcs.h"

#define BLINKM_ARDUINO_POWERED 1

// Define Constants
const int MAX_STRING_LEN = 20;   // Max string length may have to be adjusted depending on data to be extracted
const int CHECK_INTERVAL = 60;    // Check interval in seconds

// Setup vars
char tagStr[MAX_STRING_LEN]  = "";
char dataStr[MAX_STRING_LEN] = "";
char tmpStr[MAX_STRING_LEN] = "";
char endTag[3] = { '<', '/', '\0' };
int len;

// Store the forecast
int forecast_temp;
boolean rain_pulse = false;

// Flags to differentiate XML tags from document elements (ie. data)
boolean tagFlag = false;
boolean dataFlag = false;

byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
byte server[] = { 75, 101, 163, 44 };
byte port = 80;

boolean ipAcquired = false;
Client client(server, port);

void setup() {
  Serial.begin(9600);

  if( BLINKM_ARDUINO_POWERED ) {
      BlinkM_beginWithPower();
  } else {
      BlinkM_begin();
  }
  BlinkM_playScript( 0x00, 2,0,0 ); // play a script while we’re waiting to show no data received yet
  BlinkM_setFadeSpeed(0x00, 10);

  Serial.println("getting ip...");
  int result = Dhcp.beginWithDHCP(mac);

  if(result == 1) {
    ipAcquired = true;
    byte buffer[6];
    
    Dhcp.getMacAddress(buffer);
    Dhcp.getLocalIp(buffer);
/*    Serial.print("Local IP address: ");*/
/*    printArray(&Serial, ".", buffer, 4, 10);*/
    Dhcp.getSubnetMask(buffer);
    Dhcp.getGatewayIp(buffer);
/*    Serial.print("Gateway IP address: ");*/
/*    printArray(&Serial, ".", buffer, 4, 10);*/
    Dhcp.getDhcpServerIp(buffer);
    Dhcp.getDnsServerIp(buffer);
    
    delay(5000);
/*    Serial.println("connecting...");*/

    if (client.connect()) {
      Serial.println("connected");
      client.println("GET http://weatherorb.heroku.com/weather.xml HTTP/1.0");
      client.println();
      delay(3000);
    } else {
      Serial.println("connection failed");
    }
    BlinkM_stopScript( 0 ); // turn off startup script
  } else {
    Serial.println("unable to acquire ip address...");
  }
}

void loop() {

  while (client.available()) {
    serialEvent();
  }

  if (!client.connected()) {
    client.stop();

    for (int t = 1; t <= CHECK_INTERVAL; t++) {
      Serial.println(CHECK_INTERVAL + 1 - t);
      delay(1000);
    }

    if (client.connect()) {
      client.println("GET http://weatherorb.heroku.com/weather.xml HTTP/1.0");
      client.println();
      delay(2000);
    } else {
      Serial.println("Reconnect failed");
    }      
  }
}

////////////////////
// Weather Functions
////////////////////

void processRain(char* str) {
  int condition_code = atoi(str);
  rain_pulse = false;
  switch (condition_code) {
    case 3: // heavy rain
    case 4:
    case 37:
    case 38:
    case 39:
    case 45:
    case 47:
      rain_pulse = true;
      break;
    case 9: // uh, medium rain?
      rain_pulse = true;
      break;
    case 11: // light rain?
    case 12:
      rain_pulse = true;
      break;
    default:
      break;
  }
}

void processTemp(char* str) {
  Serial.print(str);
  forecast_temp = atoi(str);

  if (forecast_temp > 35) {
    BlinkM_fadeToRGB(0x00, 255, 0, 0 ); // red
    Serial.println(" VERY HOT ");
  } else if (forecast_temp > 31) {
    BlinkM_fadeToRGB(0x00, 255, 30, 0 ); // orange
    Serial.println(" HOT ");
  } else if (forecast_temp > 29) {
    BlinkM_fadeToRGB(0x00, 255, 60, 0 ); // orange
    Serial.println(" HOT ");
  } else if (forecast_temp > 27) {
    BlinkM_fadeToRGB(0x00, 255, 90, 0 ); // orange
    Serial.println(" HOT ");
  } else if (forecast_temp > 24) {
    BlinkM_fadeToRGB(0x00, 255, 120, 0 ); // orange
    Serial.println(" HOT ");
  } else if (forecast_temp < 14) {
    BlinkM_fadeToRGB(0x00, 0, 0, 255 ); // blue
    Serial.println(" REALLY COLD ");
  } else if (forecast_temp < 19) {
    BlinkM_fadeToRGB(0x00, 127, 127, 255 ); // light blue
    Serial.println(" COLD ");
  } else {
    BlinkM_fadeToRGB(0x00, 0, 255, 0 ); // green
    Serial.println(" NICE ");
  }
}

/////////////////////
// Process each char from web
/////////////////////

void serialEvent() {

  char inChar = client.read();

  if (inChar == '<') {
    addChar(inChar, tmpStr);
    tagFlag = true;
    dataFlag = false;
  } else if (inChar == '>') {
    addChar(inChar, tmpStr);
    if (tagFlag) {      
       strncpy(tagStr, tmpStr, strlen(tmpStr)+1);
    }
    clearStr(tmpStr);
    tagFlag = false;
    dataFlag = true;      
  
  } else if (inChar != 10) {
    if (tagFlag) {
      // Add tag char to string
      addChar(inChar, tmpStr);

      // Check for </XML> end tag, ignore it
      if ( tagFlag && strcmp(tmpStr, endTag) == 0 ) {
        clearStr(tmpStr);
        tagFlag = false;
        dataFlag = false;
      }
    }
      
    if (dataFlag) {
      // Add data char to string
      addChar(inChar, dataStr);
    }
  }  

  // If a LF, process the line
  if (inChar == 10 ) {

  if (matchTag("<forecast_code>")) {
    Serial.print("High: ");
    processRain(dataStr);
  }
  if (matchTag("<high>")) {
    Serial.print("High: ");
    processTemp(dataStr);
  }
  client.println();

  // Clear all strings
  clearStr(tmpStr);
  clearStr(tagStr);
  clearStr(dataStr);

  // Clear Flags
  tagFlag = false;
  dataFlag = false;
  }
}

/////////////////////
// XML Functions
/////////////////////

// Function to clear a string
void clearStr (char* str) {
  int len = strlen(str);
  for (int c = 0; c < len; c++) {
    str[c] = 0;
  }
}

//Function to add a char to a string and check its length
void addChar (char ch, char* str) {
  char *tagMsg  = "<TRUNCATED_TAG>";
  char *dataMsg = "-TRUNCATED_DATA-";

  // Check the max size of the string to make sure it doesn't grow too
  // big.  If string is beyond MAX_STRING_LEN assume it is unimportant
  // and replace it with a warning message.
  if (strlen(str) > MAX_STRING_LEN - 2) {
    if (tagFlag) {
      clearStr(tagStr);
      strcpy(tagStr,tagMsg);
    }
    if (dataFlag) {
      clearStr(dataStr);
      strcpy(dataStr,dataMsg);
    }

    // Clear the temp buffer and flags to stop current processing
    clearStr(tmpStr);
    tagFlag = false;
    dataFlag = false;

  } else {
    // Add char to string
    str[strlen(str)] = ch;
  }
}

// Function to check the current tag for a specific string
boolean matchTag (char* searchTag) {
  if ( strcmp(tagStr, searchTag) == 0 ) {
    return true;
  } else {
    return false;
  }
}

void printArray(Print *output, char* delimeter, byte* data, int len, int base) {
  char buf[10] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
  for(int i = 0; i < len; i++) {
    if(i != 0) {
      output->print(delimeter);
    }
    output->print(itoa(data[i], buf, base));
  }
  output->println();
}