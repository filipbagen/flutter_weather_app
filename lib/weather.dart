import 'package:flutter/material.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Weather Page',
        style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
      ),
    );
  }
}