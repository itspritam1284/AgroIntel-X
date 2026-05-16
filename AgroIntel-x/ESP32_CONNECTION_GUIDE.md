# ESP32 Rower Connection Troubleshooting Guide

## 🔧 Step-by-Step Setup Instructions

### 1. **Upload the Fixed Code to ESP32**
   - Open `esp32_rower_controller/esp32_rower_controller.ino` in Arduino IDE
   - Select your ESP32 board (Tools → Board → ESP32 Dev Module)
   - Select the correct COM port (Tools → Port)
   - Click Upload ⬆️

### 2. **Open Serial Monitor**
   - After upload, open Serial Monitor (Tools → Serial Monitor)
   - Set baud rate to **115200**
   - You should see:
     ```
     ========================================
     ESP32 Rower Controller Starting...
     ========================================
     Connecting to WiFi.......
     ✅ WiFi Connected Successfully!
     ========================================
     📱 IP Address: 192.168.xxx.xxx  ← COPY THIS!
     📶 Signal Strength: -45 dBm
     ========================================
     Copy this IP to your Flutter app!
     ========================================
     ```

### 3. **Update Flutter App with ESP32 IP**
   - In your Flutter app, tap the **Settings icon** (⚙️) in the top-right
   - Enter the IP address from Serial Monitor
   - Tap "Save & Connect"

---

## ❌ Common Issues & Solutions

### **Issue 1: "WiFi Connection Failed"**
**Symptoms:** Serial Monitor shows connection timeout

**Solutions:**
- ✅ Verify hotspot name is exactly: `Narzo 70 5G`
- ✅ Verify password is exactly: `123456789`
- ✅ Make sure your phone's hotspot is ON
- ✅ Check if hotspot allows 2.4GHz connections (ESP32 doesn't support 5GHz)
- ✅ Try moving ESP32 closer to your phone

**How to fix in code:**
```cpp
const char* ssid = "YOUR_EXACT_HOTSPOT_NAME";
const char* password = "YOUR_EXACT_PASSWORD";
```

---

### **Issue 2: "Cannot connect to ESP32" in Flutter App**
**Symptoms:** App shows "Offline" status

**Solutions:**
- ✅ Check Serial Monitor for the correct IP address
- ✅ Make sure your phone is connected to the SAME hotspot
- ✅ Update the IP in Flutter app settings
- ✅ Tap the Refresh icon (🔄) to reconnect

**Test connection manually:**
- Open browser on your phone
- Go to: `http://YOUR_ESP32_IP/status`
- You should see "OK"

---

### **Issue 3: ESP32 Connects but Commands Don't Work**
**Symptoms:** Connected but buttons don't respond

**Solutions:**
- ✅ Check Serial Monitor for command logs
- ✅ Verify motor driver connections
- ✅ Check power supply to motors
- ✅ Test individual endpoints in browser:
  - `http://YOUR_ESP32_IP/forward`
  - `http://YOUR_ESP32_IP/stop`

---

### **Issue 4: IP Address Keeps Changing**
**Symptoms:** Need to update IP every time ESP32 restarts

**Solution: Set Static IP (Optional)**
Add this code after `WiFi.begin()`:

```cpp
// Set static IP (optional)
IPAddress local_IP(192, 168, 43, 100);  // Change to your network
IPAddress gateway(192, 168, 43, 1);
IPAddress subnet(255, 255, 255, 0);

if (!WiFi.config(local_IP, gateway, subnet)) {
  Serial.println("Static IP Failed");
}
```

---

## 🔍 Quick Diagnostic Checklist

Before asking for help, verify:

- [ ] ESP32 shows "WiFi Connected" in Serial Monitor
- [ ] IP address is displayed in Serial Monitor
- [ ] Phone is connected to the same hotspot
- [ ] Can access `http://ESP32_IP/status` in phone browser
- [ ] IP address in Flutter app matches Serial Monitor
- [ ] Tapped Refresh button in Flutter app

---

## 📱 How to Find ESP32 IP Address

### Method 1: Serial Monitor (Recommended)
1. Open Arduino IDE
2. Tools → Serial Monitor
3. Set baud rate to 115200
4. Look for: `📱 IP Address: xxx.xxx.xxx.xxx`

### Method 2: Phone Hotspot Settings
1. Open phone Settings
2. Go to Hotspot settings
3. Look for "Connected Devices"
4. Find "ESP32" device
5. Note the IP address

### Method 3: Network Scanner App
1. Install "Fing" or similar network scanner
2. Scan network
3. Look for "Espressif" device

---

## 🎯 Expected Behavior

When everything works correctly:

1. **ESP32 Serial Monitor:**
   ```
   ✅ WiFi Connected Successfully!
   📱 IP Address: 192.168.43.10
   🌐 Web Server Started!
   📡 Status check received
   ⬆️ Moving Forward
   🛑 Stopped
   ```

2. **Flutter App:**
   - Shows "Connected" status (green)
   - IP address displayed in header
   - All buttons respond instantly
   - Status updates in real-time

---

## 🚀 Advanced Troubleshooting

### Enable Debug Mode
Add this to see more details:

```cpp
void loop() {
  server.handleClient();
  
  // Print WiFi status every 10 seconds
  static unsigned long lastCheck = 0;
  if (millis() - lastCheck > 10000) {
    Serial.print("WiFi Status: ");
    Serial.println(WiFi.status() == WL_CONNECTED ? "Connected" : "Disconnected");
    Serial.print("IP: ");
    Serial.println(WiFi.localIP());
    lastCheck = millis();
  }
}
```

### Test Individual Components

**Test Buzzer:**
```cpp
void setup() {
  // ... existing code ...
  
  // Test buzzer on startup
  digitalWrite(BUZZER_PIN, HIGH);
  delay(500);
  digitalWrite(BUZZER_PIN, LOW);
}
```

**Test Motors:**
```cpp
void setup() {
  // ... existing code ...
  
  // Test motors on startup
  forward();
  delay(1000);
  stopMotor();
}
```

---

## 📞 Still Having Issues?

If none of the above solutions work:

1. **Check your hardware connections**
2. **Verify ESP32 board is working** (upload a simple blink sketch)
3. **Try a different WiFi network**
4. **Check ESP32 power supply** (needs stable 5V)
5. **Look for error messages** in Serial Monitor

---

## 🎉 Success Indicators

You'll know it's working when:
- ✅ Serial Monitor shows IP address
- ✅ Flutter app shows "Connected" (green)
- ✅ Buttons respond instantly
- ✅ Serial Monitor logs each command
- ✅ Motors move as expected
- ✅ Buzzer sounds on reverse
- ✅ Spray pump toggles correctly
