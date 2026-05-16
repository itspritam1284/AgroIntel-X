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
#define LIGHT_PIN 5   // Relay safe GPIO

WebServer server(80);

// -------- Reverse Buzzer Control --------
bool reverseMode = false;
bool buzzerState = false;
unsigned long lastBuzzerTime = 0;

void setup() {
  Serial.begin(115200);

  // Motor Pins
  pinMode(IN1, OUTPUT); pinMode(IN2, OUTPUT);
  pinMode(IN3, OUTPUT); pinMode(IN4, OUTPUT);
  pinMode(ENA, OUTPUT); pinMode(ENB, OUTPUT);

  // Relay, Buzzer, Light Pins
  pinMode(RELAY_PIN, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(LIGHT_PIN, OUTPUT);

  // Default states
  digitalWrite(RELAY_PIN, HIGH);    // Pump OFF
  digitalWrite(BUZZER_PIN, LOW);    // Buzzer OFF
  digitalWrite(LIGHT_PIN, HIGH);    // Light OFF by default (Active LOW relay)

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

  server.begin();
  Serial.println("🌐 HTTP Server Started");
}

void loop() {
  server.handleClient();
  handleReverseBuzzer();
}

// -------- Handlers --------
void handleRoot() { server.send(200, "text/plain", "ESP32 Rower Ready"); }

void handleForward() { reverseMode = false; buzzerOff(); forward(); server.send(200, "text/plain", "OK"); }
void handleBack()    { reverseMode = true; back(); server.send(200, "text/plain", "OK"); }
void handleLeft()    { reverseMode = false; buzzerOff(); left(); server.send(200, "text/plain", "OK"); }
void handleRight()   { reverseMode = false; buzzerOff(); right(); server.send(200, "text/plain", "OK"); }
void handleStop()    { reverseMode = false; buzzerOff(); stopMotor(); server.send(200, "text/plain", "OK"); }

void handleSprayOn() { digitalWrite(RELAY_PIN, LOW); server.send(200, "text/plain", "OK"); }
void handleSprayOff(){ digitalWrite(RELAY_PIN, HIGH); server.send(200, "text/plain", "OK"); }

// 💡 Light control (Active LOW relay)
void handleLightOn()  { 
  digitalWrite(LIGHT_PIN, LOW);  // Relay ON
  server.send(200, "text/plain", "LIGHT ON"); 
}

void handleLightOff() { 
  digitalWrite(LIGHT_PIN, HIGH); // Relay OFF
  server.send(200, "text/plain", "LIGHT OFF"); 
}

// -------- Reverse Buzzer (500 ms blink) --------
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

void buzzerOff() { buzzerState = false; digitalWrite(BUZZER_PIN, LOW); }

// -------- Motor Functions --------
void forward()  { 
  digitalWrite(IN1,HIGH); digitalWrite(IN2,LOW);
  digitalWrite(IN3,HIGH); digitalWrite(IN4,LOW);
  analogWrite(ENA,200); analogWrite(ENB,200);
}

void back() { 
  digitalWrite(IN1,LOW); digitalWrite(IN2,HIGH);
  digitalWrite(IN3,LOW); digitalWrite(IN4,HIGH);
  analogWrite(ENA,200); analogWrite(ENB,200);
}

void left() { 
  digitalWrite(IN1,LOW); digitalWrite(IN2,HIGH);
  digitalWrite(IN3,HIGH); digitalWrite(IN4,LOW);
  analogWrite(ENA,200); analogWrite(ENB,200);
}

void right() { 
  digitalWrite(IN1,HIGH); digitalWrite(IN2,LOW);
  digitalWrite(IN3,LOW); digitalWrite(IN4,HIGH);
  analogWrite(ENA,200); analogWrite(ENB,200);
}

void stopMotor() {
  digitalWrite(IN1,LOW); digitalWrite(IN2,LOW);
  digitalWrite(IN3,LOW); digitalWrite(IN4,LOW);
  analogWrite(ENA,0); analogWrite(ENB,0);
}
