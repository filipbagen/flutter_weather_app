import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/weather_data.dart';

class AIService {
  static const String _baseUrl =
      'https://openrouter.ai/api/v1/chat/completions';

  static String get _apiKey {
    final key = dotenv.env['OPENROUTER_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('OpenRouter API key not found in .env file');
    }
    return key;
  }

  static Future<String> getOutfitRecommendation(WeatherData weatherData) async {
    final prompt = _buildPrompt(weatherData);

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
    };

    final body = json.encode({
      'model': 'openai/gpt-3.5-turbo',
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a helpful fashion assistant that provides practical outfit recommendations based on weather conditions. Keep your responses concise, friendly, and practical.',
        },
        {'role': 'user', 'content': prompt},
      ],
      'max_tokens': 150,
      'temperature': 0.7,
    });

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final recommendation =
            data['choices'][0]['message']['content'] as String;
        return recommendation.trim();
      } else {
        throw Exception(
          'Failed to get outfit recommendation: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error getting outfit recommendation: $e');
    }
  }

  static String _buildPrompt(WeatherData weatherData) {
    final temp = weatherData.temperatureCelsius.round();
    final feelsLike = weatherData.feelsLikeCelsius.round();
    final condition = weatherData.description;
    final humidity = weatherData.humidity;
    final windSpeed = weatherData.windSpeed;

    return '''
Based on the current weather conditions, please suggest what to wear:

Location: ${weatherData.cityName}
Temperature: $temp°C (feels like $feelsLike°C)
Weather: $condition
Humidity: $humidity%
Wind Speed: $windSpeed m/s

Please provide a brief, practical outfit recommendation in 1-2 sentences. Consider comfort, weather protection, and practicality.
''';
  }
}
