import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  // OpenWeatherMap API key
  static const String _apiKey = '3886e43edd32584093afe8f6d9d9e768';

  // Pune, Maharashtra coordinates
  static const double _lat = 18.5196;
  static const double _lon = 73.8553;

  static const String _currentWeatherUrl =
      'https://api.openweathermap.org/data/2.5/weather';
  static const String _forecastUrl =
      'https://api.openweathermap.org/data/2.5/forecast';

  /// Fetch current weather using lat/lon
  Future<WeatherData?> getWeather({
    double latitude = _lat,
    double longitude = _lon,
  }) async {
    try {
      final url = Uri.parse(
        '$_currentWeatherUrl?lat=$latitude&lon=$longitude&appid=$_apiKey&units=metric',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data);
      } else {
        print('Current Weather API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching current weather: $e');
      return null;
    }
  }

  /// Legacy method: fetch by city name (kept for compatibility)
  Future<WeatherData?> getWeatherByCity(String cityName) async {
    // Always use coordinates for accuracy
    return getWeather();
  }

  /// Fetch 5-day / 3-hour forecast using lat/lon
  Future<List<ForecastDay>> getForecast({
    double latitude = _lat,
    double longitude = _lon,
  }) async {
    try {
      final url = Uri.parse(
        '$_forecastUrl?lat=$latitude&lon=$longitude&appid=$_apiKey&units=metric',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ForecastDay.fromForecastJson(data);
      } else {
        print('Forecast API Error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching forecast: $e');
      return [];
    }
  }
}

// ─── Current Weather Model ───────────────────────────────────────────────────

class WeatherData {
  final String cityName;
  final String country;
  final double temperature;
  final double feelsLike;
  final double tempMin;
  final double tempMax;
  final int humidity;
  final int pressure;
  final double windSpeed;
  final String weatherMain;
  final String weatherDescription;
  final String weatherIcon;
  final int sunrise;
  final int sunset;

  WeatherData({
    required this.cityName,
    required this.country,
    required this.temperature,
    required this.feelsLike,
    required this.tempMin,
    required this.tempMax,
    required this.humidity,
    required this.pressure,
    required this.windSpeed,
    required this.weatherMain,
    required this.weatherDescription,
    required this.weatherIcon,
    required this.sunrise,
    required this.sunset,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      cityName: json['name'] ?? '',
      country: json['sys']['country'] ?? '',
      temperature: (json['main']['temp'] as num).toDouble(),
      feelsLike: (json['main']['feels_like'] as num).toDouble(),
      tempMin: (json['main']['temp_min'] as num).toDouble(),
      tempMax: (json['main']['temp_max'] as num).toDouble(),
      humidity: json['main']['humidity'] as int,
      pressure: json['main']['pressure'] as int,
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      weatherMain: json['weather'][0]['main'] ?? '',
      weatherDescription: json['weather'][0]['description'] ?? '',
      weatherIcon: json['weather'][0]['icon'] ?? '01d',
      sunrise: json['sys']['sunrise'] as int,
      sunset: json['sys']['sunset'] as int,
    );
  }

  String getWeatherIconUrl() {
    return 'https://openweathermap.org/img/wn/$weatherIcon@2x.png';
  }

  DateTime get sunriseTime =>
      DateTime.fromMillisecondsSinceEpoch(sunrise * 1000);
  DateTime get sunsetTime => DateTime.fromMillisecondsSinceEpoch(sunset * 1000);
}

// ─── 5-Day Forecast Model ────────────────────────────────────────────────────

class ForecastDay {
  final DateTime date;
  final double tempMin;
  final double tempMax;
  final double tempAvg;
  final String weatherMain;
  final String weatherDescription;
  final String weatherIcon;
  final int humidity;
  final double windSpeed;

  ForecastDay({
    required this.date,
    required this.tempMin,
    required this.tempMax,
    required this.tempAvg,
    required this.weatherMain,
    required this.weatherDescription,
    required this.weatherIcon,
    required this.humidity,
    required this.windSpeed,
  });

  String getIconUrl() =>
      'https://openweathermap.org/img/wn/$weatherIcon@2x.png';

  /// Convert raw forecast JSON (list of 3-hour slots) into daily summaries
  static List<ForecastDay> fromForecastJson(Map<String, dynamic> json) {
    final List<dynamic> list = json['list'] ?? [];

    // Group entries by calendar date (local)
    final Map<String, List<dynamic>> grouped = {};
    for (final item in list) {
      final dt = DateTime.fromMillisecondsSinceEpoch(
        (item['dt'] as int) * 1000,
      ).toLocal();
      final key =
          '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(item);
    }

    final today = DateTime.now();
    final todayKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final List<ForecastDay> result = [];
    final sortedKeys = grouped.keys.toList()..sort();

    for (final key in sortedKeys) {
      // Skip today — we already show live current weather
      if (key == todayKey) continue;
      if (result.length >= 5) break;

      final entries = grouped[key]!;
      final temps = entries.map((e) => (e['main']['temp'] as num).toDouble());
      final humidities = entries.map((e) => e['main']['humidity'] as int);
      final winds =
          entries.map((e) => (e['wind']['speed'] as num).toDouble());

      // Pick midday slot for icon/condition, fallback to first
      dynamic representative = entries.firstWhere(
        (e) {
          final dt = DateTime.fromMillisecondsSinceEpoch(
            (e['dt'] as int) * 1000,
          ).toLocal();
          return dt.hour >= 11 && dt.hour <= 14;
        },
        orElse: () => entries[entries.length ~/ 2],
      );

      result.add(ForecastDay(
        date: DateTime.parse(key),
        tempMin: temps.reduce((a, b) => a < b ? a : b),
        tempMax: temps.reduce((a, b) => a > b ? a : b),
        tempAvg: temps.reduce((a, b) => a + b) / temps.length,
        weatherMain: representative['weather'][0]['main'] ?? '',
        weatherDescription: representative['weather'][0]['description'] ?? '',
        weatherIcon: representative['weather'][0]['icon'] ?? '01d',
        humidity: (humidities.reduce((a, b) => a + b) / humidities.length)
            .round(),
        windSpeed: winds.reduce((a, b) => a + b) / winds.length,
      ));
    }

    return result;
  }
}
