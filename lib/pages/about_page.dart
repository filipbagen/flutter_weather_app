import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(22.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          Text(
            'About',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 10),
          Text(
            'This project was developed for the course 1DV535 at Linnaeus University using Flutter, OpenWeatherMap API, and OpenRouter API.',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 20),
          Text(
            'App Features',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 10),
          Text(
            '• Weather Page: Get current weather conditions and forecasts for your location',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            '• Outfit Page: Receive AI-powered clothing recommendations based on current weather conditions',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            '• About Page: Learn more about the app and its features',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
