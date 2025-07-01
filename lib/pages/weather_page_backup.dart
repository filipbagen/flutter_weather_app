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
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please enable location services to get weather data',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission is required to get weather data',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Location permission permanently denied. Please enable it in settings.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () => Geolocator.openAppSettings(),
            ),
          ),
        );
      }
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _latitude = position.latitude;
      _longitude = position.longitude;

      _fetchWeatherData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _fetchWeatherData() async {
    if (_latitude == null || _longitude == null) return;

    if (widget.onLoadingChanged != null) {
      widget.onLoadingChanged!(true);
    }

    try {
      final weatherData = await WeatherService.getCurrentWeather(
        _latitude!,
        _longitude!,
      );
      final forecastData = await WeatherService.getForecast(
        _latitude!,
        _longitude!,
      );

      // Notify parent widget about weather data update
      if (widget.onWeatherUpdate != null) {
        widget.onWeatherUpdate!(weatherData, forecastData);
      }

      if (widget.onLoadingChanged != null) {
        widget.onLoadingChanged!(false);
      }
    } catch (e) {
      if (widget.onLoadingChanged != null) {
        widget.onLoadingChanged!(false);
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching weather: $e')));
      }
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

  Widget _buildWeatherDetail(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: Theme.of(
            context,
          ).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(
              context,
            ).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildSensorDetail(
    String label,
    String value,
    IconData icon,
    String? comparison,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: Theme.of(
            context,
          ).colorScheme.onSecondaryContainer.withValues(alpha: 0.8),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(
              context,
            ).colorScheme.onSecondaryContainer.withValues(alpha: 0.7),
          ),
        ),
        if (comparison != null) ...[
          const SizedBox(height: 2),
          Text(
            comparison,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(
                context,
              ).colorScheme.onSecondaryContainer.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  String? _getSensorTempComparison() {
    if (_sensorData == null || _weatherData == null) return null;

    final diff = _sensorData!.temperature - _weatherData!.temperatureCelsius;
    if (diff.abs() < 1) {
      return 'Similar to API';
    } else if (diff > 0) {
      return '${diff.round()}°C warmer';
    } else {
      return '${diff.abs().round()}°C cooler';
    }
  }

  String? _getHumidityComparison() {
    if (_sensorData == null || _weatherData == null) return null;

    final diff = _sensorData!.humidity - _weatherData!.humidity;
    if (diff.abs() < 5) {
      return 'Similar to API';
    } else if (diff > 0) {
      return '${diff}% higher';
    } else {
      return '${diff.abs()}% lower';
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
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Fetching weather data...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // No data state
              if (!widget.isLoading && _weatherData == null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Getting your location...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please allow location access to get weather data',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Current Weather - Hero Card
              if (!widget.isLoading && _weatherData != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Card(
                    elevation: 8,
                    shadowColor: Colors.black.withValues(alpha: 0.1),
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
                            Theme.of(context).colorScheme.primaryContainer
                                .withValues(alpha: 0.7),
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
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.wb_sunny,
                                      size: 120,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    );
                                  },
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
                                        fontWeight: FontWeight.w400,
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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surface.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
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
                            ),
                            const SizedBox(height: 24),

                            // Additional Weather Details
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surface.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildWeatherDetail(
                                    'Feels like',
                                    '${_weatherData!.feelsLikeCelsius.round()}°',
                                    Icons.thermostat,
                                  ),
                                  _buildWeatherDetail(
                                    'Humidity',
                                    '${_weatherData!.humidity}%',
                                    Icons.water_drop,
                                  ),
                                  _buildWeatherDetail(
                                    'Wind',
                                    '${_weatherData!.windSpeed.toStringAsFixed(1)} m/s',
                                    Icons.air,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Sensor Data Card
              if (_sensorData != null || _sensorDataLoading)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Card(
                    elevation: 4,
                    shadowColor: Colors.black.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.secondaryContainer,
                            Theme.of(context).colorScheme.secondaryContainer
                                .withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.sensors,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSecondaryContainer,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Local Sensor Data',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSecondaryContainer,
                                  ),
                                ),
                                const Spacer(),
                                if (_sensorData != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _sensorData!.isDataFresh
                                          ? Colors.green.withValues(alpha: 0.2)
                                          : Colors.orange.withValues(
                                              alpha: 0.2,
                                            ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _sensorData!.isDataFresh
                                          ? 'Fresh'
                                          : 'Outdated',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: _sensorData!.isDataFresh
                                            ? Colors.green.shade700
                                            : Colors.orange.shade700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            if (_sensorDataLoading)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (_sensorData != null) ...[
                              // Sensor readings
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildSensorDetail(
                                      'Temperature',
                                      '${_sensorData!.temperature.round()}°C',
                                      Icons.thermostat,
                                      _getSensorTempComparison(),
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildSensorDetail(
                                      'Humidity',
                                      '${_sensorData!.humidity}%',
                                      Icons.water_drop,
                                      _getHumidityComparison(),
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildSensorDetail(
                                      'Light Level',
                                      _sensorData!.lightLevel,
                                      Icons.wb_sunny,
                                      null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Additional info
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surface.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Last Updated: ${_sensorData!.formattedDateTime}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSecondaryContainer
                                            .withValues(alpha: 0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Light Description: ${_sensorData!.lightDescription}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSecondaryContainer
                                            .withValues(alpha: 0.7),
                                      ),
                                    ),
                                    if (_getSensorTempComparison() != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        _getSensorTempComparison()!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSecondaryContainer,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ] else
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Text(
                                    'Sensor data unavailable',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSecondaryContainer
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Hourly Forecast
              if (_forecastData != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Card(
                    elevation: 4,
                    shadowColor: Colors.black.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Hourly Forecast',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                            ],
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
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    color: isNow
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.primaryContainer
                                        : Theme.of(context)
                                              .colorScheme
                                              .primaryContainer
                                              .withValues(alpha: 0.3),
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
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isNow
                                                  ? Theme.of(context)
                                                        .colorScheme
                                                        .onPrimaryContainer
                                                  : Theme.of(
                                                      context,
                                                    ).colorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Image.network(
                                            'https://openweathermap.org/img/wn/${forecast.icon}@2x.png',
                                            width: 32,
                                            height: 32,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Icon(
                                                    Icons.wb_sunny,
                                                    size: 32,
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                  );
                                                },
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${forecast.temperatureCelsius.round()}°',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isNow
                                                  ? Theme.of(context)
                                                        .colorScheme
                                                        .onPrimaryContainer
                                                  : Theme.of(
                                                      context,
                                                    ).colorScheme.onSurface,
                                            ),
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
                ),

              // Daily Forecast
              if (_forecastData != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Card(
                    elevation: 4,
                    shadowColor: Colors.black.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '5-Day Forecast',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                            ],
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
                                      child: Text(
                                        _formatDate(forecast.date),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        children: [
                                          Image.network(
                                            'https://openweathermap.org/img/wn/${forecast.icon}@2x.png',
                                            width: 32,
                                            height: 32,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Icon(
                                                    Icons.wb_sunny,
                                                    size: 32,
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                  );
                                                },
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              forecast.description,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.7),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${forecast.minTemp.round()}° / ${forecast.maxTemp.round()}°',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
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
                ),

              // Pull to refresh hint
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.refresh,
                      size: 16,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Pull down to refresh',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
