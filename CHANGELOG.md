## 1.0.0

- Updated the package metadata and public documentation for the stable 1.0.0 release.
- Renamed the primary library entrypoint to `ym_geolocator.dart`; update imports to `package:ym_geolocator/ym_geolocator.dart`.
- Raised the minimum supported Dart SDK to 3.13.2 and Flutter SDK to 3.47.2.
- Updated geolocation platform implementations to their latest compatible releases.
- Corrected Android plugin registration to use `ym_geolocator_android`.
- Replaced Mockito-based facade tests with a deterministic platform fake and expanded delegation coverage.
- Updated the example app to use the package's `ym_geolocator` name.
- Modernized the example Android build with the Flutter 3.47.2 Gradle template, AGP 9.1.0, Gradle 9.3.1, Kotlin 2.4.0, and Java 17.

## 0.0.1

- Initial release.
