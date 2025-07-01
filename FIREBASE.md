# Firebase Integration

This Flutter weather app fetches local sensor data from Firebase Realtime Database.

## Setup

1. Add your Firebase URL and secret to `.env`:

```
FIREBASE_URL=https://your-project-default-rtdb.region.firebasedatabase.app/
FIREBASE_SECRET=your-firebase-database-secret
```

2. Your Firebase database should have this structure:

```json
{
  "latest_reading": {
    "humidity": 52,
    "light_level": "Very Bright",
    "temperature": 25,
    "timestamp": 1609459250
  }
}
```

## Files

- `lib/models/sensor_data.dart` - Data model for sensor readings
- `lib/services/firebase_service.dart` - Service to fetch data from Firebase
- `lib/pages/weather_page.dart` - Displays both weather API and sensor data

The app shows local sensor data alongside weather API data for comparison.
