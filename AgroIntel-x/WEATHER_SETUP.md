# Weather Integration Setup

## OpenWeatherMap API Setup

To enable real-time weather data in your Smart Farming Dashboard, you need to get a free API key from OpenWeatherMap.

### Steps to Get Your API Key:

1. **Visit OpenWeatherMap**
   - Go to: https://openweathermap.org/

2. **Create a Free Account**
   - Click "Sign In" → "Create an Account"
   - Fill in your details and verify your email

3. **Get Your API Key**
   - After logging in, go to: https://home.openweathermap.org/api_keys
   - Your default API key will be shown
   - Or click "Generate" to create a new one
   - Copy the API key

4. **Add API Key to Your App**
   - Open: `lib/services/weather_service.dart`
   - Find line 6: `static const String _apiKey = 'YOUR_API_KEY_HERE';`
   - Replace `YOUR_API_KEY_HERE` with your actual API key
   - Example: `static const String _apiKey = 'abc123def456ghi789jkl';`

5. **Change Location (Optional)**
   - Open: `lib/screens/sensor_dashboard_screen.dart`
   - Find line 35: `String _cityName = 'Satara,IN';`
   - Change to your city: `'YourCity,CountryCode'`
   - Examples:
     - `'Mumbai,IN'`
     - `'Pune,IN'`
     - `'Delhi,IN'`

### Features:

The weather widget displays:
- ✅ Current temperature
- ✅ High/Low temperatures
- ✅ Weather condition with icon
- ✅ Humidity percentage
- ✅ Atmospheric pressure
- ✅ Wind speed
- ✅ Sunrise time
- ✅ Sunset time

### Auto-Refresh:

Weather data automatically refreshes every **10 minutes** to save API calls (free tier has limits).

### Free Tier Limits:

- 1,000 API calls per day
- 60 calls per minute
- Perfect for this application!

### Troubleshooting:

**If weather doesn't load:**
1. Check your API key is correct
2. Wait 10-15 minutes after creating the key (activation time)
3. Check your internet connection
4. Verify the city name is correct

**API Key Not Working?**
- New API keys can take up to 2 hours to activate
- Make sure you're using the "Current Weather Data" API (included in free tier)

---

**Note:** The weather service is already integrated into your dashboard. Just add your API key and you're ready to go! 🌤️
