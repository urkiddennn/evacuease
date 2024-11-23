import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'nearby_places.dart';

class LocationDetailsScreen extends StatelessWidget {
  final LatLng location;

  const LocationDetailsScreen({Key? key, required this.location})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Location Details")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Latitude: ${location.latitude}",
                style: const TextStyle(fontSize: 16)),
            Text("Longitude: ${location.longitude}",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Back to Map"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        NearbyPlacesScreen(location: location),
                  ),
                );
              },
              child: const Text("Find Nearby Places"),
            ),
          ],
        ),
      ),
    );
  }
}
