# IoT Weather App with Live Sensor Data Integration

This document explains how Firebase Realtime Database has been integrated into the Flutter Weather App to display local sensor data and provide AI-powered outfit recommendations based on live IoT sensor readings.

## 🌟 **Key Features**

### 1. **Live Sensor Data Priority**

- **Primary Data Source**: IoT sensor readings from Firebase Realtime Database
- **Secondary Data Source**: OpenWeatherMap API for regional context
- **Real-time Updates**: Live temperature, humidity, and light level readings

### 2. **AI Outfit Recommendations**

- **Sensor-Driven AI**: Outfit suggestions based on actual local conditions
- **Smart Fallback**: Uses weather API data when sensor data unavailable
- **Contextual Recommendations**: Considers temperature, humidity, and light levels

## Features Added

### 1. **SensorData Model** (`/lib/models/sensor_data.dart`)

- Represents live IoT sensor data structure from Firebase
- Fields: `humidity`, `lightLevel`, `lightRaw`, `temperature`, `timestamp`
- Utility methods for formatting and time display
- Real-time sensor reading processing

### 2. **FirebaseService** (`/lib/services/firebase_service.dart`)

- Handles all Firebase Realtime Database interactions for IoT data
- Uses REST API with authentication via Firebase secret
- Methods:
  - `getLatestSensorData()`: Fetches current live sensor reading
  - `getWeatherHistory()`: Fetches historical sensor readings for charts
  - `debugFirebaseData()`: Debug method for troubleshooting sensor data

### 3. **Enhanced AI Service** (`/lib/services/ai_service.dart`)

- **NEW**: `getOutfitRecommendationFromSensor()`: AI recommendations based on sensor data
- Prioritizes live sensor readings over weather API data
- Fallback mechanisms for robust outfit suggestions
- Sensor-specific prompt engineering for better AI responses

### 4. **Modernized Weather Page**

- **Primary Focus**: Large, prominent sensor data card showing live readings
- **Historical Visualization**: Temperature and humidity charts using FL Chart
- **Secondary Information**: Regional weather data from OpenWeatherMap API
- **Debug Information**: Shows status of sensor data fetching for troubleshooting

### 5. **Smart Outfit Page**

- **Data Source Indicator**: Shows whether using live sensor data or weather API
- **AI Integration**: Outfit recommendations prioritize sensor data
- **Contextual Suggestions**: Considers actual local temperature, humidity, and light levels

## Database Structure

The Firebase Realtime Database expects this structure:

**Latest Reading:**

```json
{
  "latest_reading": {
    "humidity": 52,
    "light_level": "Very Bright",
    "light_raw": 60046,
    "temperature": 25,
    "timestamp": 1609459250
  }
}
```

**Historical Readings:**

```json
{
  "weather_readings": {
    "-OTld83osHYFsqJn3oXc": {
      "humidity": 52,
      "light_level": "Very Bright",
      "light_raw": 60046,
      "temperature": 25,
      "timestamp": 1609459250
    },
    "-OTldFyrx2QErdxM77ND": {
      "humidity": 48,
      "light_level": "Bright",
      "light_raw": 45023,
      "temperature": 23,
      "timestamp": 1609459310
    }
  }
}
```

The `weather_readings` structure uses Firebase auto-generated keys (like `-OTld83osHYFsqJn3oXc`) for each reading, which is handled automatically by the `FirebaseService.getWeatherHistory()` method.

## Environment Configuration

Required `.env` variables:

```
FIREBASE_URL=https://your-project-default-rtdb.region.firebasedatabase.app/
FIREBASE_SECRET=your-firebase-database-secret
```

## Visual Features

### Sensor Data Card

- **Gradient Design**: Uses secondary container colors for visual distinction
- **Status Indicator**: Shows "Fresh" (green) or "Outdated" (orange) data status
- **Comparison Text**: Shows differences between sensor and API data
- **Icons**: Clear visual representation for each data type

### Data Comparisons

- **Temperature**: Shows difference with API temperature (e.g., "2°C warmer")
- **Humidity**: Shows difference with API humidity (e.g., "5% higher")
- **Smart Thresholds**: Only shows differences when significant (>1°C for temp, >5% for humidity)

## Implementation Details

### Error Handling

- Graceful degradation when Firebase is unavailable
- User-friendly error messages via SnackBar
- Continues to show API weather data even if sensor data fails

### Performance

- Non-blocking Firebase calls
- Loading indicators for sensor data
- Minimal UI impact when sensor data is unavailable

### Testing

- Unit tests for Firebase connectivity
- Service method testing
- Environment variable validation

## Usage Example

The sensor data automatically loads when the weather page initializes:

1. User opens the app
2. Location permission requested
3. API weather data fetched
4. Firebase sensor data fetched in parallel
5. Both datasets displayed with comparison

## Future Enhancements

1. **Real-time Updates**: Implement WebSocket connection for live data
2. **Historical Charts**: Use the historical data method for trend visualization
3. **Data Caching**: Store recent readings locally for offline access
4. **Multiple Sensors**: Support for multiple sensor locations
5. **Data Export**: Allow users to export sensor readings

## Dependencies

- `firebase_database: ^11.1.4`: Firebase Realtime Database SDK
- `http: ^1.1.0`: For REST API calls
- `flutter_dotenv: ^5.1.0`: Environment variable management
