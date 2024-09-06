#include <ESP8266WiFi.h>
#include <ESP8266WebServer.h>
 
ESP8266WebServer server(80);
 
const char* ssid = "Fiber Net";
const char* password =  "1B37D3A6F27";
 
int val = 0 ;

int R1=D0;  
int R2=D1;
int R3 = D2;

 void setup()  
 {  
    Serial.begin(115200);

    pinMode(R1,OUTPUT);
    pinMode(R2,OUTPUT);
    pinMode(R3,INPUT);

    WiFi.begin(ssid, password);  //Connect to the WiFi network
 
    while (WiFi.status() != WL_CONNECTED) {  
 
        delay(500);
        Serial.println("Waiting to connect...");
 
    }
 
    Serial.print("IP address: ");
    Serial.println(WiFi.localIP());  //Print the local IP
 
    server.on("/lockState", handlelockState); 
 
    server.begin(); 
    Serial.println("Server listening");  


 }  
 void loop()   
 {  
  
  server.handleClient();
  val = digitalRead(R3); 

  delay(200);

  if(val == 1 )  
  {  
   digitalWrite(R1,HIGH);
   Serial.println("Motion"); //  LED BULB ON  
  }  
  else  
  {  
   digitalWrite(R1,LOW);  
    Serial.println("No Motion"); //  LED BULB OFF  
  }  

  }  

void handlelockState() { 
 for (int i = 0; i < server.args(); i++) {

    if (server.argName(i) == "lockOpen") {

  
     digitalWrite(R2, HIGH);
     Serial.println("Lock is opened"); 
     server.send(200, "text/html",
              "Lock Opened");
      break;
     
    }
    if (server.argName(i) == "lockClose") {
  
     digitalWrite(R2, LOW);
     Serial.println("Lock is closed"); 
     server.send(200, "text/html",
              "Lock Closed");
     break;
    }
 }

}