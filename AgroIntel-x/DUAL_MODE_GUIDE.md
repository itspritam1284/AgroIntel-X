# Dual-Mode Smart Farming Application

## Overview
The application now supports **two modes** that you can switch between using the swap icon in the header:

### 1. 🌾 Smart Farming Dashboard (Sensor Mode)
- **Real-time IoT sensor monitoring**
- Displays: Temperature, Humidity, Soil Moisture, Rain, Light, Motion, and Flame sensors
- Auto-refresh every 2 seconds
- Beautiful image slider with farming photos
- Notification drawer for alerts (Rain, Motion, Fire)
- Detailed sensor history charts

### 2. 🚤 Rower Control Dashboard (Motor Mode)
- **ESP32-based motor control interface**
- Directional controls: Forward, Backward, Left, Right, Stop
- **Turbo Mode**: Toggle between 70% (Normal) and 100% (Turbo) power
- Real-time connection status monitoring
- Speed indicator with circular progress
- Quick actions: Reconnect and Emergency Stop
- Configurable ESP32 IP address

## Navigation

### Switch Between Modes
- **From Sensor Dashboard**: Click the swap icon (⇄) next to the notification bell
- **From Rower Control**: Click the swap icon (⇄) next to the settings gear

The swap button is located in the top-right corner of the green header on both screens.

## Features

### Sensor Dashboard Features
✅ Live sensor data from ThingSpeak
✅ Modern UI with deep green (#1B5E20) and cream (#F5F5DC) theme
✅ Animated image carousel
✅ Pull-to-refresh functionality
✅ Tap any sensor card for detailed history
✅ Real-time notifications for critical events

### Rower Control Features
✅ WiFi connection status indicator
✅ Responsive control buttons with visual feedback
✅ Turbo mode with orange highlight
✅ Speed percentage display (0-100%)
✅ Settings to configure ESP32 IP address
✅ Emergency stop button
✅ Auto-reconnect functionality

## Design Highlights

### Color Scheme
- **Primary Green**: #1B5E20 (Deep Forest Green)
- **Secondary Green**: #2E7D32 (Medium Green)
- **Background**: #F5F5DC (Cream/Beige)
- **Accent Colors**: 
  - Turbo Mode: Orange (#FF9800)
  - Alerts: Red (#F44336)
  - Success: Green (#4CAF50)

### UI Elements
- **Gradient headers** with rounded bottom corners
- **Glassmorphism effects** on buttons
- **Smooth animations** for mode indicators
- **Responsive layouts** that prevent overflow
- **Shadow effects** for depth and hierarchy

## Technical Details

### File Structure
```
lib/
├── main.dart                          # App entry point with routing
├── screens/
│   ├── sensor_dashboard_screen.dart   # IoT sensor monitoring
│   ├── rower_control_screen.dart      # Motor control interface
│   └── sensor_detail_screen.dart      # Individual sensor history
├── services/
│   └── thingspeak_service.dart        # API integration
└── widgets/
    ├── sensor_card.dart               # Sensor display cards
    └── sensor_chart.dart              # Historical data charts
```

### Routes
- `/sensors` - Smart Farming Dashboard (default)
- `/rower` - Rower Control Dashboard

### Dependencies
- `http` - For API calls to ThingSpeak and ESP32
- `fl_chart` - For sensor data visualization
- `intl` - For date/time formatting
- `smooth_page_indicator` - For image carousel dots

## ESP32 Configuration

### Default IP Address
The default ESP32 IP is set to `192.168.42.91`

### To Change IP Address
1. Open Rower Control screen
2. Tap the settings icon (⚙️) in the top-right
3. Enter your ESP32's IP address
4. Click "Save"

### API Endpoints
The app expects these endpoints on your ESP32:
- `/status` - Check connection status
- `/forward` - Move forward
- `/backward` - Move backward
- `/left` - Turn left
- `/right` - Turn right
- `/stop` - Stop all motors
- `/forward/turbo` - Forward at max speed
- `/backward/turbo` - Backward at max speed
- (etc. for other turbo commands)

## Bug Fixes
✅ Fixed 3.8px overflow in header Row
✅ Added proper constraints to IconButtons
✅ Made date text responsive with ellipsis
✅ Improved spacing between header elements

## Usage Tips

1. **Start with Sensor Mode** to monitor your farm conditions
2. **Switch to Rower Mode** when you need to control the motors
3. **Enable Turbo Mode** only when you need maximum power
4. **Use Emergency Stop** if something goes wrong
5. **Check connection status** before sending commands

## Future Enhancements (Potential)
- Save favorite motor commands
- Schedule automated rower movements
- Integrate sensor data with motor control (auto-stop on obstacles)
- Add voice control
- Remote access via cloud
- Historical motor usage logs

---

**Version**: 1.0.0  
**Last Updated**: January 22, 2026  
**Theme**: Smart Farming IoT + Rower Control
