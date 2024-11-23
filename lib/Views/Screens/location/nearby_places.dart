import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class NearbyPlacesScreen extends StatelessWidget {
  final LatLng location;

  const NearbyPlacesScreen({Key? key, required this.location})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nearby Places")),
      body: Center(
        child: Text(
          "Nearby places for:\nLatitude: ${location.latitude}\nLongitude: ${location.longitude}",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
