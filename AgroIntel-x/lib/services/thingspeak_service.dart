import 'dart:convert';
import 'package:http/http.dart' as http;

class ThingSpeakService {
  static const String channelId = '3231289';
  static const String apiKey = 'N6TC8OHEK08ODTYO';
  static const String baseUrl = 'https://api.thingspeak.com';

  Future<Map<String, dynamic>> fetchChannelData({int results = 10}) async {
    try {
      final url = Uri.parse(
        '$baseUrl/channels/$channelId/feeds.json?api_key=$apiKey&results=$results',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }

  Future<SensorData?> getLatestData() async {
    try {
      final data = await fetchChannelData(results: 1);
      final feeds = data['feeds'] as List;

      if (feeds.isEmpty) return null;

      final latest = feeds.first;
      final channel = data['channel'];

      return SensorData.fromJson(latest, channel);
    } catch (e) {
      print('Error getting latest data: $e');
      return null;
    }
  }

  Future<List<SensorData>> getHistoricalData({int results = 20}) async {
    try {
      final data = await fetchChannelData(results: results);
      final feeds = data['feeds'] as List;
      final channel = data['channel'];

      return feeds
          .map((feed) => SensorData.fromJson(feed, channel))
          .toList()
          .reversed
          .toList();
    } catch (e) {
      print('Error getting historical data: $e');
      return [];
    }
  }
}

class SensorData {
  final DateTime timestamp;
  final double temperature;
  final double humidity;
  final int rain;
  final int soilMoisture;
  final int lux;
  final int motion;
  final int flame;
  final String channelName;

  SensorData({
    required this.timestamp,
    required this.temperature,
    required this.humidity,
    required this.rain,
    required this.soilMoisture,
    required this.lux,
    required this.motion,
    required this.flame,
    required this.channelName,
  });

  factory SensorData.fromJson(
    Map<String, dynamic> json,
    Map<String, dynamic> channel,
  ) {
    return SensorData(
      timestamp: DateTime.parse(json['created_at']),
      temperature: double.tryParse(json['field1'] ?? '0') ?? 0.0,
      humidity: double.tryParse(json['field2'] ?? '0') ?? 0.0,
      rain: int.tryParse(json['field3'] ?? '0') ?? 0,
      soilMoisture: int.tryParse(json['field4'] ?? '0') ?? 0,
      lux: int.tryParse(json['field5'] ?? '0') ?? -1,
      motion: int.tryParse(json['field6'] ?? '0') ?? 0,
      flame: int.tryParse(json['field7'] ?? '0') ?? 0,
      channelName: channel['name'] ?? 'Smart Farming',
    );
  }

  String getTemperatureStatus() {
    if (temperature < 15) return 'Cold';
    if (temperature < 25) return 'Optimal';
    if (temperature < 35) return 'Warm';
    return 'Hot';
  }

  String getHumidityStatus() {
    if (humidity < 30) return 'Dry';
    if (humidity < 60) return 'Optimal';
    if (humidity < 80) return 'Humid';
    return 'Very Humid';
  }

  String getSoilMoistureStatus() {
    if (soilMoisture < 100) return 'Very Dry';
    if (soilMoisture < 200) return 'Dry';
    if (soilMoisture < 400) return 'Optimal';
    if (soilMoisture < 600) return 'Moist';
    return 'Wet';
  }

  bool get isRaining => rain < 500;
  bool get hasMotion => motion == 1;
  bool get hasFlame => flame == 1;
  bool get isDaylight => lux > 0;
}
