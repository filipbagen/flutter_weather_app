import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/weather_data.dart';
import '../models/outfit_data.dart';

class AIService {
  static const String _baseUrl =
      'https://openrouter.ai/api/v1/chat/completions';

  // Available clothing items (update this when you add new photos)
  static const Map<String, List<String>> availableClothing = {
    'tops': ['jacket_green', 'shirt_dark', 'tshirt_striped', 'tshirt_white'],
    'bottoms': ['chinos_beige', 'chinos_navy', 'jeans_dark', 'shorts_blue'],
    'shoes': [
      'sneakers_gray',
      'sneakers_navy',
      'sneakers_white',
      'trainingshoes_red',
    ],
    'accessories': ['glasses_sunglasses', 'head_neutral'],
  };

  static String get _apiKey {
    final key = dotenv.env['OPENROUTER_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('OpenRouter API key not found in .env file');
    }
    return key;
  }

  static Future<OutfitData> getOutfitRecommendation(
    WeatherData weatherData,
  ) async {
    final prompt = _buildPrompt(weatherData);

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
      'HTTP-Referer': 'https://flutter-weather-app.com',
      'X-Title': 'Flutter Weather App',
    };

    final body = json.encode({
      'model': 'meta-llama/llama-3.2-3b-instruct:free',
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a helpful fashion assistant that selects outfit items from a specific wardrobe. Always respond with valid JSON only.',
        },
        {'role': 'user', 'content': prompt},
      ],
      'max_tokens': 200,
      'temperature': 0.3,
    });

    try {
      print('Making request to: $_baseUrl');
      print('Headers: $headers');

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: headers,
        body: body,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final recommendation =
            data['choices'][0]['message']['content'] as String;

        print('AI recommendation: $recommendation');

        // Parse JSON response from AI
        try {
          final outfitJson = json.decode(recommendation.trim());
          return OutfitData.fromJson(outfitJson);
        } catch (e) {
          print('Failed to parse AI response as JSON: $e');
          // If AI doesn't return valid JSON, provide fallback outfit
          return _getFallbackOutfit(weatherData);
        }
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        throw Exception(
          'Failed to get outfit recommendation: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Exception in AI service: $e');
      // If API call fails completely, return fallback
      return _getFallbackOutfit(weatherData);
    }
  }

  static OutfitData _getFallbackOutfit(WeatherData weatherData) {
    final temp = weatherData.temperatureCelsius;

    // Simple fallback logic based on temperature
    if (temp < 10) {
      return OutfitData(
        top: 'jacket_green',
        bottom: 'jeans_dark',
        shoes: 'sneakers_white',
      );
    } else if (temp < 20) {
      return OutfitData(
        top: 'shirt_dark',
        bottom: 'chinos_navy',
        shoes: 'sneakers_gray',
      );
    } else {
      return OutfitData(
        top: 'tshirt_white',
        bottom: 'shorts_blue',
        shoes: 'sneakers_white',
      );
    }
  }

  static String _buildPrompt(WeatherData weatherData) {
    final temp = weatherData.temperatureCelsius.round();
    final feelsLike = weatherData.feelsLikeCelsius.round();
    final condition = weatherData.description;
    final humidity = weatherData.humidity;
    final windSpeed = weatherData.windSpeed;

    return '''
Based on the weather conditions, select outfit items from this specific wardrobe:

Weather:
- Temperature: $temp°C (feels like $feelsLike°C)
- Condition: $condition
- Humidity: $humidity%
- Wind: $windSpeed m/s

Available items:
TOPS: ${availableClothing['tops']!.join(', ')}
BOTTOMS: ${availableClothing['bottoms']!.join(', ')}
SHOES: ${availableClothing['shoes']!.join(', ')}
ACCESSORIES: ${availableClothing['accessories']!.join(', ')} (optional)

RULES:
- Always select 1 top, 1 bottom, and 1 shoes
- For cold weather (< 15°C), prefer jacket_green
- For hot weather (> 25°C), prefer shorts and light tshirt
- Accessory is optional

Return ONLY valid JSON format:
{
  "top": "item_name",
  "bottom": "item_name", 
  "shoes": "item_name",
  "accessory": "item_name"
}
''';
  }
}
