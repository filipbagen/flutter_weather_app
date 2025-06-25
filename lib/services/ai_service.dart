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

  // Human-readable names for clothing items
  static const Map<String, String> clothingNames = {
    // Tops
    'jacket_green': 'green jacket',
    'shirt_dark': 'dark shirt',
    'tshirt_striped': 'striped t-shirt',
    'tshirt_white': 'white t-shirt',
    // Bottoms
    'chinos_beige': 'beige chinos',
    'chinos_navy': 'navy chinos',
    'jeans_dark': 'dark jeans',
    'shorts_blue': 'blue shorts',
    // Shoes
    'sneakers_gray': 'gray sneakers',
    'sneakers_navy': 'navy sneakers',
    'sneakers_white': 'white sneakers',
    'trainingshoes_red': 'red training shoes',
    // Accessories
    'glasses_sunglasses': 'sunglasses',
    'head_neutral': 'neutral head',
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
              'You are a professional fashion stylist providing clothing recommendations. Write as a stylist giving advice to a client, using phrases like "I recommend" or "I suggest". Always respond with valid JSON only.',
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
          final outfitData = OutfitData.fromJson(outfitJson);

          // Validate that all required items are present
          if (outfitData.top == null ||
              outfitData.bottom == null ||
              outfitData.shoes == null) {
            print('AI response missing required items, using fallback');
            return _getFallbackOutfit(weatherData);
          }

          // Ensure head_neutral is always included
          final updatedOutfit = OutfitData(
            top: outfitData.top,
            bottom: outfitData.bottom,
            shoes: outfitData.shoes,
            accessory: outfitData.accessory ?? 'head_neutral',
            motivation: _humanizeMotivation(
              outfitData.motivation ?? 'Perfect outfit for today\'s weather!',
            ),
          );

          return updatedOutfit;
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

  // Convert file names to human-readable names in motivation text
  static String _humanizeMotivation(String motivation) {
    String result = motivation;

    // Replace each file name with its human-readable version
    clothingNames.forEach((fileName, humanName) {
      result = result.replaceAll(fileName, humanName);
    });

    return result;
  }

  static OutfitData _getFallbackOutfit(WeatherData weatherData) {
    final temp = weatherData.temperatureCelsius;
    final condition = weatherData.description.toLowerCase();

    // Simple fallback logic based on temperature
    if (temp < 10) {
      return OutfitData(
        top: 'jacket_green',
        bottom: 'jeans_dark',
        shoes: 'sneakers_white',
        accessory: 'head_neutral',
        motivation:
            'Given the cold temperature of ${temp.round()}°C, I recommend a warm green jacket with dark jeans for necessary insulation and comfort.',
      );
    } else if (temp < 20) {
      return OutfitData(
        top: 'shirt_dark',
        bottom: 'chinos_navy',
        shoes: 'sneakers_gray',
        accessory: 'head_neutral',
        motivation:
            'For the moderate temperature of ${temp.round()}°C, I suggest this outfit that offers a good balance of comfort and style.',
      );
    } else {
      String motivationText =
          'For the warm weather at ${temp.round()}°C, I recommend lightweight, breathable clothing to help you stay cool and comfortable.';
      if (condition.contains('rain')) {
        motivationText += ' I also suggest considering protection for potential rain.';
      }
      return OutfitData(
        top: 'tshirt_white',
        bottom: 'shorts_blue',
        shoes: 'sneakers_white',
        accessory: 'head_neutral',
        motivation: motivationText,
      );
    }
  }

  static String _buildPrompt(WeatherData weatherData) {
    final temp = weatherData.temperatureCelsius.round();
    final feelsLike = weatherData.feelsLikeCelsius.round();
    final condition = weatherData.description;
    final humidity = weatherData.humidity;
    final windSpeed = weatherData.windSpeed;

    // Create human-readable lists
    final topsDisplay = availableClothing['tops']!
        .map((item) => '${clothingNames[item]} ($item)')
        .join(', ');
    final bottomsDisplay = availableClothing['bottoms']!
        .map((item) => '${clothingNames[item]} ($item)')
        .join(', ');
    final shoesDisplay = availableClothing['shoes']!
        .map((item) => '${clothingNames[item]} ($item)')
        .join(', ');
    final accessoriesDisplay = availableClothing['accessories']!
        .map((item) => '${clothingNames[item]} ($item)')
        .join(', ');

    return '''
Based on the weather conditions, select outfit items from this specific wardrobe:

Weather:
- Temperature: $temp°C (feels like $feelsLike°C)
- Condition: $condition
- Humidity: $humidity%
- Wind: $windSpeed m/s

Available items:
TOPS: $topsDisplay
BOTTOMS: $bottomsDisplay
SHOES: $shoesDisplay
ACCESSORIES: $accessoriesDisplay

RULES:
- MANDATORY: You MUST select exactly 1 item from each category:
  * 1 TOP (required - choose from jacket_green, shirt_dark, tshirt_striped, tshirt_white)
  * 1 BOTTOM (required - choose from chinos_beige, chinos_navy, jeans_dark, shorts_blue)
  * 1 SHOES (required - choose from sneakers_gray, sneakers_navy, sneakers_white, trainingshoes_red)
  * ACCESSORY must always be "head_neutral"
- For cold weather (< 15°C), prefer green jacket
- For hot weather (> 25°C), prefer shorts and light t-shirt
- In your motivation, use ONLY human-readable clothing names (e.g., "green jacket" not "jacket_green")
- IMPORTANT: Write as a professional stylist giving recommendations. Use phrases like:
  * "I recommend..."
  * "Given the [weather condition], I suggest..."
  * "For today's weather, I advise..."
  * "Considering the [temperature/humidity/wind], [clothing item] would be ideal..."
- Avoid first-person language from the wearer's perspective (don't say "I will wear" or "This will keep me warm")

Return ONLY valid JSON format with the exact file names from parentheses above:
{
  "top": "exact_file_name",
  "bottom": "exact_file_name", 
  "shoes": "exact_file_name",
  "accessory": "head_neutral",
  "motivation": "Professional stylist recommendation using human-readable clothing names"
}
''';
  }
}
