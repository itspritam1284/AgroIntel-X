# Rower Control - Bluetooth Setup Guide

## 📱 Overview
The Rower Control system now uses **Bluetooth** instead of WiFi/Hotspot for communication between the Flutter app and the ESP32 controller.

## 🔧 Hardware Setup

### ESP32 Configuration
- **Device Name**: `ESP32_SPRAY_ROBOT`
- **Communication**: Bluetooth Serial (Classic Bluetooth)
- **Code File**: `esp32_bluetooth_controller.ino`

### Pin Configuration (L298N Motor Driver)
- **IN1**: GPIO 27
- **IN2**: GPIO 26
- **IN3**: GPIO 25
- **IN4**: GPIO 33
- **ENA**: GPIO 14 (PWM for speed control)
- **ENB**: GPIO 12 (PWM for speed control)

### Relay Configuration
- **RELAY_PIN**: GPIO 4 (Active LOW for 12V pump control)

## 📲 Mobile App Setup

### 1. Pair ESP32 with Your Phone
Before using the app, you need to pair your phone with the ESP32:

1. Upload `esp32_bluetooth_controller.ino` to your ESP32 dev module
2. Power on the ESP32
3. On your phone, go to **Settings → Bluetooth**
4. Look for **ESP32_SPRAY_ROBOT** in available devices
5. Tap to pair (no PIN required)

### 2. Using the App

1. Open the Farmer IoT Sensors app
2. Navigate to **Rower Control** screen
3. Tap the **Bluetooth icon** in the top-right corner
4. Select **ESP32_SPRAY_ROBOT** from the list of paired devices
5. Wait for connection confirmation
6. Once connected, you can control the rower!

## 🎮 Available Commands

### Movement Controls
- **Forward**: Move the rower forward
- **Backward**: Move the rower backward
- **Left**: Turn left
- **Right**: Turn right
- **Stop**: Stop all motors

### Speed Modes
- **Normal Mode**: 60% speed (PWM 200)
- **Turbo Mode**: 100% speed (PWM 255)

### Spray Control
- **Spray On**: Activate the 12V pump (relay LOW)
- **Spray Off**: Deactivate the pump (relay HIGH)

## 🔌 Bluetooth Commands (Sent to ESP32)

| Command | Action |
|---------|--------|
| `forward` | Move forward |
| `back` | Move backward |
| `left` | Turn left |
| `right` | Turn right |
| `stop` | Stop motors |
| `spray on` or `pump on` | Turn pump ON |
| `spray off` or `pump off` | Turn pump OFF |

## 🛠️ Troubleshooting

### Cannot Find ESP32_SPRAY_ROBOT
- Ensure ESP32 is powered on
- Check if the code is uploaded correctly
- Restart Bluetooth on your phone
- Move closer to the ESP32

### Connection Failed
- Make sure the device is paired first
- Try unpairing and pairing again
- Restart the ESP32
- Check if another device is connected to the ESP32

### Commands Not Working
- Verify Bluetooth connection status (green indicator)
- Check ESP32 serial monitor for received commands
- Ensure motor driver and relay are properly connected
- Check power supply to motors and pump

## 📦 Dependencies

### Flutter Packages
```yaml
flutter_bluetooth_serial: ^0.4.0
permission_handler: ^11.0.1
```

### Android Permissions
The app requires the following permissions:
- `BLUETOOTH`
- `BLUETOOTH_ADMIN`
- `BLUETOOTH_SCAN`
- `BLUETOOTH_CONNECT`
- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`

These are automatically requested when you first use the Bluetooth feature.

## 🔄 Migrating from WiFi to Bluetooth

### What Changed?
- ❌ Removed: HTTP requests to ESP32 IP address
- ❌ Removed: WiFi/Hotspot dependency
- ✅ Added: Bluetooth Serial communication
- ✅ Added: Device pairing and discovery
- ✅ Added: Automatic reconnection handling

### Benefits
- ✨ No need for WiFi hotspot
- ✨ More reliable connection
- ✨ Lower power consumption
- ✨ Easier setup process
- ✨ Works without internet

## 📝 Notes

- Bluetooth Classic is used (not BLE) for better compatibility
- The ESP32 can only connect to one device at a time
- Commands are case-insensitive
- Connection status is shown in real-time
- Auto-disconnect when app is closed

## 🚀 Future Enhancements

- [ ] Add battery level monitoring
- [ ] Implement auto-reconnect on connection loss
- [ ] Add command history
- [ ] Support for multiple ESP32 devices
- [ ] Add Bluetooth signal strength indicator

---

**Created by**: @Balaji Electrical and Techno Hub  
**Location**: Ambegaon B.K, Pune
