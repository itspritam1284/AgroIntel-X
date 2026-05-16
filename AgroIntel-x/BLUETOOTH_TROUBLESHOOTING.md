# 🔧 Bluetooth Connection Troubleshooting Guide

## ✅ What We Fixed

### 1. **Permission Request Order**
- Now requests permissions BEFORE checking Bluetooth status
- Requests permissions one-by-one for better compatibility
- Adds a small delay after permission request
- Checks if permissions were actually granted

### 2. **Connection Timeout**
- Added 10-second timeout to prevent hanging
- Better error messages with emojis for easy debugging
- Improved error type logging

### 3. **Error Handling**
- Added try-catch blocks around initialization
- Better mounted widget checks
- More detailed console logging

## 🧪 How to Test

### Step 1: Check Logcat for Errors
When you run the app, watch the console/logcat for these messages:

```
✅ Good Messages:
🔄 Connecting to ESP32_SPRAY_ROBOT...
✅ Connected to ESP32_SPRAY_ROBOT
📥 Received: SPRAY ON

❌ Error Messages to Watch For:
❌ Connection failed: [error details]
⏱️ Connection timeout
Error type: [error type]
```

### Step 2: Test Connection Flow

1. **Open the app**
   - Should ask for permissions (first time only)
   - Grant ALL permissions (Bluetooth, Location, Nearby Devices)

2. **Tap Bluetooth icon** (top-right)
   - Should show list of paired devices
   - ESP32_SPRAY_ROBOT should appear

3. **Tap ESP32_SPRAY_ROBOT**
   - Status should change to "Connecting..."
   - Then "Connected" with green indicator
   - Device name should appear in header

4. **Test a command**
   - Tap FORWARD button
   - Watch Serial Bluetooth Terminal for "forward" command

## 🐛 Common Issues & Solutions

### Issue 1: "No paired devices found"
**Solution:**
```
1. Go to Phone Settings → Bluetooth
2. Find ESP32_SPRAY_ROBOT
3. Tap to pair
4. Return to app and tap Bluetooth icon again
```

### Issue 2: "Permission denied"
**Solution:**
```
1. Go to Phone Settings → Apps → Farmer IoT Sensors
2. Tap Permissions
3. Enable:
   - Bluetooth ✅
   - Location ✅
   - Nearby devices ✅
4. Restart the app
```

### Issue 3: "Connection timeout"
**Solution:**
```
1. Make sure ESP32 is powered on
2. Check if Serial Bluetooth Terminal can connect
3. If yes, disconnect Serial Bluetooth Terminal first
4. Try connecting from your app again
```

### Issue 4: "Connection lost immediately"
**Solution:**
```
1. ESP32 can only connect to ONE device at a time
2. Close Serial Bluetooth Terminal app
3. Restart ESP32
4. Try connecting from your app
```

### Issue 5: App shows "Connected" but commands don't work
**Solution:**
```
1. Check ESP32 serial monitor
2. Commands should appear there
3. If not, check the command format
4. Try disconnecting and reconnecting
```

## 📱 Testing Checklist

Before reporting issues, check:

- [ ] ESP32 is powered on
- [ ] ESP32 code is uploaded correctly
- [ ] ESP32 is paired in phone Bluetooth settings
- [ ] All app permissions are granted
- [ ] Serial Bluetooth Terminal is CLOSED
- [ ] No other device is connected to ESP32
- [ ] Bluetooth is enabled on phone
- [ ] Location services are enabled (required for Bluetooth scan)

## 🔍 Debug Commands

### Check if device is paired:
```bash
# In phone settings → Bluetooth
# Look for: ESP32_SPRAY_ROBOT
```

### Check app logs:
```bash
# Run app with:
flutter run

# Watch for:
- "Bluetooth permission: true"
- "Location permission: true"
- "🔄 Connecting to ESP32_SPRAY_ROBOT..."
- "✅ Connected to ESP32_SPRAY_ROBOT"
```

### Check ESP32 logs:
```bash
# Open Arduino Serial Monitor (9600 baud)
# Should see:
- "ESP32 Spray Robot Ready!"
- "Waiting for Bluetooth connection..."
- "Received: forward" (when you send commands)
```

## 🎯 Expected Behavior

### On App Start:
1. Permission dialogs appear (first time)
2. Status shows "Not Connected"
3. Bluetooth icon is visible

### On Connect Button:
1. Dialog shows paired devices
2. ESP32_SPRAY_ROBOT is in the list
3. Tap device → "Connecting..."
4. After 1-3 seconds → "Connected" ✅
5. Green indicator appears
6. Device name shows in header

### On Command Send:
1. Tap any control button
2. Status updates (e.g., "Moving Forward")
3. ESP32 serial monitor shows command
4. Motors/pump respond
5. Snackbar shows success message

## 📊 Performance Expectations

- **Connection Time**: 1-3 seconds
- **Command Latency**: < 100ms
- **Range**: 10-30 meters
- **Battery Impact**: Low (Bluetooth Classic)

## 🚨 If Nothing Works

Try this complete reset:

1. **Unpair ESP32**
   ```
   Settings → Bluetooth → ESP32_SPRAY_ROBOT → Forget
   ```

2. **Clear app data**
   ```
   Settings → Apps → Farmer IoT Sensors → Storage → Clear Data
   ```

3. **Restart ESP32**
   ```
   Power cycle the ESP32
   ```

4. **Re-pair**
   ```
   Settings → Bluetooth → Pair with ESP32_SPRAY_ROBOT
   ```

5. **Restart app**
   ```
   Close and reopen the app
   Grant all permissions
   ```

6. **Try connecting**
   ```
   Tap Bluetooth icon → Select device
   ```

## 📝 Report Issues

If you still have problems, provide:

1. **Console logs** (from `flutter run`)
2. **ESP32 serial monitor** output
3. **Screenshot** of the error
4. **Android version**
5. **Phone model**

---

**Last Updated**: 2026-01-23  
**Version**: 2.0.1 (Bluetooth - Debug)
