# ym_geolocator

Cross-platform location services for Flutter. `ym_geolocator` provides a small,
typed facade over the platform implementations for Android, iOS, macOS, web,
Windows, and Linux.

## Requirements

- Flutter 3.47.2 or newer
- Dart 3.13.2 or newer
- Android API 23 or newer when targeting Android

## Installation

Add the package to `pubspec.yaml`:

```yaml
dependencies:
  ym_geolocator: ^1.0.0
```

Then fetch dependencies:

```shell
flutter pub get
```

## Platform configuration

### Android

Add the location permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

For background location updates, follow the Android background-location
requirements and add only the permissions your application genuinely needs.

### iOS and macOS

Add `NSLocationWhenInUseUsageDescription` to the application `Info.plist`.
For temporary precise location on iOS 14 or newer, also add an
`NSLocationTemporaryUsageDescriptionDictionary` entry whose key matches the
`purposeKey` passed to `requestTemporaryFullAccuracy`.

### Web

Location access is subject to browser support, secure-context requirements, and
the browser's permission model. Test the permission flow in every browser your
application supports.

## Usage

Check services and permissions before requesting a position:

```dart
import 'package:ym_geolocator/ym_geolocator.dart';

Future<Position?> determinePosition() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    return null;
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    return null;
  }

  return Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
    ),
  );
}
```

Listen for continuous updates and cancel the subscription when it is no longer
needed:

```dart
final subscription = Geolocator.getPositionStream(
  locationSettings: const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10,
  ),
).listen((position) {
  // Update application state.
});

await subscription.cancel();
```

Platform-specific settings are available through `AndroidSettings`,
`AppleSettings`, and `WebSettings`. The older
`desiredAccuracy`/`forceAndroidLocationManager`/`timeLimit` arguments remain
available for compatibility, but new code should pass `locationSettings`.

Useful helpers include:

- `Geolocator.getLastKnownPosition()` for a fast cached result
- `Geolocator.getServiceStatusStream()` for service state changes
- `Geolocator.openAppSettings()` and `Geolocator.openLocationSettings()` for
  recovery flows
- `Geolocator.distanceBetween()` and `Geolocator.bearingBetween()` for
  coordinate calculations

## Example application

Run the bundled example from the repository root:

```shell
cd example
flutter pub get
flutter run
```

## Development

Run the package checks before opening a pull request:

```shell
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter pub publish --dry-run
```

## License

This project is distributed under the MIT License. See [LICENSE](LICENSE).

## Links

- [Repository](https://github.com/yashmanghnani/ym_geolocator)
- [Issue tracker](https://github.com/yashmanghnani/ym_geolocator/issues)
