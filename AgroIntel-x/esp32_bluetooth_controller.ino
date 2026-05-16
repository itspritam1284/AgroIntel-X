/* Code created by @Balaji Electrical and Techno Hub
   Location: Ambegaon B.K, Pune
*/

#include <BluetoothSerial.h>
BluetoothSerial SerialBT;

// -------- L298N Motor Driver Pins --------
#define IN1 27
#define IN2 26
#define IN3 25
#define IN4 33
#define ENA 14
#define ENB 12

// -------- Relay (12V Pump) --------
#define RELAY_PIN 4   // Active LOW relay

void setup() {
  Serial.begin(9600);
  SerialBT.begin("ESP32_SPRAY_ROBOT"); // Bluetooth Name

  pinMode(IN1, OUTPUT); pinMode(IN2, OUTPUT);
  pinMode(IN3, OUTPUT); pinMode(IN4, OUTPUT);
  pinMode(ENA, OUTPUT); pinMode(ENB, OUTPUT);

  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, HIGH); // Pump OFF
}

void loop() {
  if (SerialBT.available()) {
    String cmd = SerialBT.readString();
    cmd.toLowerCase();
    Serial.println(cmd);

    // -------- Robot Movement --------
    if (cmd.indexOf("forward") >= 0) forward();
    else if (cmd.indexOf("back") >= 0) back();
    else if (cmd.indexOf("left") >= 0) left();
    else if (cmd.indexOf("right") >= 0) right();
    else if (cmd.indexOf("stop") >= 0) stopMotor();

    // -------- Pump Control --------
    else if (cmd.indexOf("spray on") >= 0 || cmd.indexOf("pump on") >= 0) {
      digitalWrite(RELAY_PIN, LOW);   // Pump ON
      SerialBT.println("SPRAY ON");
    }
    else if (cmd.indexOf("spray off") >= 0 || cmd.indexOf("pump off") >= 0) {
      digitalWrite(RELAY_PIN, HIGH);  // Pump OFF
      SerialBT.println("SPRAY OFF");
    }
  }
}

// -------- Motor Functions --------
void forward() {
  digitalWrite(IN1, HIGH); digitalWrite(IN2, LOW);
  digitalWrite(IN3, HIGH); digitalWrite(IN4, LOW);
  analogWrite(ENA, 200);
  analogWrite(ENB, 200);
}

void back() {
  digitalWrite(IN1, LOW); digitalWrite(IN2, HIGH);
  digitalWrite(IN3, LOW); digitalWrite(IN4, HIGH);
}

void left() {
  digitalWrite(IN1, LOW); digitalWrite(IN2, HIGH);
  digitalWrite(IN3, HIGH); digitalWrite(IN4, LOW);
}

void right() {
  digitalWrite(IN1, HIGH); digitalWrite(IN2, LOW);
  digitalWrite(IN3, LOW); digitalWrite(IN4, HIGH);
}

void stopMotor() {
  digitalWrite(IN1, LOW); digitalWrite(IN2, LOW);
  digitalWrite(IN3, LOW); digitalWrite(IN4, LOW);
}