# Weather API Setup Guide 🌤️

## Getting Your Free OpenWeatherMap API Key

### Step 1: Sign Up
1. Go to [OpenWeatherMap](https://openweathermap.org/)
2. Click on **"Sign In"** in the top right corner
3. Click **"Create an Account"**
4. Fill in your details:
   - Username
   - Email
   - Password
5. Verify your email address

### Step 2: Get Your API Key
1. After logging in, go to your profile
2. Click on **"API keys"** tab
3. You'll see a default API key already generated
4. Or click **"Generate"** to create a new key
5. Copy your API key (it looks like: `a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6`)

### Step 3: Update Your App
1. Open `lib/services/weather_service.dart`
2. Find line 6 where it says:
   ```dart
   static const String _apiKey = 'f9e1a8b7c6d5e4f3a2b1c0d9e8f7a6b5';
   ```
3. Replace the API key with your actual key:
   ```dart
   static const String _apiKey = 'YOUR_ACTUAL_API_KEY_HERE';
   ```

### Step 4: Activate Your API Key
⚠️ **Important**: New API keys take about 10-15 minutes to activate!
- After creating your key, wait 10-15 minutes before testing
- The API won't work immediately after creation

## Free Plan Limits
- ✅ 60 calls per minute
- ✅ 1,000,000 calls per month
- ✅ Current weather data
- ✅ 5-day forecast
- ✅ Perfect for personal projects!

## Current Implementation

### Features
Your app currently displays:
- 📍 **Location**: City name (Satara, IN)
- 🌡️ **Temperature**: Current temperature in Celsius
- 📊 **High/Low**: Daily temperature range
- 💧 **Humidity**: Current humidity percentage
- 🌬️ **Wind Speed**: Wind speed in m/s
- 🌅 **Sunrise/Sunset**: Times for sunrise and sunset
- 🌤️ **Weather Condition**: Clear sky, clouds, rain, etc.
- 🔄 **Auto-refresh**: Updates every 10 minutes

### Changing Location
To change the default location, edit `sensor_dashboard_screen.dart`:

```dart
// Line 38 - Change this to your city
String _cityName = 'Satara, India';  // Change to your city
```

Examples:
- `'Mumbai, India'`
- `'Pune, India'`
- `'Delhi, India'`
- `'Bangalore, India'`

## Troubleshooting

### Problem: Weather not loading
**Solutions:**
1. Check if API key is activated (wait 10-15 minutes after creation)
2. Verify API key is correct (no extra spaces)
3. Check internet connection
4. Verify city name is spelled correctly

### Problem: API Error 401 (Unauthorized)
**Solution:** Your API key is invalid or not activated yet. Wait 10-15 minutes or generate a new key.

### Problem: API Error 404 (Not Found)
**Solution:** City name is incorrect. Try using format: `'CityName, CountryCode'`

### Problem: Weather shows old data
**Solution:** The app auto-refreshes every 10 minutes. You can also pull down to refresh manually.

## API Documentation
For more details, visit: [OpenWeatherMap API Docs](https://openweathermap.org/api)

## Alternative Weather APIs (Free)

If you want to try other weather services:

### 1. WeatherAPI.com
- Free tier: 1M calls/month
- Website: https://www.weatherapi.com/
- Very generous free tier

### 2. Tomorrow.io (formerly ClimaCell)
- Free tier: 500 calls/day
- Website: https://www.tomorrow.io/
- More detailed weather data

### 3. Visual Crossing
- Free tier: 1000 records/day
- Website: https://www.visualcrossing.com/
- Historical weather data available

## Security Note 🔒

⚠️ **Never commit API keys to public repositories!**

For production apps:
1. Use environment variables
2. Store keys in secure backend
3. Use API key restrictions (domain/IP whitelist)
4. Rotate keys regularly

## Current Weather Display

Your app shows weather in a beautiful card with:
- Clean, modern design
- Gradient background
- Easy-to-read typography
- Professional icons
- Real-time updates

---

**Last Updated**: January 22, 2026  
**Status**: ✅ Ready to use  
**API Provider**: OpenWeatherMap  
**Plan**: Free Tier
