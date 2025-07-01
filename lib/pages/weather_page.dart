import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fl_chart/fl_chart.dart';
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
  List<SensorData> _weatherHistory = [];

  @override
  void initState() {
    super.initState();
    if (widget.weatherData == null) {
      _getCurrentLocation();
    }
    _fetchSensorData();
    _fetchWeatherHistory();
  }

  WeatherData? get _weatherData => widget.weatherData;
  ForecastData? get _forecastData => widget.forecastData;

  Future<void> _refreshWeather() async {
    _getCurrentLocation();
    _fetchSensorData();
    _fetchWeatherHistory();
  }

  Future<void> _fetchSensorData() async {
    final sensorData = await FirebaseService.getLatestSensorData();
    if (mounted) {
      setState(() {
        _sensorData = sensorData;
      });
    }
  }

  Future<void> _fetchWeatherHistory() async {
    final history = await FirebaseService.getWeatherHistory();

    // Debug: Let's also check what raw data we're getting
    final debugData = await FirebaseService.debugFirebaseData();
    print('DEBUG: Raw Firebase data: $debugData');
    print('DEBUG: Parsed history count: ${history.length}');

    if (mounted) {
      setState(() {
        _weatherHistory = history;
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
              // Debug Information Section (shown when data is missing)
              if (_sensorData == null || _weatherHistory.isEmpty)
                Card(
                  elevation: 4,
                  color: Colors.orange.shade50,
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
                              Icons.info_outline,
                              color: Colors.orange.shade700,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Debug Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_sensorData == null)
                          Text(
                            '• Latest sensor data: Not available',
                            style: TextStyle(color: Colors.orange.shade700),
                          ),
                        if (_sensorData != null)
                          Text(
                            '• Latest sensor data: Available (${_sensorData!.formattedTime})',
                            style: TextStyle(color: Colors.green.shade700),
                          ),
                        Text(
                          '• Historical data: ${_weatherHistory.length} readings found',
                          style: TextStyle(
                            color: _weatherHistory.isEmpty
                                ? Colors.orange.shade700
                                : Colors.green.shade700,
                          ),
                        ),
                        if (_weatherHistory.isEmpty)
                          const Text(
                            '• Check Firebase console: weather_readings path',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Hero Sensor Data Card - The main focus
              if (_sensorData != null)
                Card(
                  elevation: 12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primaryContainer,
                          Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.sensors,
                                size: 32,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Live Sensor Data',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Main temperature display
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.thermostat,
                                size: 80,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: 20),
                              Column(
                                children: [
                                  Text(
                                    '${_sensorData!.temperature.round()}°',
                                    style: TextStyle(
                                      fontSize: 88,
                                      fontWeight: FontWeight.w100,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                      height: 1,
                                    ),
                                  ),
                                  Text(
                                    'Celsius',
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                          .withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Additional sensor readings
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surface.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildLargeSensorDetail(
                                  'Humidity',
                                  '${_sensorData!.humidity}%',
                                  Icons.water_drop,
                                  Colors.blue,
                                ),
                                _buildLargeSensorDetail(
                                  'Light Level',
                                  _sensorData!.lightLevel,
                                  Icons.wb_sunny,
                                  Colors.orange,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),
                          Text(
                            'Last updated: ${_sensorData!.formattedTime}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Temperature History Chart
              if (_weatherHistory.isNotEmpty)
                Card(
                  elevation: 6,
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
                              Icons.show_chart,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Temperature History',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 200,
                          child: LineChart(_buildTemperatureChart()),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Humidity History Chart
              if (_weatherHistory.isNotEmpty)
                Card(
                  elevation: 6,
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
                              Icons.water_drop,
                              color: Colors.blue,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Humidity History',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 200,
                          child: LineChart(_buildHumidityChart()),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 32),

              // API Weather Data - Secondary Information
              if (!widget.isLoading && _weatherData != null)
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
                        Row(
                          children: [
                            Icon(
                              Icons.cloud,
                              color: Theme.of(context).colorScheme.secondary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Regional Weather (${_weatherData!.cityName})',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Image.network(
                              'https://openweathermap.org/img/wn/${_weatherData!.icon}@2x.png',
                              width: 64,
                              height: 64,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_weatherData!.temperatureCelsius.round()}°C',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _weatherData!.description,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildCompactWeatherDetail(
                              'Feels like',
                              '${_weatherData!.feelsLikeCelsius.round()}°C',
                              Icons.thermostat,
                            ),
                            _buildCompactWeatherDetail(
                              'Humidity',
                              '${_weatherData!.humidity}%',
                              Icons.water_drop,
                            ),
                            _buildCompactWeatherDetail(
                              'Wind',
                              '${_weatherData!.windSpeed.toStringAsFixed(1)} m/s',
                              Icons.air,
                            ),
                          ],
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

  Widget _buildLargeSensorDetail(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 40, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactWeatherDetail(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  LineChartData _buildTemperatureChart() {
    if (_weatherHistory.isEmpty) return LineChartData();

    final spots = _weatherHistory.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.temperature);
    }).toList();

    return LineChartData(
      gridData: const FlGridData(show: true),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) => Text('${value.toInt()}°'),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < _weatherHistory.length) {
                return Text(_weatherHistory[index].formattedTime);
              }
              return const Text('');
            },
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: true),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.red,
          barWidth: 3,
          dotData: const FlDotData(show: true),
        ),
      ],
    );
  }

  LineChartData _buildHumidityChart() {
    if (_weatherHistory.isEmpty) return LineChartData();

    final spots = _weatherHistory.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.humidity.toDouble());
    }).toList();

    return LineChartData(
      gridData: const FlGridData(show: true),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) => Text('${value.toInt()}%'),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < _weatherHistory.length) {
                return Text(_weatherHistory[index].formattedTime);
              }
              return const Text('');
            },
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: true),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.blue,
          barWidth: 3,
          dotData: const FlDotData(show: true),
        ),
      ],
    );
  }
}
