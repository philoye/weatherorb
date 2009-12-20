//////////////////////////////////////////////
//
//////////////////////////////////////////////

#include <string.h>
#include <Ethernet.h>
#include "Dhcp.h"

// Define Constants
const int MAX_STRING_LEN = 20;   // Max string length may have to be adjusted depending on data to be extracted
const int CHECK_INTERVAL = 300;    // Check interval in seconds

// Setup vars
char tagStr[MAX_STRING_LEN]  = "";
char dataStr[MAX_STRING_LEN] = "";
char tmpStr[MAX_STRING_LEN] = "";
char endTag[3] = {'<', '/', '\0'};
int len;

// Flags to differentiate XML tags from document elements (ie. data)
boolean tagFlag = false;
boolean dataFlag = false;

byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
byte server[] = { 75, 101, 163, 44 }; // heroku's primary ip address
boolean ipAcquired = false;

Client client(server, 80);

void setup() {
  Serial.begin(9600);

  client.println();
  client.println();
  Serial.println("getting ip...");
  int result = Dhcp.beginWithDHCP(mac);

  if(result == 1) {
    ipAcquired = true;
    byte buffer[6];
    
    Dhcp.getMacAddress(buffer);
    Dhcp.getLocalIp(buffer);
    Serial.print("Local IP Address: ");
    printArray(&Serial, ".", buffer, 4, 10);
    Dhcp.getSubnetMask(buffer);
    Serial.print("Subnet mask: ");
    printArray(&Serial, ".", buffer, 4, 10);
    Dhcp.getGatewayIp(buffer);
    Serial.print("Gateway IP Address: ");
    printArray(&Serial, ".", buffer, 4, 10);
    Dhcp.getDhcpServerIp(buffer);
    Dhcp.getDnsServerIp(buffer);
    
    delay(3000);
    
    Serial.println("connecting...");

    if (client.connect()) {
      Serial.println("connected");
      client.println("GET http://weatherorb.heroku.com/weather.xml HTTP/1.0");
      client.println();
      delay(3000);
    } else {
      Serial.println("connection failed");
    }
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

// Process each char from web
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

      if (matchTag("<condition>")) {
	 Serial.print("Condition: ");
         Serial.print(dataStr);
      }
      if (matchTag("<temp>")) {
	 Serial.print(" Current: ");
         processTemp(dataStr);
      }
      if (matchTag("<forecast>")) {
	 Serial.print("Forecast: ");
         Serial.print(dataStr);
      }
      if (matchTag("<high>")) {
	 Serial.print(", High: ");
         processTemp(dataStr);
      }
      if (matchTag("<low>")) {
	 Serial.print(", Low: ");
         processTemp(dataStr);
         Serial.println("");
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
// Weather Functions
/////////////////////

void processTemp(char* str) {
   Serial.print(str);
   int t = atoi(str);
   if (t > 30) {
     Serial.print(" HOT ");
   } else if (t < 17) {
     Serial.print(" COLD ");
   } else {
     Serial.print(" NICE ");
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



