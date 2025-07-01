import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/weather_data.dart';
import '../models/sensor_data.dart';
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
              'You are a professional fashion stylist providing expert clothing recommendations. Write as a stylist giving advice to a client, using phrases like "I recommend" or "I suggest". IMPORTANT: If the accessory is "head_neutral", do NOT mention it in your motivation - it is just the natural head, not an accessory. Only mention caps or sunglasses when actually recommending them. Always respond with valid JSON only.',
        },
        {'role': 'user', 'content': prompt},
      ],
      'max_tokens': 200,
      'temperature': 0.3,
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

        // Parse JSON response from AI
        try {
          final outfitJson = json.decode(recommendation.trim());
          final outfitData = OutfitData.fromJson(outfitJson);

          // Validate that all required items are present
          if (outfitData.top == null ||
              outfitData.bottom == null ||
              outfitData.shoes == null ||
              outfitData.accessory == null) {
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
          // If AI doesn't return valid JSON, provide fallback outfit
          return _getFallbackOutfit(weatherData);
        }
      } else {
        throw Exception(
          'Failed to get outfit recommendation: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      // If API call fails completely, return fallback
      return _getFallbackOutfit(weatherData);
    }
  }

  static Future<OutfitData> getOutfitRecommendationFromSensor(
    SensorData sensorData,
  ) async {
    final prompt = _buildPromptFromSensor(sensorData);

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
              'You are a professional fashion stylist providing expert clothing recommendations based on live weather data. Write as a stylist giving advice to a client, using phrases like "I recommend" or "I suggest". IMPORTANT: If the accessory is "head_neutral", do NOT mention it in your motivation - it is just the natural head, not an accessory. Only mention caps or sunglasses when actually recommending them. Always respond with valid JSON only.',
        },
        {'role': 'user', 'content': prompt},
      ],
      'max_tokens': 200,
      'temperature': 0.3,
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

        // Parse JSON response from AI
        try {
          final outfitJson = json.decode(recommendation.trim());
          final outfitData = OutfitData.fromJson(outfitJson);

          // Validate that all required items are present
          if (outfitData.top == null ||
              outfitData.bottom == null ||
              outfitData.shoes == null ||
              outfitData.accessory == null) {
            return _getFallbackOutfitFromSensor(sensorData);
          }

          // Return the complete outfit as provided by AI
          final completeOutfit = OutfitData(
            top: outfitData.top,
            bottom: outfitData.bottom,
            shoes: outfitData.shoes,
            accessory: outfitData.accessory,
            motivation: _humanizeMotivation(
              outfitData.motivation ??
                  'Perfect outfit for today\'s conditions!',
            ),
          );

          return completeOutfit;
        } catch (e) {
          return _getFallbackOutfitFromSensor(sensorData);
        }
      } else {
        throw Exception(
          'Failed to get outfit recommendation: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      return _getFallbackOutfitFromSensor(sensorData);
    }
  }

  // Convert file names to human-readable names in motivation text
  static String _humanizeMotivation(String motivation) {
    String result = motivation;

    // Replace each file name with its human-readable version
    clothingNames.forEach((fileName, humanName) {
      // Skip head_neutral replacement to avoid mentioning it
      if (fileName != 'head_neutral') {
        result = result.replaceAll(fileName, humanName);
      }
    });

    // Clean up any mentions of head_neutral or similar phrases
    result = result
        .replaceAll('head_neutral', '')
        .replaceAll('neutral head accessory', '')
        .replaceAll('neutral head', '')
        .replaceAll('head accessory', '')
        .replaceAll('Adding a ', '')
        .replaceAll('adding a ', '')
        .replaceAll(' will complete the outfit', '')
        .replaceAll(' completes the outfit', '')
        .replaceAll('  ', ' ') // Remove double spaces
        .trim();

    return result;
  }

  static OutfitData _getFallbackOutfit(WeatherData weatherData) {
    final temp = weatherData.temperatureCelsius;
    final condition = weatherData.description.toLowerCase();
    final windSpeed = weatherData.windSpeed;

    // Enhanced accessory selection logic
    String selectAccessory(double temp, String condition, double windSpeed) {
      if (condition.contains('sun') ||
          condition.contains('clear') ||
          condition.contains('bright')) {
        return 'sunglasses';
      }

      if (temp < 15 || windSpeed > 5) {
        return 'cap_black';
      }

      if (temp > 20 &&
          (condition.contains('cloud') || condition.contains('part'))) {
        return 'cap_blue';
      }

      // Default: neutral for formal/minimal looks
      return 'head_neutral';
    }

    // Generate motivation based on accessory choice
    String getMotivation(double temp, String condition, String accessory) {
      String baseMotivation;
      String accessoryText = '';

      if (temp < 10) {
        baseMotivation =
            'Given the cold temperature of ${temp.round()}°C, I recommend a warm black winter jacket with blue jeans for necessary insulation and comfort.';
      } else if (temp < 20) {
        baseMotivation =
            'For the moderate temperature of ${temp.round()}°C, I suggest this balanced outfit that offers comfort and style without overheating.';
      } else {
        baseMotivation =
            'For the warm weather at ${temp.round()}°C, I recommend lightweight, breathable clothing to help you stay cool and comfortable.';
      }

      // Only add accessory text for actual accessories (not head_neutral)
      if (accessory == 'sunglasses') {
        accessoryText =
            ' The sunglasses will protect your eyes from the bright conditions.';
      } else if (accessory == 'cap_black') {
        accessoryText = temp < 15
            ? ' The black cap provides additional warmth and protection.'
            : ' The black cap adds a stylish finishing touch.';
      } else if (accessory == 'cap_blue') {
        accessoryText =
            ' The blue cap complements the casual, comfortable style.';
      }
      // No text for head_neutral - it's just the natural head

      return baseMotivation + accessoryText;
    }

    String selectedAccessory = selectAccessory(temp, condition, windSpeed);

    // Simple fallback logic based on temperature using actual available items
    if (temp < 10) {
      return OutfitData(
        top: 'winter-jacket_black',
        bottom: 'jeans_blue',
        shoes: 'casual_white',
        accessory: selectedAccessory,
        motivation: getMotivation(temp, condition, selectedAccessory),
      );
    } else if (temp < 20) {
      return OutfitData(
        top: 'sweatshirt_beige',
        bottom: 'wide-trousers_black',
        shoes: 'casual_white',
        accessory: selectedAccessory,
        motivation: getMotivation(temp, condition, selectedAccessory),
      );
    } else {
      return OutfitData(
        top: 'tshirt_white',
        bottom: 'linnen-shorts_beige',
        shoes: 'sandals_black',
        accessory: selectedAccessory,
        motivation: getMotivation(temp, condition, selectedAccessory),
      );
    }
  }

  static OutfitData _getFallbackOutfitFromSensor(SensorData sensorData) {
    final temp = sensorData.temperature;
    final lightLevel = sensorData.lightLevel.toLowerCase();

    // Enhanced accessory selection logic for sensor data
    String selectAccessory(double temp, String lightLevel) {
      if (lightLevel.contains('bright') || lightLevel.contains('very bright')) {
        return 'sunglasses';
      }

      if (temp < 15) {
        return 'cap_black';
      }

      if (temp > 20 &&
          (lightLevel.contains('dim') || lightLevel.contains('dark'))) {
        return 'cap_blue';
      }

      // Default: neutral for moderate conditions
      return 'head_neutral';
    }

    // Generate motivation based on sensor data
    String getMotivationFromSensor(
      double temp,
      String lightLevel,
      String accessory,
    ) {
      String baseMotivation;
      String accessoryText = '';

      if (temp < 10) {
        baseMotivation =
            'Given the cold reading of ${temp.round()}°C, I recommend a warm black winter jacket with blue jeans for necessary insulation and comfort.';
      } else if (temp < 20) {
        baseMotivation =
            'For the moderate temperature of ${temp.round()}°C, I suggest this balanced outfit that offers comfort and style.';
      } else {
        baseMotivation =
            'With the warm weather at ${temp.round()}°C, I recommend lightweight, breathable clothing to help you stay cool.';
      }

      // Only add accessory text for actual accessories (not head_neutral)
      if (accessory == 'sunglasses') {
        accessoryText =
            ' The sunglasses will protect your eyes from the bright light conditions.';
      } else if (accessory == 'cap_black') {
        accessoryText = temp < 15
            ? ' The black cap provides additional warmth for the cooler temperature.'
            : ' The black cap adds a stylish finishing touch.';
      } else if (accessory == 'cap_blue') {
        accessoryText =
            ' The blue cap complements the casual, comfortable style.';
      }

      return baseMotivation + accessoryText;
    }

    String selectedAccessory = selectAccessory(temp, lightLevel);

    // Simple fallback logic based on sensor temperature
    if (temp < 10) {
      return OutfitData(
        top: 'winter-jacket_black',
        bottom: 'jeans_blue',
        shoes: 'casual_white',
        accessory: selectedAccessory,
        motivation: getMotivationFromSensor(
          temp,
          lightLevel,
          selectedAccessory,
        ),
      );
    } else if (temp < 20) {
      return OutfitData(
        top: 'sweatshirt_beige',
        bottom: 'wide-trousers_black',
        shoes: 'casual_white',
        accessory: selectedAccessory,
        motivation: getMotivationFromSensor(
          temp,
          lightLevel,
          selectedAccessory,
        ),
      );
    } else {
      return OutfitData(
        top: 'tshirt_white',
        bottom: 'linnen-shorts_beige',
        shoes: 'sandals_black',
        accessory: selectedAccessory,
        motivation: getMotivationFromSensor(
          temp,
          lightLevel,
          selectedAccessory,
        ),
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

CRITICAL INSTRUCTIONS:
- Select EXACTLY 1 item from each category above
- Use the exact file names in parentheses for your selection
- IMPORTANT: "head_neutral" is just the natural head - NOT an accessory to mention
- Only mention accessories in motivation if you choose cap_black, cap_blue, or sunglasses
- If you choose head_neutral, do NOT mention head, accessories, or anything head-related
- Consider weather appropriateness (temperature, conditions, wind, humidity)
- Write motivation as a professional stylist using human-readable clothing names
- Keep motivation to maximum 2 sentences
- Focus on weather benefits and style, not head accessories unless actually choosing caps/sunglasses

Return only valid JSON:
{
  "top": "exact_file_name",
  "bottom": "exact_file_name", 
  "shoes": "exact_file_name",
  "accessory": "exact_file_name",
  "motivation": "Brief stylist recommendation using human-readable clothing names (DO NOT mention head_neutral)"
}''';
  }

  static String _buildPromptFromSensor(SensorData sensorData) {
    final temp = sensorData.temperature.round();
    final humidity = sensorData.humidity;
    final lightLevel = sensorData.lightLevel;

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
Select one outfit item from each category based on these current conditions:

Current Weather Data:
- Temperature: $temp°C (live reading)
- Humidity: $humidity% (live reading)
- Light Level: $lightLevel (live reading)

Available Wardrobe:
TOPS: $topsDisplay
BOTTOMS: $bottomsDisplay
SHOES: $shoesDisplay
ACCESSORIES: $accessoriesDisplay

CRITICAL INSTRUCTIONS:
- Select EXACTLY 1 item from each category above
- Use the exact file names in parentheses for your selection
- IMPORTANT: "head_neutral" is just the natural head - NOT an accessory to mention
- Only mention accessories in motivation if you choose cap_black, cap_blue, or sunglasses
- If you choose head_neutral, do NOT mention head, accessories, or anything head-related
- Consider current readings (temperature, humidity, light level) for appropriateness
- Write motivation as a professional stylist using human-readable clothing names
- Keep motivation to maximum 2 sentences
- Focus on weather benefits and style, not head accessories unless actually choosing caps/sunglasses

Return only valid JSON:
{
  "top": "exact_file_name",
  "bottom": "exact_file_name", 
  "shoes": "exact_file_name",
  "accessory": "exact_file_name",
  "motivation": "Brief stylist recommendation based on current weather data using human-readable clothing names (DO NOT mention head_neutral)"
}''';
  }
}
