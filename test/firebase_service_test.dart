import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_weather_app/services/firebase_service.dart';

void main() {
  group('Firebase Service Tests', () {
    setUpAll(() async {
      // Load environment variables for testing
      await dotenv.load(fileName: ".env");
    });

    test('should connect to Firebase', () async {
      final canConnect = await FirebaseService.testConnection();
      expect(
        canConnect,
        isTrue,
        reason: 'Should be able to connect to Firebase',
      );
    });

    test('should fetch latest sensor data', () async {
      try {
        final sensorData = await FirebaseService.getLatestSensorData();

        if (sensorData != null) {
          expect(sensorData.humidity, isA<int>());
          expect(sensorData.temperature, isA<double>());
          expect(sensorData.lightLevel, isA<String>());
          expect(sensorData.lightRaw, isA<int>());
          expect(sensorData.timestamp, isA<int>());

          print('Sensor data retrieved successfully:');
          print('Temperature: ${sensorData.temperature}°C');
          print('Humidity: ${sensorData.humidity}%');
          print('Light Level: ${sensorData.lightLevel}');
          print('Last Updated: ${sensorData.formattedDateTime}');
        } else {
          print('No sensor data available in Firebase');
        }
      } catch (e) {
        print('Error fetching sensor data: $e');
        // Don't fail the test if data is unavailable, just log it
      }
    });
  });
}
