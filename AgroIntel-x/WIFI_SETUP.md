# 📶 WiFi/Hotspot Setup Guide - ESP32 Rower Control

## ✅ What Changed - Back to WiFi!

We've switched from Bluetooth back to **WiFi/Hotspot** for better compatibility!

### **Changes Made:**
1. ✅ **ESP32 Code**: Now creates its own WiFi hotspot
2. ✅ **Flutter App**: Uses HTTP requests instead of Bluetooth
3. ✅ **Removed**: All Bluetooth packages and permissions
4. ✅ **Hardware**: Same pins, no changes needed!

---

## 🔧 Hardware Setup (No Changes)

### **L298N Motor Driver**
```
ESP32 → L298N
GPIO 27 → IN1
GPIO 26 → IN2
GPIO 25 → IN3
GPIO 33 → IN4
GPIO 14 → ENA (PWM)
GPIO 12 → ENB (PWM)
```

### **Relay Module (12V Pump)**
```
ESP32 → Relay
GPIO 4 → Relay IN (Active LOW)
```

---

## 📱 Setup Instructions

### **Step 1: Upload ESP32 Code**

1. Open **Arduino IDE**
2. Open file: `esp32_wifi_controller.ino`
3. Select **Board**: ESP32 Dev Module
4. Select **Port**: Your ESP32 COM port
5. Click **Upload** ⬆️

### **Step 2: Check Serial Monitor**

After upload, open Serial Monitor (115200 baud):
```
Creating WiFi Hotspot...
Hotspot IP address: 192.168.4.1
Connect your phone to: ESP32_SPRAY_ROBOT
Password: 12345678
HTTP server started!
Ready to receive commands
```

### **Step 3: Connect Phone to ESP32 Hotspot**

1. Go to **Phone Settings → WiFi**
2. Find network: **ESP32_SPRAY_ROBOT**
3. Password: **12345678**
4. Connect ✅

### **Step 4: Run Flutter App**

```bash
flutter run
```

The app will automatically connect to `192.168.4.1`

---

## 🎯 How It Works

### **ESP32 WiFi Hotspot**
- **Network Name**: ESP32_SPRAY_ROBOT
- **Password**: 12345678
- **IP Address**: 192.168.4.1 (fixed)
- **Port**: 80 (HTTP)

### **Flutter App**
- Connects to ESP32 via WiFi
- Sends HTTP GET requests
- Default IP: 192.168.4.1

### **Commands (HTTP Endpoints)**
```
http://192.168.4.1/forward    → Move forward
http://192.168.4.1/back       → Move backward
http://192.168.4.1/left       → Turn left
http://192.168.4.1/right      → Turn right
http://192.168.4.1/stop       → Stop motors
http://192.168.4.1/spray_on   → Pump ON
http://192.168.4.1/spray_off  → Pump OFF
http://192.168.4.1/status     → Check connection
```

---

## 🌐 Web Interface (Bonus!)

You can also control the rower from a web browser!

1. Connect to **ESP32_SPRAY_ROBOT** WiFi
2. Open browser
3. Go to: **http://192.168.4.1**
4. You'll see a beautiful control interface! 🎨

---

## 🔧 Customization

### **Change WiFi Name/Password**

Edit in `esp32_wifi_controller.ino`:
```cpp
const char* ssid = "ESP32_SPRAY_ROBOT";  // Change this
const char* password = "12345678";        // Change this (min 8 chars)
```

### **Change IP Address (in Flutter app)**

If you need to change the IP, tap the **Settings icon** in the app and enter the new IP.

---

## 🐛 Troubleshooting

### **Can't find ESP32_SPRAY_ROBOT WiFi**
```
✓ Check ESP32 is powered on
✓ Check code uploaded successfully
✓ Check Serial Monitor for "HTTP server started!"
✓ Restart ESP32
```

### **App shows "Connection Failed"**
```
✓ Make sure phone is connected to ESP32_SPRAY_ROBOT WiFi
✓ Check IP address is 192.168.4.1
✓ Try tapping Settings icon and reconnecting
✓ Restart the app
```

### **Commands not working**
```
✓ Check Serial Monitor for command logs
✓ Verify motor driver connections
✓ Check power supply to motors
✓ Test with web browser first (http://192.168.4.1)
```

### **Pump spray toggle disabled**
```
✓ Make sure you're connected to ESP32 WiFi
✓ Check connection status shows "Connected" (green)
✓ Toggle will only work when connected
```

---

## 📊 Comparison: WiFi vs Bluetooth

### **WiFi Hotspot (Current)**
- ✅ No pairing needed
- ✅ Works with web browser too
- ✅ Easier to debug
- ✅ More stable connection
- ✅ Can connect multiple devices
- ❌ Requires WiFi connection

### **Bluetooth (Previous)**
- ✅ No WiFi needed
- ✅ Lower power consumption
- ❌ Pairing required
- ❌ Permission issues on Android
- ❌ Only one device at a time
- ❌ Harder to debug

---

## 🎮 Testing Checklist

Before using:
- [ ] ESP32 code uploaded
- [ ] Serial Monitor shows "HTTP server started!"
- [ ] Phone connected to ESP32_SPRAY_ROBOT WiFi
- [ ] App shows "Connected" status (green)
- [ ] Test web interface works (http://192.168.4.1)
- [ ] Test all movement buttons
- [ ] Test pump spray toggle

---

## 📝 Quick Reference

### **WiFi Credentials**
```
Network: ESP32_SPRAY_ROBOT
Password: 12345678
IP: 192.168.4.1
```

### **Flutter App**
```
Default IP: 192.168.4.1
Can change in Settings
```

### **Web Browser**
```
URL: http://192.168.4.1
Works on any device connected to ESP32 WiFi
```

---

## 🚀 Ready to Go!

Your system is now configured for **WiFi/Hotspot** operation!

1. ✅ Upload `esp32_wifi_controller.ino`
2. ✅ Connect phone to ESP32_SPRAY_ROBOT
3. ✅ Run Flutter app
4. ✅ Control your rower! 🚜

---

**Created by**: @Balaji Electrical and Techno Hub  
**Location**: Ambegaon B.K, Pune  
**Version**: 3.0.0 (WiFi/Hotspot)  
**Date**: 2026-01-23
