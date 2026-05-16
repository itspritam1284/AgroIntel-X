import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKey = 'AIzaSyCw6w-EJrtPuBrRWWMslTw39jmW9oRVY_Y';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent';

  Future<FarmingPlan> generateFarmingPlan({
    required String cropName,
    required DateTime plantingDate,
    required double temperature,
    required double humidity,
    required double soilMoisture,
    required double lightIntensity,
  }) async {
    try {
      final prompt = '''
You are an expert agricultural advisor. Create a detailed day-by-day farming plan for growing ${cropName}.

Current Farm Conditions:
- Temperature: ${temperature.toStringAsFixed(1)}°C
- Humidity: ${humidity.toStringAsFixed(1)}%
- Soil Moisture: ${soilMoisture.toStringAsFixed(1)}%
- Light Intensity: ${lightIntensity.toStringAsFixed(0)} lux
- Planting Date: ${plantingDate.toString().split(' ')[0]}

Please provide a comprehensive farming plan with the following structure:
1. Overview (2-3 sentences about the crop and expected timeline)
2. Day-by-day activities for the first 30 days (critical growth period)
3. Weekly activities for weeks 5-12
4. Monthly activities until harvest

For each time period, specify:
- What to do (irrigation, fertilization, pest control, etc.)
- Why it's important
- Expected observations
- Warnings or precautions

Format your response as JSON with this exact structure:
{
  "cropName": "${cropName}",
  "overview": "Brief overview text",
  "totalDuration": "X weeks/months",
  "activities": [
    {
      "day": 1,
      "title": "Activity title",
      "description": "What to do",
      "importance": "Why it matters",
      "observations": "What to look for",
      "warnings": "Precautions if any"
    }
  ]
}

Provide at least 30 daily activities and then weekly/monthly milestones. Be specific and practical.
''';

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 8192,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final generatedText =
            data['candidates'][0]['content']['parts'][0]['text'] as String;

        // Extract JSON from the response (it might be wrapped in markdown code blocks)
        String jsonText = generatedText;
        if (generatedText.contains('```json')) {
          final startIndex = generatedText.indexOf('```json') + 7;
          final endIndex = generatedText.lastIndexOf('```');
          jsonText = generatedText.substring(startIndex, endIndex).trim();
        } else if (generatedText.contains('```')) {
          final startIndex = generatedText.indexOf('```') + 3;
          final endIndex = generatedText.lastIndexOf('```');
          jsonText = generatedText.substring(startIndex, endIndex).trim();
        }

        final planData = jsonDecode(jsonText);

        return FarmingPlan(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          cropName: planData['cropName'] ?? cropName,
          plantingDate: plantingDate,
          createdDate: DateTime.now(),
          overview: planData['overview'] ?? '',
          totalDuration: planData['totalDuration'] ?? '',
          activities:
              (planData['activities'] as List)
                  .map((activity) => PlanActivity.fromJson(activity))
                  .toList(),
          sensorData: SensorSnapshot(
            temperature: temperature,
            humidity: humidity,
            soilMoisture: soilMoisture,
            lightIntensity: lightIntensity,
          ),
        );
      } else {
        throw Exception('Failed to generate plan: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error generating farming plan: $e');
    }
  }
}

class FarmingPlan {
  final String id;
  final String cropName;
  final DateTime plantingDate;
  final DateTime createdDate;
  final String overview;
  final String totalDuration;
  final List<PlanActivity> activities;
  final SensorSnapshot sensorData;

  FarmingPlan({
    required this.id,
    required this.cropName,
    required this.plantingDate,
    required this.createdDate,
    required this.overview,
    required this.totalDuration,
    required this.activities,
    required this.sensorData,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'cropName': cropName,
    'plantingDate': plantingDate.toIso8601String(),
    'createdDate': createdDate.toIso8601String(),
    'overview': overview,
    'totalDuration': totalDuration,
    'activities': activities.map((a) => a.toJson()).toList(),
    'sensorData': sensorData.toJson(),
  };

  factory FarmingPlan.fromJson(Map<String, dynamic> json) => FarmingPlan(
    id: json['id'],
    cropName: json['cropName'],
    plantingDate: DateTime.parse(json['plantingDate']),
    createdDate: DateTime.parse(json['createdDate']),
    overview: json['overview'],
    totalDuration: json['totalDuration'],
    activities:
        (json['activities'] as List)
            .map((a) => PlanActivity.fromJson(a))
            .toList(),
    sensorData: SensorSnapshot.fromJson(json['sensorData']),
  );
}

class PlanActivity {
  final int day;
  final String title;
  final String description;
  final String importance;
  final String observations;
  final String warnings;

  PlanActivity({
    required this.day,
    required this.title,
    required this.description,
    required this.importance,
    required this.observations,
    required this.warnings,
  });

  Map<String, dynamic> toJson() => {
    'day': day,
    'title': title,
    'description': description,
    'importance': importance,
    'observations': observations,
    'warnings': warnings,
  };

  factory PlanActivity.fromJson(Map<String, dynamic> json) => PlanActivity(
    day: json['day'],
    title: json['title'] ?? '',
    description: json['description'] ?? '',
    importance: json['importance'] ?? '',
    observations: json['observations'] ?? '',
    warnings: json['warnings'] ?? '',
  );
}

class SensorSnapshot {
  final double temperature;
  final double humidity;
  final double soilMoisture;
  final double lightIntensity;

  SensorSnapshot({
    required this.temperature,
    required this.humidity,
    required this.soilMoisture,
    required this.lightIntensity,
  });

  Map<String, dynamic> toJson() => {
    'temperature': temperature,
    'humidity': humidity,
    'soilMoisture': soilMoisture,
    'lightIntensity': lightIntensity,
  };

  factory SensorSnapshot.fromJson(Map<String, dynamic> json) => SensorSnapshot(
    temperature: json['temperature'],
    humidity: json['humidity'],
    soilMoisture: json['soilMoisture'],
    lightIntensity: json['lightIntensity'],
  );
}
