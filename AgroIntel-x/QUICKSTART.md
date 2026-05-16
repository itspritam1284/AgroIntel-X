# 🚀 Quick Start Guide

## Running the App

### Option 1: Run on Chrome (Recommended for Testing)
```bash
flutter run -d chrome
```

### Option 2: Run on Your Android Device
```bash
flutter run -d RMX3869
```

### Option 3: Run on Any Available Device
```bash
# First, check available devices
flutter devices

# Then run on your preferred device
flutter run
```

## What You'll See

### 1. **Loading Screen**
- Beautiful loading animation with cyan spinner
- "Loading Sensor Data..." message

### 2. **Dashboard (Once Loaded)**

#### Header Section
- Channel name: "Iot sensor Data 1"
- Subtitle: "Real-time Farm Monitoring"
- Live indicator (green)
- Auto-refresh timer (cyan)

#### Sensor Cards (Grid Layout)
Four beautiful animated cards showing:
1. **Temperature**: 25.1°C - Optimal status
2. **Humidity**: 62.8% - Optimal status
3. **Soil Moisture**: 139 - Dry status
4. **Rain Sensor**: 1023 - Dry status

#### Alerts Section
Three alert cards:
1. **Motion Detection**: Currently inactive
2. **Flame Detection**: Currently inactive
3. **Light Level**: Daylight detected (active)

#### Charts Section
Three beautiful line charts showing:
1. **Temperature Trend** (red gradient)
2. **Humidity Trend** (teal gradient)
3. **Soil Moisture Trend** (mint green gradient)

#### Footer
- Last updated timestamp

## Interacting with the App

### Refresh Data
- **Automatic**: Data refreshes every 15 seconds
- **Manual**: Swipe down from the top to refresh

### View Chart Details
- Tap on any point in the charts to see exact values
- Scroll through the charts to see historical trends

### Monitor Alerts
- Active alerts will have a glowing indicator
- Color coding helps identify severity:
  - 🟢 Green: Normal/Good
  - 🟡 Yellow: Attention
  - 🟠 Orange: Warning
  - 🔴 Red: Critical

## Understanding Sensor Values

### Temperature (field1)
- **Current**: 25.1°C
- **Status**: Optimal (15-25°C range)
- **Color**: Red/Pink card

### Humidity (field2)
- **Current**: 62.8%
- **Status**: Optimal (30-60% range)
- **Color**: Teal card

### Rain Sensor (field3)
- **Current**: 1023
- **Status**: Dry (> 500 = not raining)
- **Color**: Purple card

### Soil Moisture (field4)
- **Current**: 139
- **Status**: Dry (100-200 range)
- **Color**: Mint green card

### Light Level (field5)
- **Current**: -1 (night mode)
- **Status**: Daylight if > 0
- **Alert**: Yellow card when active

### Motion (field6)
- **Current**: 0 (no motion)
- **Status**: Active when = 1
- **Alert**: Orange card when active

### Flame (field7)
- **Current**: 1 (detected)
- **Status**: Critical when = 1
- **Alert**: Red card when active

## Customization

### Change Auto-Refresh Interval
Edit `lib/screens/dashboard_screen.dart` line ~55:
```dart
_refreshTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
  _loadData(showLoading: false);
});
```
Change `seconds: 15` to your preferred interval.

### Change Number of Historical Data Points
Edit `lib/screens/dashboard_screen.dart` line ~73:
```dart
final historical = await _service.getHistoricalData(results: 20);
```
Change `results: 20` to show more or fewer data points.

### Update API Credentials
Edit `lib/services/thingspeak_service.dart` lines 4-5:
```dart
static const String channelId = '3231289';
static const String apiKey = 'N6TC8OHEK08ODTYO';
```

## Troubleshooting

### App Won't Load Data
1. Check your internet connection
2. Verify API key is correct
3. Check ThingSpeak channel is public or API key has read access
4. Look for error messages in the app

### Charts Not Showing
- Ensure there's historical data in your ThingSpeak channel
- Check that at least 2 data points exist
- Verify the data fields are not empty

### App Crashes on Launch
1. Run `flutter clean`
2. Run `flutter pub get`
3. Try running again

### Slow Performance
1. Reduce auto-refresh interval
2. Reduce number of historical data points
3. Close other apps

## Tips for Best Experience

1. **Use on Larger Screens**: The dashboard looks best on tablets or desktop
2. **Portrait Mode**: Works great in portrait orientation on mobile
3. **Dark Environment**: The dark theme is easier on the eyes
4. **Monitor Trends**: Check the charts regularly for patterns
5. **Watch Alerts**: Keep an eye on the alerts section for critical conditions

## Next Steps

1. ✅ App is running successfully
2. 📊 Data is being fetched from ThingSpeak
3. 🎨 Beautiful UI is displaying all sensors
4. 📈 Charts are showing historical trends
5. 🔔 Alerts are monitoring critical conditions

**Enjoy your beautiful IoT dashboard!** 🌾✨

---

For more details, see:
- `README.md` - Full documentation
- `FEATURES.md` - Detailed feature list
