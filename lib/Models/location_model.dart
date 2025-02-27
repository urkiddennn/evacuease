class LocationModel {
  final String id;
  final String name;
  final String description;
  final List<String> contacts;
  final int capacity;
  final String hazardType;
  final double lat;
  final double lng;
  final String locationName; // New field for readable location name
  final List<String> images;

  LocationModel({
    required this.id,
    required this.name,
    required this.description,
    required this.contacts,
    required this.capacity,
    required this.hazardType,
    required this.lat,
    required this.lng,
    required this.locationName,
    required this.images,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unknown Name',
      description: json['description'] ?? 'No description available',
      contacts:
          (json['contacts'] as List?)?.map((e) => e.toString()).toList() ?? [],
      capacity: json['capacity'] ?? 0,
      hazardType: json['hazardType']?.toString() ?? 'Unknown',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      locationName:
          json['locationName']?.toString() ?? 'Unknown Location', // New field
      images:
          (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
