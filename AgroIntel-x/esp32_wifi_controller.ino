/* 
  ESP32 Rower Controller - Station Mode
  Reverse = Buzzer Beep (500 ms ON / OFF)
  Light Control via Mobile
*/

#include <WiFi.h>
#include <WebServer.h>

// -------- HOTSPOT CREDENTIALS --------
const char* ssid = "Narzo 70 5G";     
const char* password = "123456789";   

// -------- L298N Motor Driver Pins --------
#define IN1 27
#define IN2 26
#define IN3 25
#define IN4 33
#define ENA 14
#define ENB 12

// -------- Relay (12V Pump) --------
#define RELAY_PIN 4   // Active LOW relay

// -------- Buzzer --------
#define BUZZER_PIN 13

// -------- Light (Relay) --------
#define LIGHT_PIN 5   // Active LOW relay

// -------- Sowing & Cutting --------
#define PAIRNI_PIN 18
#define CUT_PIN 19

// -------- Ultrasonic Sensor --------
#define TRIG_PIN 2
#define ECHO_PIN 15
#define OBSTACLE_THRESHOLD 35 // Distance in cm to stop

WebServer server(80);

// -------- Control States --------
bool reverseMode = false;
bool forwardMode = false;
bool buzzerState = false;
unsigned long lastBuzzerTime = 0;

void setup() {
  Serial.begin(115200);

  // Motor Pins
  pinMode(IN1, OUTPUT); pinMode(IN2, OUTPUT);
  pinMode(IN3, OUTPUT); pinMode(IN4, OUTPUT);
  pinMode(ENA, OUTPUT); pinMode(ENB, OUTPUT);

  // Aux Pins
  pinMode(RELAY_PIN, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(LIGHT_PIN, OUTPUT);
  pinMode(PAIRNI_PIN, OUTPUT);
  pinMode(CUT_PIN, OUTPUT);

  // Ultrasonic Pins
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);

  // Default states
  digitalWrite(RELAY_PIN, HIGH);    
  digitalWrite(BUZZER_PIN, LOW);    
  digitalWrite(LIGHT_PIN, HIGH);    
  digitalWrite(PAIRNI_PIN, LOW);    
  digitalWrite(CUT_PIN, LOW);       

  stopMotor();

  // -------- WiFi Connect --------
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);

  Serial.print("Connecting");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("\n✅ WiFi Connected");
  Serial.print("📱 IP Address: ");
  Serial.println(WiFi.localIP());

  // -------- Server Routes --------
  server.on("/", handleRoot);
  server.on("/forward", handleForward);
  server.on("/back", handleBack);
  server.on("/left", handleLeft);
  server.on("/right", handleRight);
  server.on("/stop", handleStop);
  
  server.on("/spray_on", handleSprayOn);
  server.on("/spray_off", handleSprayOff);
  server.on("/light_on", handleLightOn);
  server.on("/light_off", handleLightOff);
  
  server.on("/pairni_on", handlePairniOn);
  server.on("/pairni_off", handlePairniOff);
  server.on("/cut_on", handleCutOn);
  server.on("/cut_off", handleCutOff);

  server.on("/status", handleStatus);

  server.begin();
  Serial.println("🌐 HTTP Server Started");
}

void loop() {
  server.handleClient();
  handleReverseBuzzer();
  handleObstacleDetection();
}

// -------- Handlers --------
void handleRoot() { server.send(200, "text/plain", "ESP32 Rower Ready"); }
void handleStatus() { server.send(200, "text/plain", "OK"); }

void handleForward() { forwardMode = true; reverseMode = false; buzzerOff(); forward(); server.send(200, "text/plain", "OK"); }
void handleBack()    { forwardMode = false; reverseMode = true; back(); server.send(200, "text/plain", "OK"); }
void handleLeft()    { forwardMode = false; reverseMode = false; buzzerOff(); left(); server.send(200, "text/plain", "OK"); }
void handleRight()   { forwardMode = false; reverseMode = false; buzzerOff(); right(); server.send(200, "text/plain", "OK"); }
void handleStop()    { forwardMode = false; reverseMode = false; buzzerOff(); stopMotor(); server.send(200, "text/plain", "OK"); }

void handleSprayOn() { digitalWrite(RELAY_PIN, LOW); server.send(200, "text/plain", "OK"); }
void handleSprayOff()){ digitalWrite(RELAY_PIN, HIGH); server.send(200, "text/plain", "OK"); }

void handleLightOn()  { 
  digitalWrite(LIGHT_PIN, LOW);
  server.send(200, "text/plain", "LIGHT ON"); 
}

void handleLightOff() { 
  digitalWrite(LIGHT_PIN, HIGH);
  server.send(200, "text/plain", "LIGHT OFF"); 
}

void handlePairniOn() { digitalWrite(PAIRNI_PIN, HIGH); server.send(200, "text/plain", "OK"); }
void handlePairniOff() { digitalWrite(PAIRNI_PIN, LOW); server.send(200, "text/plain", "OK"); }

void handleCutOn() { digitalWrite(CUT_PIN, HIGH); server.send(200, "text/plain", "OK"); }
void handleCutOff() { digitalWrite(CUT_PIN, LOW); server.send(200, "text/plain", "OK"); }

// -------- Obstacle Detection --------
void handleObstacleDetection() {
  if (forwardMode) {
    long distance = getDistance();
    if (distance > 0 && distance < OBSTACLE_THRESHOLD) {
      Serial.print("⚠️ Obstacle Detected! Distance: ");
      Serial.print(distance);
      Serial.println(" cm. Stopping!");
      
      stopMotor();
      forwardMode = false;
    }
  }
}

long getDistance() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);
  
  long duration = pulseIn(ECHO_PIN, HIGH, 30000); // 30ms timeout (~5 meters)
  if (duration == 0) return -1;
  
  long distance = duration * 0.034 / 2;
  return distance;
}

// -------- Reverse Buzzer --------
void handleReverseBuzzer() {
  if (reverseMode) {
    unsigned long currentTime = millis();
    if (currentTime - lastBuzzerTime >= 500) {
      lastBuzzerTime = currentTime;
      buzzerState = !buzzerState;
      digitalWrite(BUZZER_PIN, buzzerState);
    }
  } else {
    buzzerOff();
  }
}

void buzzerOff() { 
  buzzerState = false; 
  digitalWrite(BUZZER_PIN, LOW); 
}

// -------- Motor Functions --------

void forward() { 
  digitalWrite(IN1,HIGH); digitalWrite(IN2,LOW);
  digitalWrite(IN3,HIGH); digitalWrite(IN4,LOW);
  analogWrite(ENA,200); analogWrite(ENB,200);
}

void back() { 
  digitalWrite(IN1,LOW); digitalWrite(IN2,HIGH);
  digitalWrite(IN3,LOW); digitalWrite(IN4,HIGH);
  analogWrite(ENA,200); analogWrite(ENB,200);
}

// ✅ FIXED LEFT
void left() { 
  digitalWrite(IN1,HIGH); digitalWrite(IN2,LOW);
  digitalWrite(IN3,LOW);  digitalWrite(IN4,HIGH);
  analogWrite(ENA,200); analogWrite(ENB,200);
}

// ✅ FIXED RIGHT
void right() { 
  digitalWrite(IN1,LOW);  digitalWrite(IN2,HIGH);
  digitalWrite(IN3,HIGH); digitalWrite(IN4,LOW);
  analogWrite(ENA,200); analogWrite(ENB,200);
}

void stopMotor() {
  digitalWrite(IN1,LOW); digitalWrite(IN2,LOW);
  digitalWrite(IN3,LOW); digitalWrite(IN4,LOW);
  analogWrite(ENA,0); analogWrite(ENB,0);
}