import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/weather_service.dart';
import '../services/firebase_service.dart';
import '../models/weather_data.dart';
import '../models/forecast_data.dart';
import '../models/sensor_data.dart';

class WeatherPage extends StatefulWidget {
  final Function(WeatherData?, ForecastData?)? onWeatherUpdate;
  final WeatherData? weatherData;
  final ForecastData? forecastData;
  final bool isLoading;
  final Function(bool)? onLoadingChanged;

  const WeatherPage({
    super.key,
    this.onWeatherUpdate,
    this.weatherData,
    this.forecastData,
    this.isLoading = false,
    this.onLoadingChanged,
  });

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  double? _latitude;
  double? _longitude;
  SensorData? _sensorData;

  @override
  void initState() {
    super.initState();
    if (widget.weatherData == null) {
      _getCurrentLocation();
    }
    _fetchSensorData();
  }

  WeatherData? get _weatherData => widget.weatherData;
  ForecastData? get _forecastData => widget.forecastData;

  Future<void> _refreshWeather() async {
    _getCurrentLocation();
    _fetchSensorData();
  }

  Future<void> _fetchSensorData() async {
    final sensorData = await FirebaseService.getLatestSensorData();
    if (mounted) {
      setState(() {
        _sensorData = sensorData;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition();
    _latitude = position.latitude;
    _longitude = position.longitude;
    _fetchWeatherData();
  }

  Future<void> _fetchWeatherData() async {
    if (_latitude == null || _longitude == null) return;

    if (widget.onLoadingChanged != null) {
      widget.onLoadingChanged!(true);
    }

    final weatherData = await WeatherService.getCurrentWeather(
      _latitude!,
      _longitude!,
    );
    final forecastData = await WeatherService.getForecast(
      _latitude!,
      _longitude!,
    );

    if (widget.onWeatherUpdate != null) {
      widget.onWeatherUpdate!(weatherData, forecastData);
    }

    if (widget.onLoadingChanged != null) {
      widget.onLoadingChanged!(false);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final itemDate = DateTime(date.year, date.month, date.day);

    if (itemDate == today) {
      return 'Today';
    } else if (itemDate == tomorrow) {
      return 'Tomorrow';
    } else {
      final weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      return weekdays[date.weekday % 7];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.1),
            Theme.of(context).colorScheme.surface,
          ],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _refreshWeather,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Loading state
              if (widget.isLoading)
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        const Text('Fetching weather data...'),
                      ],
                    ),
                  ),
                ),

              // No data state
              if (!widget.isLoading && _weatherData == null)
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        const Text('Getting your location...'),
                        const SizedBox(height: 8),
                        const Text(
                          'Please allow location access to get weather data',
                        ),
                      ],
                    ),
                  ),
                ),

              // Current Weather
              if (!widget.isLoading && _weatherData != null)
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primaryContainer,
                          Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Text(
                            _weatherData!.cityName,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network(
                                'https://openweathermap.org/img/wn/${_weatherData!.icon}@4x.png',
                                width: 120,
                                height: 120,
                              ),
                              const SizedBox(width: 16),
                              Column(
                                children: [
                                  Text(
                                    '${_weatherData!.temperatureCelsius.round()}°',
                                    style: TextStyle(
                                      fontSize: 72,
                                      fontWeight: FontWeight.w200,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                      height: 1,
                                    ),
                                  ),
                                  Text(
                                    'Celsius',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _weatherData!.description.toUpperCase(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                children: [
                                  const Icon(Icons.thermostat, size: 24),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_weatherData!.feelsLikeCelsius.round()}°',
                                  ),
                                  const Text(
                                    'Feels like',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  const Icon(Icons.water_drop, size: 24),
                                  const SizedBox(height: 4),
                                  Text('${_weatherData!.humidity}%'),
                                  const Text(
                                    'Humidity',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  const Icon(Icons.air, size: 24),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_weatherData!.windSpeed.toStringAsFixed(1)} m/s',
                                  ),
                                  const Text(
                                    'Wind',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Sensor Data Card
              if (_sensorData != null)
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Local Sensor Data',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                const Icon(Icons.thermostat, size: 24),
                                const SizedBox(height: 4),
                                Text(
                                  '${_sensorData!.temperature.round()}°C',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Text(
                                  'Temperature',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                const Icon(Icons.water_drop, size: 24),
                                const SizedBox(height: 4),
                                Text(
                                  '${_sensorData!.humidity}%',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Text(
                                  'Humidity',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                const Icon(Icons.wb_sunny, size: 24),
                                const SizedBox(height: 4),
                                Text(
                                  _sensorData!.lightLevel,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Text(
                                  'Light Level',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Hourly Forecast
              if (_forecastData != null)
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hourly Forecast',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 140,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _forecastData!.hourlyForecasts.length,
                            itemBuilder: (context, index) {
                              final forecast =
                                  _forecastData!.hourlyForecasts[index];
                              final isNow = index == 0;
                              return Container(
                                width: 85,
                                margin: const EdgeInsets.only(right: 12),
                                child: Card(
                                  elevation: isNow ? 6 : 2,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 8,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          isNow
                                              ? 'Now'
                                              : '${forecast.date.hour}:00',
                                        ),
                                        const SizedBox(height: 8),
                                        Image.network(
                                          'https://openweathermap.org/img/wn/${forecast.icon}@2x.png',
                                          width: 32,
                                          height: 32,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${forecast.temperatureCelsius.round()}°',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Daily Forecast
              if (_forecastData != null)
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '5-Day Forecast',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Column(
                          children: _forecastData!.dailyForecasts.map((
                            forecast,
                          ) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(_formatDate(forecast.date)),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Row(
                                      children: [
                                        Image.network(
                                          'https://openweathermap.org/img/wn/${forecast.icon}@2x.png',
                                          width: 32,
                                          height: 32,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            forecast.description,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${forecast.minTemp.round()}° / ${forecast.maxTemp.round()}°',
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
