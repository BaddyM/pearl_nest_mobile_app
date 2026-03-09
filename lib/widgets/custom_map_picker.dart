import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class CustomMapPicker extends StatefulWidget {
  final Function(LatLng) onLocationSelected;

  const CustomMapPicker({super.key, required this.onLocationSelected});

  @override
  State<CustomMapPicker> createState() => _CustomMapPickerState();
}

class _CustomMapPickerState extends State<CustomMapPicker> {
  // Default to a central location (e.g., Kampala, Uganda based on your error logs)
  LatLng _currentCenter = const LatLng(0.3476, 32.5825);
  final MapController _mapController = MapController();

  // Add this helper function outside the build method
  final TileUpdateTransformer _debounceTileUpdate = TileUpdateTransformer.fromHandlers(
    handleData: (event, sink) {
      Future.delayed(const Duration(milliseconds: 100), () => sink.add(event));
    },
  );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentCenter,
            initialZoom: 15.0,
            onPositionChanged: (position, hasGesture) {
              if (hasGesture) {
                setState(() {
                  _currentCenter = position.center!;
                });
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.pearlnest.mobile',
              // Adds a bit of a buffer to prevent frame drops during network errors
              tileUpdateTransformer: _debounceTileUpdate,
            ),
          ],
        ),

        // Stationary Center Pin
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 40), // Offset to sit on the point
            child: Icon(Icons.location_on, color: Colors.redAccent, size: 45),
          ),
        ),

        // "Confirm" Button
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => widget.onLocationSelected(_currentCenter),
            child: const Text(
              "Confirm This Location",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
