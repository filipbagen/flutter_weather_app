import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_weather_app/services/firebase_service.dart';

void main() {
  group('Firebase Service Tests', () {
    setUpAll(() async {
      await dotenv.load(fileName: ".env");
    });

    test('should fetch latest sensor data', () async {
      final sensorData = await FirebaseService.getLatestSensorData();

      if (sensorData != null) {
        expect(sensorData.humidity, isA<int>());
        expect(sensorData.temperature, isA<double>());
        expect(sensorData.lightLevel, isA<String>());
        expect(sensorData.timestamp, isA<int>());
      }
    });
  });
}
