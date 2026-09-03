import 'dart:async';
import 'dart:io' show Platform;

import 'package:baseflow_plugin_template/baseflow_plugin_template.dart';
import 'package:flutter/material.dart';
import 'package:ym_geolocator/ym_geolocator.dart';

/// Defines the main theme color.
final MaterialColor themeMaterialColor =
    BaseflowPluginExample.createMaterialColor(
      const Color.fromRGBO(48, 49, 60, 1),
    );

void main() {
  runApp(const GeolocatorWidget());
}

/// Example [Widget] showing the functionalities of the geolocator plugin
class GeolocatorWidget extends StatefulWidget {
  /// Creates a new GeolocatorWidget.
  const GeolocatorWidget({super.key});

  /// Utility method to create a page with the Baseflow templating.
  static ExamplePage createPage() {
    return ExamplePage(
      Icons.location_on,
      (context) => const GeolocatorWidget(),
    );
  }

  @override
  State<GeolocatorWidget> createState() => _GeolocatorWidgetState();
}

class _GeolocatorWidgetState extends State<GeolocatorWidget> {
  static const String _kLocationServicesDisabledMessage =
      'Location services are disabled.';
  static const String _kPermissionDeniedMessage = 'Permission denied.';
  static const String _kPermissionDeniedForeverMessage =
      'Permission denied forever.';
  static const String _kPermissionGrantedMessage = 'Permission granted.';

  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;
  final List<_PositionItem> _positionItems = <_PositionItem>[];
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<ServiceStatus>? _serviceStatusStreamSubscription;
  bool _positionStreamStarted = false;

  @override
  void initState() {
    super.initState();
    _toggleServiceStatusStream();
  }

  PopupMenuButton<int> _createActions() {
    return PopupMenuButton<int>(
      elevation: 40,
      onSelected: (value) async {
        switch (value) {
          case 1:
            _getLocationAccuracy();
            break;
          case 2:
            _requestTemporaryFullAccuracy();
            break;
          case 3:
            _openAppSettings();
            break;
          case 4:
            _openLocationSettings();
            break;
          case 5:
            setState(_positionItems.clear);
            break;
          default:
            break;
        }
      },
      itemBuilder: (context) => [
        if (Platform.isIOS)
          const PopupMenuItem(value: 1, child: Text("Get Location Accuracy")),
        if (Platform.isIOS)
          const PopupMenuItem(
            value: 2,
            child: Text("Request Temporary Full Accuracy"),
          ),
        const PopupMenuItem(value: 3, child: Text("Open App Settings")),
        if (Platform.isAndroid || Platform.isWindows)
          const PopupMenuItem(value: 4, child: Text("Open Location Settings")),
        const PopupMenuItem(value: 5, child: Text("Clear")),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const sizedBox = SizedBox(height: 10);

    return BaseflowPluginExample(
      pluginName: 'ym_geolocator',
      githubURL: 'https://github.com/yashmanghnani/ym_geolocator',
      pubDevURL: 'https://pub.dev/packages/ym_geolocator',
      appBarActions: [_createActions()],
      pages: [
        ExamplePage(
          Icons.location_on,
          (context) => Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: ListView.builder(
              itemCount: _positionItems.length,
              itemBuilder: (context, index) {
                final positionItem = _positionItems[index];

                if (positionItem.type == _PositionItemType.log) {
                  return ListTile(
                    title: Text(
                      positionItem.displayValue,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                } else {
                  return Card(
                    child: ListTile(
                      tileColor: themeMaterialColor,
                      title: Text(
                        positionItem.displayValue,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                }
              },
            ),
            floatingActionButton: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  onPressed: () {
                    _positionStreamStarted = !_positionStreamStarted;
                    _toggleListening();
                  },
                  tooltip: (_positionStreamSubscription == null)
                      ? 'Start position updates'
                      : _positionStreamSubscription!.isPaused
                      ? 'Resume'
                      : 'Pause',
                  backgroundColor: _determineButtonColor(),
                  child:
                      (_positionStreamSubscription == null ||
                          _positionStreamSubscription!.isPaused)
                      ? const Icon(Icons.play_arrow)
                      : const Icon(Icons.pause),
                ),
                sizedBox,
                FloatingActionButton(
                  onPressed: _getCurrentPosition,
                  child: const Icon(Icons.my_location),
                ),
                sizedBox,
                FloatingActionButton(
                  onPressed: _getLastKnownPosition,
                  child: const Icon(Icons.bookmark),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _getCurrentPosition() async {
    final hasPermission = await _handlePermission();

    if (!hasPermission) {
      return;
    }

    final position = await _geolocatorPlatform.getCurrentPosition();
    _updatePositionList(_PositionItemType.position, position.toString());
  }

  Future<bool> _handlePermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await _geolocatorPlatform.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      _updatePositionList(
        _PositionItemType.log,
        _kLocationServicesDisabledMessage,
      );

      return false;
    }

    permission = await _geolocatorPlatform.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocatorPlatform.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        _updatePositionList(_PositionItemType.log, _kPermissionDeniedMessage);

        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      _updatePositionList(
        _PositionItemType.log,
        _kPermissionDeniedForeverMessage,
      );

      return false;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    _updatePositionList(_PositionItemType.log, _kPermissionGrantedMessage);
    return true;
  }

  void _updatePositionList(_PositionItemType type, String displayValue) {
    if (!mounted) {
      return;
    }

    setState(() {
      _positionItems.add(_PositionItem(type, displayValue));
    });
  }

  bool get _isListening =>
      _positionStreamSubscription != null &&
      !_positionStreamSubscription!.isPaused;

  Color _determineButtonColor() => _isListening ? Colors.green : Colors.red;

  void _toggleServiceStatusStream() {
    if (_serviceStatusStreamSubscription != null) {
      return;
    }

    _serviceStatusStreamSubscription = _geolocatorPlatform
        .getServiceStatusStream()
        .listen(_handleServiceStatus, onError: _handleServiceStatusError);
  }

  void _handleServiceStatus(ServiceStatus serviceStatus) {
    if (serviceStatus == ServiceStatus.enabled) {
      if (_positionStreamStarted && !_isListening) {
        _toggleListening();
      }
      _updatePositionList(
        _PositionItemType.log,
        'Location service has been enabled',
      );
      return;
    }

    if (_positionStreamSubscription != null) {
      _positionStreamSubscription?.cancel();
      _positionStreamSubscription = null;
      _updatePositionList(
        _PositionItemType.log,
        'Position Stream has been canceled',
      );
    }

    _updatePositionList(
      _PositionItemType.log,
      'Location service has been disabled',
    );
  }

  void _handleServiceStatusError(Object error, StackTrace stackTrace) {
    _serviceStatusStreamSubscription?.cancel();
    _serviceStatusStreamSubscription = null;
  }

  void _toggleListening() {
    if (_positionStreamSubscription == null) {
      final positionStream = _geolocatorPlatform.getPositionStream();
      _positionStreamSubscription = positionStream.listen(
        (position) => _updatePositionList(
          _PositionItemType.position,
          position.toString(),
        ),
        onError: _handlePositionStreamError,
      )..pause();
    }

    final subscription = _positionStreamSubscription;
    if (subscription == null) {
      return;
    }

    final statusDisplayValue = subscription.isPaused ? 'resumed' : 'paused';
    if (subscription.isPaused) {
      subscription.resume();
    } else {
      subscription.pause();
    }

    _updatePositionList(
      _PositionItemType.log,
      'Listening for position updates $statusDisplayValue',
    );
  }

  void _handlePositionStreamError(Object error, StackTrace stackTrace) {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _serviceStatusStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _getLastKnownPosition() async {
    final position = await _geolocatorPlatform.getLastKnownPosition();
    if (position != null) {
      _updatePositionList(_PositionItemType.position, position.toString());
    } else {
      _updatePositionList(
        _PositionItemType.log,
        'No last known position available',
      );
    }
  }

  Future<void> _getLocationAccuracy() async {
    final status = await _geolocatorPlatform.getLocationAccuracy();
    _handleLocationAccuracyStatus(status);
  }

  Future<void> _requestTemporaryFullAccuracy() async {
    final status = await _geolocatorPlatform.requestTemporaryFullAccuracy(
      purposeKey: 'TemporaryPreciseAccuracy',
    );
    _handleLocationAccuracyStatus(status);
  }

  void _handleLocationAccuracyStatus(LocationAccuracyStatus status) {
    String locationAccuracyStatusValue;
    if (status == LocationAccuracyStatus.precise) {
      locationAccuracyStatusValue = 'Precise';
    } else if (status == LocationAccuracyStatus.reduced) {
      locationAccuracyStatusValue = 'Reduced';
    } else {
      locationAccuracyStatusValue = 'Unknown';
    }
    _updatePositionList(
      _PositionItemType.log,
      '$locationAccuracyStatusValue location accuracy granted.',
    );
  }

  Future<void> _openAppSettings() async {
    final opened = await _geolocatorPlatform.openAppSettings();
    String displayValue;

    if (opened) {
      displayValue = 'Opened Application Settings.';
    } else {
      displayValue = 'Error opening Application Settings.';
    }

    _updatePositionList(_PositionItemType.log, displayValue);
  }

  Future<void> _openLocationSettings() async {
    final opened = await _geolocatorPlatform.openLocationSettings();
    String displayValue;

    if (opened) {
      displayValue = 'Opened Location Settings';
    } else {
      displayValue = 'Error opening Location Settings';
    }

    _updatePositionList(_PositionItemType.log, displayValue);
  }
}

enum _PositionItemType { log, position }

class _PositionItem {
  _PositionItem(this.type, this.displayValue);

  final _PositionItemType type;
  final String displayValue;
}
