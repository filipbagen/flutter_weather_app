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
    'tops': [
      'half-zipper-jumper_black',
      'linnen-shirt_beige',
      'overshirt_navy',
      'pike_white',
      'rain-coat_navy',
      'short-sleeve-shirt_beige',
      'sweatshirt_beige',
      'sweatshirt_black',
      'tshirt_black',
      'tshirt_green',
      'tshirt_white',
      'winter-jacket_black',
    ],
    'bottoms': [
      'jeans_blue',
      'linnen-shorts_beige',
      'linnen-shorts_navy',
      'shorts_black',
      'wide-trousers_black',
    ],
    'shoes': [
      'barefoot',
      'casual_white',
      'running-shoes_black',
      'sandals_black',
      'socks_white',
    ],
    'accessories': ['cap_black', 'cap_blue', 'head_neutral', 'sunglasses'],
  };

  // Human-readable names for clothing items
  static const Map<String, String> clothingNames = {
    // Tops
    'half-zipper-jumper_black': 'black half-zipper jumper',
    'linnen-shirt_beige': 'beige linen shirt',
    'overshirt_navy': 'navy overshirt',
    'pike_white': 'white polo shirt',
    'rain-coat_navy': 'navy rain coat',
    'short-sleeve-shirt_beige': 'beige short-sleeve shirt',
    'sweatshirt_beige': 'beige sweatshirt',
    'sweatshirt_black': 'black sweatshirt',
    'tshirt_black': 'black t-shirt',
    'tshirt_green': 'green t-shirt',
    'tshirt_white': 'white t-shirt',
    'winter-jacket_black': 'black winter jacket',
    // Bottoms
    'jeans_blue': 'blue jeans',
    'linnen-shorts_beige': 'beige linen shorts',
    'linnen-shorts_navy': 'navy linen shorts',
    'shorts_black': 'black shorts',
    'wide-trousers_black': 'black wide trousers',
    // Shoes
    'barefoot': 'barefoot',
    'casual_white': 'white casual shoes',
    'running-shoes_black': 'black running shoes',
    'sandals_black': 'black sandals',
    'socks_white': 'white socks',
    // Accessories
    'cap_black': 'black cap',
    'cap_blue': 'blue cap',
    'head_neutral': 'neutral head',
    'sunglasses': 'sunglasses',
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

    // Debug: Print the prompt being sent to AI
    print('=== AI PROMPT ===');
    print(prompt);
    print('=== END PROMPT ===');

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
              outfitData.shoes == null ||
              outfitData.accessory == null) {
            print('AI response missing required items, using fallback');
            return _getFallbackOutfit(weatherData);
          }

          // Return the complete outfit as provided by AI
          final completeOutfit = OutfitData(
            top: outfitData.top,
            bottom: outfitData.bottom,
            shoes: outfitData.shoes,
            accessory: outfitData.accessory,
            motivation: _humanizeMotivation(
              outfitData.motivation ?? 'Perfect outfit for today\'s weather!',
            ),
          );

          return completeOutfit;
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
    final windSpeed = weatherData.windSpeed;

    // Enhanced accessory selection logic
    String selectAccessory(double temp, String condition, double windSpeed) {
      // Priority 1: Sunny/clear weather - sunglasses
      if (condition.contains('sun') ||
          condition.contains('clear') ||
          condition.contains('bright')) {
        return 'sunglasses';
      }

      // Priority 2: Cold or windy weather - cap for warmth/protection
      if (temp < 15 || windSpeed > 5) {
        return 'cap_black';
      }

      // Priority 3: Casual warm weather - cap for style
      if (temp > 20 &&
          (condition.contains('cloud') || condition.contains('part'))) {
        return 'cap_blue';
      }

      // Default: neutral for formal/minimal looks
      return 'head_neutral';
    }

    // Simple fallback logic based on temperature using actual available items
    if (temp < 10) {
      return OutfitData(
        top: 'winter-jacket_black',
        bottom: 'jeans_blue',
        shoes: 'casual_white',
        accessory: selectAccessory(temp, condition, windSpeed),
        motivation:
            'Given the cold temperature of ${temp.round()}°C, I recommend a warm black winter jacket with blue jeans. This combination provides necessary insulation and comfort.',
      );
    } else if (temp < 20) {
      return OutfitData(
        top: 'sweatshirt_beige',
        bottom: 'wide-trousers_black',
        shoes: 'casual_white',
        accessory: selectAccessory(temp, condition, windSpeed),
        motivation:
            'For the moderate temperature of ${temp.round()}°C, I suggest this balanced outfit. It offers comfort and style without overheating.',
      );
    } else {
      String accessory = selectAccessory(temp, condition, windSpeed);

      String motivationText =
          'For the warm weather at ${temp.round()}°C, I recommend lightweight, breathable clothing. This outfit will help you stay cool and comfortable.';

      return OutfitData(
        top: 'tshirt_white',
        bottom: 'linnen-shorts_beige',
        shoes: 'sandals_black',
        accessory: accessory,
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
Select one outfit item from each category based on these weather conditions:

Weather Data:
- Temperature: $temp°C (feels like $feelsLike°C)
- Condition: $condition
- Humidity: $humidity%
- Wind Speed: $windSpeed m/s

Available Wardrobe:
TOPS: $topsDisplay
BOTTOMS: $bottomsDisplay
SHOES: $shoesDisplay
ACCESSORIES: $accessoriesDisplay

Requirements:
- Select EXACTLY 1 item from each category above
- Use the exact file names in parentheses for your selection
- Consider weather appropriateness (temperature, conditions, wind, humidity)
- Write motivation as a professional stylist using human-readable clothing names
- Keep motivation to maximum 2 sentences

Return only valid JSON:
{
  "top": "exact_file_name",
  "bottom": "exact_file_name", 
  "shoes": "exact_file_name",
  "accessory": "exact_file_name",
  "motivation": "Brief stylist recommendation using human-readable clothing names"
}''';
  }
}
