# Firebase Realtime Database Integration

This document explains how Firebase Realtime Database has been integrated into the Flutter Weather App to display local sensor data alongside API weather data.

## Features Added

### 1. **SensorData Model** (`/lib/models/sensor_data.dart`)

- Represents the sensor data structure from Firebase
- Fields: `humidity`, `lightLevel`, `lightRaw`, `temperature`, `timestamp`
- Utility methods for formatting and data comparison
- Data freshness checking (considers data fresh if less than 30 minutes old)

### 2. **FirebaseService** (`/lib/services/firebase_service.dart`)

- Handles all Firebase Realtime Database interactions
- Uses REST API with authentication via Firebase secret
- Methods:
  - `getLatestSensorData()`: Fetches the current sensor reading
  - `getHistoricalSensorData()`: Fetches historical readings (for future use)
  - `testConnection()`: Tests Firebase connectivity
  - `listenToSensorData()`: Stream for real-time updates

### 3. **Enhanced Weather Page**

- Added sensor data card between current weather and forecast
- Shows local temperature, humidity, and light level
- Compares sensor data with API weather data
- Visual indicators for data freshness
- Automatic refresh with weather data

## Database Structure

The Firebase Realtime Database expects this structure:

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
