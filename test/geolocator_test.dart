import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ym_geolocator/ym_geolocator.dart';

final Position mockPosition = Position(
  latitude: 52.561270,
  longitude: 5.639382,
  timestamp: DateTime.fromMillisecondsSinceEpoch(500, isUtc: true),
  altitude: 3000.0,
  altitudeAccuracy: 0.0,
  accuracy: 0.0,
  heading: 0.0,
  headingAccuracy: 0.0,
  speed: 0.0,
  speedAccuracy: 0.0,
);

void main() {
  late FakeGeolocatorPlatform platform;

  setUp(() {
    platform = FakeGeolocatorPlatform();
    GeolocatorPlatform.instance = platform;
    debugDefaultTargetPlatformOverride = null;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  group('Geolocator', () {
    test('checkPermission delegates to the platform', () async {
      expect(await Geolocator.checkPermission(), LocationPermission.whileInUse);
    });

    test('requestPermission delegates to the platform', () async {
      expect(
        await Geolocator.requestPermission(),
        LocationPermission.whileInUse,
      );
    });

    test('isLocationServiceEnabled delegates to the platform', () async {
      expect(await Geolocator.isLocationServiceEnabled(), isTrue);
    });

    test('getLastKnownPosition forwards the legacy Android flag', () async {
      final position = await Geolocator.getLastKnownPosition(
        forceAndroidLocationManager: true,
      );

      expect(position, mockPosition);
      expect(platform.lastForceLocationManager, isTrue);
    });

    test('getCurrentPosition creates platform defaults', () async {
      expect(await Geolocator.getCurrentPosition(), mockPosition);

      expect(platform.lastCurrentPositionSettings, isA<LocationSettings>());
      expect(
        platform.lastCurrentPositionSettings!.accuracy,
        LocationAccuracy.best,
      );
    });

    test('getCurrentPosition creates Android settings on Android', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final timeLimit = const Duration(seconds: 10);

      await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        forceAndroidLocationManager: true,
        timeLimit: timeLimit,
      );

      final settings = platform.lastCurrentPositionSettings;
      expect(settings, isA<AndroidSettings>());
      final androidSettings = settings! as AndroidSettings;
      expect(androidSettings.accuracy, LocationAccuracy.high);
      expect(androidSettings.forceLocationManager, isTrue);
      expect(androidSettings.timeLimit, timeLimit);
    });

    test('getCurrentPosition preserves explicit settings', () async {
      final settings = LocationSettings(
        accuracy: LocationAccuracy.low,
        distanceFilter: 25,
      );

      await Geolocator.getCurrentPosition(locationSettings: settings);

      expect(platform.lastCurrentPositionSettings, same(settings));
    });

    test('getLocationAccuracy delegates to the platform', () async {
      expect(
        await Geolocator.getLocationAccuracy(),
        LocationAccuracyStatus.reduced,
      );
    });

    test('requestTemporaryFullAccuracy forwards the purpose key', () async {
      await Geolocator.requestTemporaryFullAccuracy(
        purposeKey: 'purposeKeyValue',
      );

      expect(platform.lastPurposeKey, 'purposeKeyValue');
    });

    test('getServiceStatusStream delegates to the platform', () async {
      expect(
        await Geolocator.getServiceStatusStream().single,
        ServiceStatus.enabled,
      );
    });

    test('getPositionStream forwards location settings', () async {
      final settings = LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10,
      );

      expect(
        await Geolocator.getPositionStream(locationSettings: settings).single,
        mockPosition,
      );
      expect(platform.lastStreamSettings, same(settings));
    });

    test('openAppSettings delegates to the platform', () async {
      expect(await Geolocator.openAppSettings(), isTrue);
    });

    test('openLocationSettings delegates to the platform', () async {
      expect(await Geolocator.openLocationSettings(), isTrue);
    });

    test('distanceBetween returns meters', () {
      expect(Geolocator.distanceBetween(0, 0, 0, 1), closeTo(111319.49, 0.01));
    });

    test('bearingBetween returns the initial bearing', () {
      expect(Geolocator.bearingBetween(0, 0, 0, 1), closeTo(90, 0.001));
    });
  });
}

class FakeGeolocatorPlatform extends GeolocatorPlatform {
  LocationSettings? lastCurrentPositionSettings;
  LocationSettings? lastStreamSettings;
  bool lastForceLocationManager = false;
  String? lastPurposeKey;

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<LocationPermission> requestPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async {
    lastForceLocationManager = forceLocationManager;
    return mockPosition;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    lastCurrentPositionSettings = locationSettings;
    return mockPosition;
  }

  @override
  Stream<ServiceStatus> getServiceStatusStream() =>
      Stream.value(ServiceStatus.enabled);

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    lastStreamSettings = locationSettings;
    return Stream.value(mockPosition);
  }

  @override
  Future<LocationAccuracyStatus> getLocationAccuracy() async =>
      LocationAccuracyStatus.reduced;

  @override
  Future<LocationAccuracyStatus> requestTemporaryFullAccuracy({
    required String purposeKey,
  }) async {
    lastPurposeKey = purposeKey;
    return LocationAccuracyStatus.reduced;
  }

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openLocationSettings() async => true;
}
