import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            'About',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          const Text(
            'This project was developed for the course Introduction to Applied Internet of Things at Linnaeus University. It integrates Flutter mobile development with IoT sensor data, Firebase Realtime Database, OpenWeatherMap API, and AI-powered outfit recommendations.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          const Text(
            'App Features',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          const Text(
            '• Weather Page: Displays live sensor data from IoT devices with temperature, humidity, and light level readings. Includes historical data visualization with charts and regional weather data from OpenWeatherMap API as secondary information',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            '• Outfit Page: AI-powered clothing recommendations that prioritize live sensor data over weather API data for more accurate, location-specific outfit suggestions',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            '• IoT Integration: Real-time data from Firebase Realtime Database showing temperature, humidity, and ambient light levels from local sensors',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            '• Data Visualization: Interactive charts showing temperature and humidity trends over time using live sensor readings',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            '• About Page: Information about the IoT weather monitoring system and its features',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          const Text(
            'Technologies Used',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          const Text(
            '• Flutter: Cross-platform mobile app development',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            '• Firebase Realtime Database: Real-time IoT sensor data storage and retrieval',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            '• FL Chart: Interactive data visualization for sensor readings',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            '• OpenWeatherMap API: Regional weather data as secondary information source',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            '• OpenRouter AI API: LLaMA 3.2 model for intelligent outfit recommendations',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20), // Add some bottom padding
        ],
      ),
    );
  }
}
