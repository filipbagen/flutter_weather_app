import 'package:flutter/material.dart';
import '../models/weather_data.dart';
import '../models/forecast_data.dart';
import '../models/sensor_data.dart';
import '../services/firebase_service.dart';
import 'weather_page.dart';

class WeatherPageWrapper extends StatefulWidget {
  final Function(WeatherData?, ForecastData?)? onWeatherUpdate;
  final Function(SensorData?)? onSensorUpdate;
  final WeatherData? weatherData;
  final ForecastData? forecastData;
  final bool isLoading;
  final Function(bool)? onLoadingChanged;

  const WeatherPageWrapper({
    super.key,
    this.onWeatherUpdate,
    this.onSensorUpdate,
    this.weatherData,
    this.forecastData,
    this.isLoading = false,
    this.onLoadingChanged,
  });

  @override
  State<WeatherPageWrapper> createState() => _WeatherPageWrapperState();
}

class _WeatherPageWrapperState extends State<WeatherPageWrapper> {
  SensorData? _currentSensorData;

  @override
  void initState() {
    super.initState();
    _fetchSensorData();
  }

  Future<void> _fetchSensorData() async {
    final sensorData = await FirebaseService.getLatestSensorData();
    if (mounted && sensorData != null) {
      setState(() {
        _currentSensorData = sensorData;
      });
      
      // Notify parent about sensor data update
      if (widget.onSensorUpdate != null) {
        widget.onSensorUpdate!(sensorData);
      }
    }
  }

  void _handleWeatherUpdate(WeatherData? weatherData, ForecastData? forecastData) {
    // Refresh sensor data when weather updates
    _fetchSensorData();
    
    // Pass through the weather update
    if (widget.onWeatherUpdate != null) {
      widget.onWeatherUpdate!(weatherData, forecastData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WeatherPage(
      onWeatherUpdate: _handleWeatherUpdate,
      weatherData: widget.weatherData,
      forecastData: widget.forecastData,
      isLoading: widget.isLoading,
      onLoadingChanged: widget.onLoadingChanged,
    );
  }
}
